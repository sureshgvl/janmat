import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/performance_monitor.dart';
import '../../../utils/connection_optimizer.dart';
import '../../../utils/app_logger.dart';
import 'manifesto_cache_service.dart';
import '../../notifications/services/poll_notification_service.dart';

class ManifestoPollService {
  static final PerformanceMonitor _monitor = PerformanceMonitor();
  static final ConnectionOptimizer _connectionOptimizer = ConnectionOptimizer();
  static final ManifestoCacheService _cacheService = ManifestoCacheService();
  static const String _mainPollId = 'main_poll';

  // Prevent multiple simultaneous votes
  static final Map<String, bool> _votingInProgress = {};

  /// Vote on a manifesto poll
  /// Prevents duplicate votes by checking if user already voted
  static Future<void> voteOnPoll(String manifestoId, String userId, String option) async {
    final voteKey = '${manifestoId}_$userId';

    // Prevent multiple simultaneous votes
    if (_votingInProgress[voteKey] == true) {
      AppLogger.common('⚠️ Vote already in progress for $voteKey, skipping');
      return;
    }

    _votingInProgress[voteKey] = true;
    _monitor.startTimer('vote_on_manifesto_poll');

    try {
      // Cache vote locally first
      await _cacheService.cachePollVote(manifestoId, userId, option, synced: false);

      // If online, sync to Firestore
      if (_connectionOptimizer.currentQuality != ConnectionQuality.offline) {
        try {
          final pollRef = FirebaseFirestore.instance
              .collection('manifesto_polls')
              .doc(manifestoId)
              .collection('polls')
              .doc(_mainPollId);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            try {
              final snapshot = await transaction.get(pollRef);

              Map<String, int> votes = {};
              Map<String, String> userVotes = {};

              if (snapshot.exists) {
                final data = snapshot.data()!;
                votes = Map<String, int>.from(data['votes'] ?? {});
                userVotes = Map<String, String>.from(data['userVotes'] ?? {});
              }

              // Check if user already voted
              if (userVotes.containsKey(userId)) {
                // Remove previous vote
                final previousOption = userVotes[userId]!;
                if (votes.containsKey(previousOption)) {
                  votes[previousOption] = (votes[previousOption] ?? 0) - 1;
                }
              }

              // Add new vote
              userVotes[userId] = option;
              votes[option] = (votes[option] ?? 0) + 1;

              transaction.set(pollRef, {
                'pollId': _mainPollId,
                'manifestoId': manifestoId,
                'votes': votes,
                'userVotes': userVotes,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } catch (transactionError) {
              AppLogger.common('Transaction error: $transactionError');
              // Don't rethrow here, let outer catch handle it
              rethrow;
            }
          });

          _monitor.trackFirebaseWrite('manifesto_polls', 1);
          await _cacheService.markPollVoteSynced(manifestoId, userId);
        } catch (e) {
          AppLogger.common('Failed to sync poll vote to Firestore, will retry later: $e');
          // Vote remains in cache as unsynced
        }
      }

      _monitor.stopTimer('vote_on_manifesto_poll');
      AppLogger.common('✅ Vote recorded for manifesto $manifestoId by user $userId on option $option');

      // Send voting reminder notifications (if poll is still active)
      try {
        final pollNotificationService = PollNotificationService();
        // Get manifesto details for notification
        final manifestoResults = await getPollResultsStream(manifestoId).first;
        if (manifestoResults.isNotEmpty) {
          // This is a simplified approach - in a real implementation,
          // we'd need to get the manifesto title and candidate name
          await pollNotificationService.notifyManifestoPollResults(
            manifestoId: manifestoId,
            candidateName: 'Candidate', // This should be fetched from manifesto data
            finalResults: manifestoResults,
          );
          AppLogger.common('🔔 Manifesto poll results notifications sent');
        }
      } catch (e) {
        AppLogger.common('⚠️ Failed to send manifesto poll notifications: $e');
        // Don't fail the vote if notifications fail
      }
    } catch (e) {
      _monitor.stopTimer('vote_on_manifesto_poll');
      AppLogger.common('Error voting on manifesto poll: $e');
      throw Exception('Failed to vote on poll: $e');
    }
    finally {
      // Always clear the voting flag
      _votingInProgress.remove(voteKey);
    }
  }

