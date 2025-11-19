import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import '../../../models/like_model.dart';
import '../../../utils/app_logger.dart';
import '../../../services/local_database_service.dart';
import '../../../services/web_storage_helper.dart';

class ManifestoCacheService {
  static final ManifestoCacheService _instance = ManifestoCacheService._internal();
  factory ManifestoCacheService() => _instance;
  ManifestoCacheService._internal();

  final LocalDatabaseService _dbService = LocalDatabaseService();


  // Like operations
  Future<void> cacheLike(LikeModel like, {bool synced = false}) async {
    if (kIsWeb) {
      // Web: Use SharedPreferences storage
      await WebStorageHelper.saveManifestoInteraction(like.id, {
        'id': like.id,
        'type': 'like',
        'userId': like.userId,
        'postId': like.postId,
        'createdAt': like.createdAt.toIso8601String(),
        'synced': synced ? 1 : 0,
        'syncAction': 'create',
      });
      AppLogger.common('🌐 [ManifestoCache] Web cached like: ${like.id}');
    } else {
      // Mobile: Use SQLite storage
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
      AppLogger.common('🐘 [ManifestoCache] Mobile cached like: ${like.id}');
    }
  }

  Future<void> removeCachedLike(String likeId) async {
    if (kIsWeb) {
      // Web: Update SharedPreferences storage
      await WebStorageHelper.saveManifestoInteraction(likeId, {
        'synced': 0,
        'syncAction': 'delete',
      });
      AppLogger.common('🌐 [ManifestoCache] Web marked like for deletion: $likeId');
    } else {
      // Mobile: Update SQLite storage
      final db = await _dbService.database;
      await db.update(
        LocalDatabaseService.likesTable,
        {'synced': 0, 'syncAction': 'delete'},
        where: 'id = ?',
        whereArgs: [likeId],
      );
      AppLogger.common('🐘 [ManifestoCache] Mobile marked like for deletion: $likeId');
    }
  }

