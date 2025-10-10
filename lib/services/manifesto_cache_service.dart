import 'package:sqflite/sqflite.dart';
import '../models/like_model.dart';
import '../utils/app_logger.dart';
import 'local_database_service.dart';

class ManifestoCacheService {
  static final ManifestoCacheService _instance = ManifestoCacheService._internal();
  factory ManifestoCacheService() => _instance;
  ManifestoCacheService._internal();

  final LocalDatabaseService _dbService = LocalDatabaseService();


  // Like operations
  Future<void> cacheLike(LikeModel like, {bool synced = false}) async {
    final db = await _dbService.database;
    await db.insert(
      LocalDatabaseService.likesTable,
      {
        'id': like.id,
        'userId': like.userId,
        'postId': like.postId,
        'createdAt': like.createdAt.toIso8601String(),
        'synced': synced ? 1 : 0,
        'syncAction': 'create',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.common('💾 [ManifestoCache] Cached like: ${like.id}');
  }

  Future<void> removeCachedLike(String likeId) async {
    final db = await _dbService.database;
    await db.update(
      LocalDatabaseService.likesTable,
      {'synced': 0, 'syncAction': 'delete'},
      where: 'id = ?',
      whereArgs: [likeId],
    );
    AppLogger.common('🗑️ [ManifestoCache] Marked like for deletion: $likeId');
  }

  Future<bool> hasUserLiked(String userId, String manifestoId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalDatabaseService.likesTable,
      where: 'userId = ? AND postId = ? AND (syncAction != ? OR syncAction IS NULL)',
      whereArgs: [userId, manifestoId, 'delete'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<int> getCachedLikeCount(String manifestoId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${LocalDatabaseService.likesTable} WHERE postId = ? AND (syncAction != ? OR syncAction IS NULL)',
      [manifestoId, 'delete'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLikes() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalDatabaseService.likesTable,
      where: 'synced = ?',
      whereArgs: [0],
    );

    return maps;
  }

  Future<void> markLikeSynced(String likeId) async {
    final db = await _dbService.database;
    await db.update(
      LocalDatabaseService.likesTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [likeId],
    );
    AppLogger.common('✅ [ManifestoCache] Marked like synced: $likeId');
  }

  // Poll operations
  Future<void> cachePollVote(String manifestoId, String userId, String option, {bool synced = false}) async {
    final db = await _dbService.database;
    await db.insert(
      LocalDatabaseService.pollsTable,
      {
        'manifestoId': manifestoId,
        'userId': userId,
        'option': option,
        'createdAt': DateTime.now().toIso8601String(),
        'synced': synced ? 1 : 0,
        'syncAction': 'create',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.common('💾 [ManifestoCache] Cached poll vote: $manifestoId - $userId');
  }

  Future<String?> getCachedUserVote(String manifestoId, String userId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalDatabaseService.pollsTable,
      columns: ['option'],
      where: 'manifestoId = ? AND userId = ? AND (syncAction != ? OR syncAction IS NULL)',
      whereArgs: [manifestoId, userId, 'delete'],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first['option'] as String : null;
  }

  Future<Map<String, int>> getCachedPollResults(String manifestoId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT option, COUNT(*) as count FROM ${LocalDatabaseService.pollsTable} WHERE manifestoId = ? AND (syncAction != ? OR syncAction IS NULL) GROUP BY option',
      [manifestoId, 'delete'],
    );

    final results = <String, int>{};
    for (final map in maps) {
      results[map['option'] as String] = map['count'] as int;
    }
    return results;
  }

  Future<bool> hasUserVoted(String manifestoId, String userId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      LocalDatabaseService.pollsTable,
      where: 'manifestoId = ? AND userId = ? AND (syncAction != ? OR syncAction IS NULL)',
      whereArgs: [manifestoId, userId, 'delete'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPollVotes() async {
    final db = await _dbService.database;
    return await db.query(
      LocalDatabaseService.pollsTable,
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markPollVoteSynced(String manifestoId, String userId) async {
    final db = await _dbService.database;
    await db.update(
      LocalDatabaseService.pollsTable,
      {'synced': 1},
      where: 'manifestoId = ? AND userId = ?',
      whereArgs: [manifestoId, userId],
    );
    AppLogger.common('✅ [ManifestoCache] Marked poll vote synced: $manifestoId - $userId');
  }

  // Sync operations
  Future<Map<String, dynamic>> getPendingSyncItems() async {
    final unsyncedLikes = await getUnsyncedLikes();
    final unsyncedPolls = await getUnsyncedPollVotes();

    return {
      'likes': unsyncedLikes,
      'polls': unsyncedPolls,
    };
  }

  Future<void> clearSyncedItems() async {
    final db = await _dbService.database;

    // Remove synced likes
    await db.delete(
      LocalDatabaseService.likesTable,
      where: 'synced = ?',
      whereArgs: [1],
    );

    // Remove synced polls
    await db.delete(
      LocalDatabaseService.pollsTable,
      where: 'synced = ?',
      whereArgs: [1],
    );

    AppLogger.common('🧹 [ManifestoCache] Cleared synced items from cache');
  }

  // Cache management
  Future<void> updateManifestoCache(String manifestoId, List<LikeModel> likes, Map<String, int> pollResults) async {
    final db = await _dbService.database;
    final batch = db.batch();

    // Clear existing data for this manifesto
    batch.delete(
      LocalDatabaseService.likesTable,
      where: 'postId = ?',
      whereArgs: [manifestoId],
    );
    batch.delete(
      LocalDatabaseService.pollsTable,
      where: 'manifestoId = ?',
      whereArgs: [manifestoId],
    );

    // Insert new likes
    for (final like in likes) {
      batch.insert(
        LocalDatabaseService.likesTable,
        {
          'id': like.id,
          'userId': like.userId,
          'postId': like.postId,
          'createdAt': like.createdAt.toIso8601String(),
          'synced': 1, // Server data is already synced
          'syncAction': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Note: Poll results are aggregated, so we don't store individual votes from server
    // Only local votes are stored

    await batch.commit();
    await _dbService.updateCacheMetadata('manifesto_$manifestoId');
    AppLogger.common('💾 [ManifestoCache] Updated cache for manifesto: $manifestoId');
  }

  Future<DateTime?> getLastManifestoUpdate(String manifestoId) async {
    return await _dbService.getLastUpdateTime('manifesto_$manifestoId');
  }
}
