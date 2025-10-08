import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../utils/connection_optimizer.dart';
import 'manifesto_cache_service.dart';

class ManifestoSyncService {
  static final ManifestoSyncService _instance = ManifestoSyncService._internal();
  factory ManifestoSyncService() => _instance;

  ManifestoSyncService._internal() {
    _initialize();
  }

  final ConnectionOptimizer _connectionOptimizer = ConnectionOptimizer();
  final ManifestoCacheService _cacheService = ManifestoCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<ConnectionQuality>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _syncInProgress = false;

  void _initialize() {
    // Listen to connectivity changes
    _connectivitySubscription = _connectionOptimizer.qualityStream.listen(_onConnectivityChanged);

    // Start periodic sync check
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_connectionOptimizer.currentQuality != ConnectionQuality.offline) {
        _performSync();
      }
    });

    AppLogger.common('🔄 ManifestoSyncService initialized');
  }

  void _onConnectivityChanged(ConnectionQuality quality) {
    if (quality != ConnectionQuality.offline) {
      // Came back online, trigger sync
      AppLogger.common('🌐 Connection restored, starting manifesto sync...');
      _performSync();
    } else {
      AppLogger.common('📴 Connection lost, manifesto sync paused');
    }
  }

  Future<void> _performSync() async {
    if (_syncInProgress) {
      AppLogger.common('🔄 Sync already in progress, skipping');
      return;
    }

    _syncInProgress = true;
    try {
      AppLogger.common('🔄 Starting manifesto sync...');

      final pendingItems = await _cacheService.getPendingSyncItems();
      int syncedCount = 0;

      // Sync comments
      for (final comment in pendingItems['comments'] as List) {
        try {
          await _syncComment(comment);
          syncedCount++;
        } catch (e) {
          AppLogger.commonError('❌ Failed to sync comment ${comment.id}', error: e);
        }
      }

      // Sync likes
      for (final like in pendingItems['likes'] as List) {
        try {
          await _syncLike(like);
          syncedCount++;
        } catch (e) {
          AppLogger.commonError('❌ Failed to sync like ${like.id}', error: e);
        }
      }

      // Sync polls
      for (final poll in pendingItems['polls'] as List<Map<String, dynamic>>) {
        try {
          await _syncPollVote(poll);
          syncedCount++;
        } catch (e) {
          AppLogger.commonError('❌ Failed to sync poll vote', error: e);
        }
      }

      if (syncedCount > 0) {
        AppLogger.common('✅ Manifesto sync completed: $syncedCount items synced');
      } else {
        AppLogger.common('ℹ️ No pending manifesto items to sync');
      }
    } catch (e) {
      AppLogger.commonError('❌ Manifesto sync failed', error: e);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncComment(dynamic comment) async {
    final commentsRef = _firestore.collection('comments');

    if (comment.syncAction == 'delete') {
      // Find and delete from Firestore
      final query = await commentsRef
          .where('userId', isEqualTo: comment.userId)
          .where('postId', isEqualTo: comment.postId)
          .where('text', isEqualTo: comment.text)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } else {
      // Add to Firestore
      await commentsRef.add(comment.toJson());
    }

    await _cacheService.markCommentSynced(comment.id);
  }

  Future<void> _syncLike(dynamic like) async {
    final likesRef = _firestore.collection('likes');

    if (like.syncAction == 'delete') {
      // Find and delete from Firestore
      final query = await likesRef
          .where('userId', isEqualTo: like.userId)
          .where('postId', isEqualTo: like.postId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } else {
      // Add to Firestore
      await likesRef.add(like.toJson());
    }

    await _cacheService.markLikeSynced(like.id);
  }

  Future<void> _syncPollVote(Map<String, dynamic> pollData) async {
    final pollRef = _firestore
        .collection('manifesto_polls')
        .doc(pollData['manifestoId'])
        .collection('polls')
        .doc('main_poll');

    if (pollData['syncAction'] == 'delete') {
      // Remove vote from poll
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(pollRef);
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final userVotes = Map<String, String>.from(data['userVotes'] ?? {});
          final votes = Map<String, int>.from(data['votes'] ?? {});

          final userId = pollData['userId'];
          if (userVotes.containsKey(userId)) {
            final option = userVotes[userId]!;
            userVotes.remove(userId);
            if (votes.containsKey(option)) {
              votes[option] = (votes[option] ?? 0) - 1;
            }

            transaction.update(pollRef, {
              'userVotes': userVotes,
              'votes': votes,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });
    } else {
      // Add vote to poll
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(pollRef);

        Map<String, int> votes = {};
        Map<String, String> userVotes = {};

        if (snapshot.exists) {
          final data = snapshot.data()!;
          votes = Map<String, int>.from(data['votes'] ?? {});
          userVotes = Map<String, String>.from(data['userVotes'] ?? {});
        }

        final userId = pollData['userId'];
        final option = pollData['option'];

        // Remove previous vote if exists
        if (userVotes.containsKey(userId)) {
          final previousOption = userVotes[userId]!;
          if (votes.containsKey(previousOption)) {
            votes[previousOption] = (votes[previousOption] ?? 0) - 1;
          }
        }

        // Add new vote
        userVotes[userId] = option;
        votes[option] = (votes[option] ?? 0) + 1;

        transaction.set(pollRef, {
          'pollId': 'main_poll',
          'manifestoId': pollData['manifestoId'],
          'votes': votes,
          'userVotes': userVotes,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    }

    await _cacheService.markPollVoteSynced(pollData['manifestoId'], pollData['userId']);
  }

  /// Force immediate sync
  Future<void> forceSync() async {
    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      throw Exception('Cannot sync while offline');
    }

    if (_syncInProgress) {
      throw Exception('Sync already in progress');
    }

    await _performSync();
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingItems = await _cacheService.getPendingSyncItems();
    return {
      'isOnline': _connectionOptimizer.currentQuality != ConnectionQuality.offline,
      'pendingComments': (pendingItems['comments'] as List).length,
      'pendingLikes': (pendingItems['likes'] as List).length,
      'pendingPolls': (pendingItems['polls'] as List).length,
    };
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    AppLogger.common('🧹 ManifestoSyncService disposed');
  }
}