  Future<bool> hasUserLiked(String userId, String manifestoId) async {
    if (kIsWeb) {
      // Web: Check SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      return interactions.values.any((interaction) =>
          interaction['type'] == 'like' &&
          interaction['userId'] == userId &&
          interaction['postId'] == manifestoId &&
          interaction['syncAction'] != 'delete');
    } else {
      // Mobile: Check SQLite storage
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.likesTable,
        where: 'userId = ? AND postId = ? AND (syncAction != ? OR syncAction IS NULL)',
        whereArgs: [userId, manifestoId, 'delete'],
        limit: 1,
      );
      return maps.isNotEmpty;
    }
  }

  Future<int> getCachedLikeCount(String manifestoId) async {
    if (kIsWeb) {
      // Web: Count from SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      return interactions.values.where((interaction) =>
          interaction['type'] == 'like' &&
          interaction['postId'] == manifestoId &&
          interaction['syncAction'] != 'delete').length;
    } else {
      // Mobile: Count from SQLite storage
      final db = await _dbService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${LocalDatabaseService.likesTable} WHERE postId = ? AND (syncAction != ? OR syncAction IS NULL)',
        [manifestoId, 'delete'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLikes() async {
    if (kIsWeb) {
      // Web: Get from SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      return interactions.values.where((interaction) =>
          interaction['type'] == 'like' &&
          (interaction['synced'] == 0 || interaction['synced'] == '0')).toList();
    } else {
      // Mobile: Get from SQLite storage
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.likesTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
      return maps;
    }
  }

  Future<void> markLikeSynced(String likeId) async {
    if (kIsWeb) {
      // Web: Update SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      final likeData = interactions[likeId];
      if (likeData != null) {
        likeData['synced'] = 1;
        await WebStorageHelper.saveManifestoInteraction(likeId, likeData);
      }
      AppLogger.common('🌐 [ManifestoCache] Web marked like synced: $likeId');
    } else {
      // Mobile: Update SQLite storage
      final db = await _dbService.database;
      await db.update(
        LocalDatabaseService.likesTable,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [likeId],
      );
      AppLogger.common('🐘 [ManifestoCache] Mobile marked like synced: $likeId');
    }
  }

  // Poll operations
  Future<void> cachePollVote(String manifestoId, String userId, String option, {bool synced = false}) async {
    final pollId = '${manifestoId}_$userId';
    if (kIsWeb) {
      // Web: Use SharedPreferences storage
      await WebStorageHelper.saveManifestoInteraction(pollId, {
        'id': pollId,
        'type': 'poll',
        'userId': userId,
        'postId': manifestoId,
        'option': option,
        'createdAt': DateTime.now().toIso8601String(),
        'synced': synced ? 1 : 0,
        'syncAction': 'create',
      });
      AppLogger.common('🌐 [ManifestoCache] Web cached poll vote: $manifestoId - $userId');
    } else {
      // Mobile: Use SQLite storage
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
      AppLogger.common('🐘 [ManifestoCache] Mobile cached poll vote: $manifestoId - $userId');
    }
  }

  Future<String?> getCachedUserVote(String manifestoId, String userId) async {
    if (kIsWeb) {
      // Web: Check SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      final pollInteractions = interactions.values.where((interaction) =>
          interaction['type'] == 'poll' &&
          interaction['userId'] == userId &&
          interaction['postId'] == manifestoId &&
          interaction['syncAction'] != 'delete');
      if (pollInteractions.isEmpty) return null;
      return pollInteractions.first['option'] as String?;
    } else {
      // Mobile: Check SQLite storage
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
  }

  Future<Map<String, int>> getCachedPollResults(String manifestoId) async {
    if (kIsWeb) {
      // Web: Count from SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      final pollVotes = interactions.values.where((interaction) =>
          interaction['type'] == 'poll' &&
          interaction['postId'] == manifestoId &&
          interaction['syncAction'] != 'delete');

      final results = <String, int>{};
      for (final vote in pollVotes) {
        final option = vote['option'] as String;
        results[option] = (results[option] ?? 0) + 1;
      }
      return results;
    } else {
      // Mobile: Count from SQLite storage
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
  }

  Future<bool> hasUserVoted(String manifestoId, String userId) async {
    if (kIsWeb) {
      // Web: Check SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      return interactions.values.any((interaction) =>
          interaction['type'] == 'poll' &&
          interaction['userId'] == userId &&
          interaction['postId'] == manifestoId &&
          interaction['syncAction'] != 'delete');
    } else {
      // Mobile: Check SQLite storage
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.pollsTable,
        where: 'manifestoId = ? AND userId = ? AND (syncAction != ? OR syncAction IS NULL)',
        whereArgs: [manifestoId, userId, 'delete'],
        limit: 1,
      );
      return maps.isNotEmpty;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPollVotes() async {
    if (kIsWeb) {
      // Web: Get from SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      return interactions.values.where((interaction) =>
          interaction['type'] == 'poll' &&
          (interaction['synced'] == 0 || interaction['synced'] == '0')).toList();
    } else {
      // Mobile: Get from SQLite storage
      final db = await _dbService.database;
      return await db.query(
        LocalDatabaseService.pollsTable,
        where: 'synced = ?',
        whereArgs: [0],
      );
    }
  }

  Future<void> markPollVoteSynced(String manifestoId, String userId) async {
    final pollId = '${manifestoId}_$userId';
    if (kIsWeb) {
      // Web: Update SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      final pollData = interactions[pollId];
      if (pollData != null) {
        pollData['synced'] = 1;
        await WebStorageHelper.saveManifestoInteraction(pollId, pollData);
      }
      AppLogger.common('🌐 [ManifestoCache] Web marked poll vote synced: $manifestoId - $userId');
    } else {
      // Mobile: Update SQLite storage
      final db = await _dbService.database;
      await db.update(
        LocalDatabaseService.pollsTable,
        {'synced': 1},
        where: 'manifestoId = ? AND userId = ?',
        whereArgs: [manifestoId, userId],
      );
      AppLogger.common('🐘 [ManifestoCache] Mobile marked poll vote synced: $manifestoId - $userId');
    }
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
    if (kIsWeb) {
      // Web: Clear from SharedPreferences storage
      final interactions = await WebStorageHelper.getManifestoInteractions();
      final filteredInteractions = Map<String, Map<String, dynamic>>.fromEntries(
        interactions.entries.where((entry) =>
          (entry.value['synced'] == 0 || entry.value['synced'] == '0')
        )
      );
      // Not a direct replacement of clearSyncedItems functionality
      // This would need to be implemented differently for web
      AppLogger.common('🌐 [ManifestoCache] Web clearSyncedItems needs implementation');
    } else {
      // Mobile: Clear from SQLite storage
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

      AppLogger.common('🐘 [ManifestoCache] Mobile cleared synced items from cache');
    }
  }

  // Cache management
  Future<void> updateManifestoCache(String manifestoId, List<LikeModel> likes, Map<String, int> pollResults) async {
    if (kIsWeb) {
      // Web: Update SharedPreferences storage with server data
      // Clear existing data for this manifesto
      final interactions = await WebStorageHelper.getManifestoInteractions();
      final filteredInteractions = Map<String, Map<String, dynamic>>.fromEntries(
        interactions.entries.where((entry) => entry.value['postId'] != manifestoId)
      );

      // Re-save filtered interactions
      // Note: For full implementation, we'd need to clear and re-add all data

      // Insert new likes
      for (final like in likes) {
        await WebStorageHelper.saveManifestoInteraction(like.id, {
          'id': like.id,
          'type': 'like',
          'userId': like.userId,
          'postId': like.postId,
          'createdAt': like.createdAt.toIso8601String(),
          'synced': 1, // Server data is already synced
          'syncAction': null,
        });
      }

      AppLogger.common('🌐 [ManifestoCache] Web updated cache for manifesto: $manifestoId');
    } else {
      // Mobile: Update SQLite storage
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

      await batch.commit();
      await _dbService.updateCacheMetadata('manifesto_$manifestoId');
      AppLogger.common('🐘 [ManifestoCache] Mobile updated cache for manifesto: $manifestoId');
    }
  }

  Future<DateTime?> getLastManifestoUpdate(String manifestoId) async {
    if (kIsWeb) {
      // Web: Check cache metadata in SharedPreferences
      final metadata = await WebStorageHelper.getCacheMetadata();
      final manifestMetadata = metadata['manifesto_$manifestoId'];
      if (manifestMetadata != null && manifestMetadata['last_updated'] != null) {
        return DateTime.parse(manifestMetadata['last_updated'] as String);
      }
      return null;
    } else {
      // Mobile: Get from LocalDatabaseService
      return await _dbService.getLastUpdateTime('manifesto_$manifestoId');
    }
  }
}