  /// Get stream of poll results for a manifesto (with offline support)
  static Stream<Map<String, int>> getPollResultsStream(String manifestoId) {
    // If offline, return cached results
    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.fromFuture(_cacheService.getCachedPollResults(manifestoId));
    }

    // Online: Get from Firestore
    final pollRef = FirebaseFirestore.instance
        .collection('manifesto_polls')
        .doc(manifestoId)
        .collection('polls')
        .doc(_mainPollId);

    return pollRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {};
      }

      final data = snapshot.data()!;
      _monitor.trackFirebaseRead('manifesto_polls', 1);

      return Map<String, int>.from(data['votes'] ?? {});
    });
  }

  /// Check if user has already voted on a manifesto poll (with offline support)
  static Future<bool> hasUserVoted(String manifestoId, String userId) async {
    _monitor.startTimer('check_user_voted_manifesto_poll');

    try {
      // Check cache first
      final cachedResult = await _cacheService.hasUserVoted(manifestoId, userId);
      if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
        _monitor.stopTimer('check_user_voted_manifesto_poll');
        return cachedResult;
      }

      // Online: Check Firestore
      final pollRef = FirebaseFirestore.instance
          .collection('manifesto_polls')
          .doc(manifestoId)
          .collection('polls')
          .doc(_mainPollId);

      final snapshot = await pollRef.get();

      if (!snapshot.exists) {
        _monitor.stopTimer('check_user_voted_manifesto_poll');
        _monitor.trackFirebaseRead('manifesto_polls', 1);
        return false;
      }

      final data = snapshot.data()!;
      final userVotes = Map<String, String>.from(data['userVotes'] ?? {});

      _monitor.stopTimer('check_user_voted_manifesto_poll');
      _monitor.trackFirebaseRead('manifesto_polls', 1);

      return userVotes.containsKey(userId);
    } catch (e) {
      _monitor.stopTimer('check_user_voted_manifesto_poll');
      AppLogger.common('Error checking user vote: $e');
      // Fall back to cache
      return await _cacheService.hasUserVoted(manifestoId, userId);
    }
  }

  /// Get stream of user's current vote on a manifesto poll (with offline support)
  static Stream<String?> getUserVoteStream(String manifestoId, String userId) {
    // If offline, return cached result as stream
    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.fromFuture(_cacheService.getCachedUserVote(manifestoId, userId));
    }

    // Online: Get from Firestore as stream
    final pollRef = FirebaseFirestore.instance
        .collection('manifesto_polls')
        .doc(manifestoId)
        .collection('polls')
        .doc(_mainPollId);

    return pollRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data()!;
      _monitor.trackFirebaseRead('manifesto_polls', 1);

      final userVotes = Map<String, String>.from(data['userVotes'] ?? {});
      return userVotes[userId];
    });
  }

  /// Get user's current vote on a manifesto poll (with offline support)
  static Future<String?> getUserVote(String manifestoId, String userId) async {
    _monitor.startTimer('get_user_vote_manifesto_poll');

    try {
      // Check cache first
      final cachedResult = await _cacheService.getCachedUserVote(manifestoId, userId);
      if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
        _monitor.stopTimer('get_user_vote_manifesto_poll');
        return cachedResult;
      }

      // Online: Check Firestore
      final pollRef = FirebaseFirestore.instance
          .collection('manifesto_polls')
          .doc(manifestoId)
          .collection('polls')
          .doc(_mainPollId);

      final snapshot = await pollRef.get();

      if (!snapshot.exists) {
        _monitor.stopTimer('get_user_vote_manifesto_poll');
        _monitor.trackFirebaseRead('manifesto_polls', 1);
        return null;
      }

      final data = snapshot.data()!;
      final userVotes = Map<String, String>.from(data['userVotes'] ?? {});

      _monitor.stopTimer('get_user_vote_manifesto_poll');
      _monitor.trackFirebaseRead('manifesto_polls', 1);

      return userVotes[userId];
    } catch (e) {
      _monitor.stopTimer('get_user_vote_manifesto_poll');
      AppLogger.common('Error getting user vote: $e');
      // Fall back to cache
      return await _cacheService.getCachedUserVote(manifestoId, userId);
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return _monitor.getFirebaseSummary();
  }
}
