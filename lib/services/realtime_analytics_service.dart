import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/connection_optimizer.dart';
import '../utils/app_logger.dart';

/// Service for real-time analytics streaming
class RealtimeAnalyticsService {
  static final RealtimeAnalyticsService _instance = RealtimeAnalyticsService._internal();
  factory RealtimeAnalyticsService() => _instance;

  RealtimeAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectionOptimizer _connectionOptimizer = ConnectionOptimizer();

  // Stream subscriptions cache to prevent memory leaks
  final Map<String, StreamSubscription> _activeSubscriptions = {};

  /// Get real-time follower count stream for a candidate
  Stream<int> getFollowerCountStream(String candidateId) {
    final streamKey = 'follower_count_$candidateId';

    // Cancel existing subscription if any
    _activeSubscriptions[streamKey]?.cancel();

    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      // Return cached/static value when offline
      return Stream.value(0);
    }

    // Find candidate location first
    return _getCandidateLocationStream(candidateId).asyncMap((location) async {
      if (location == null) return 0;

      final snapshot = await _firestore
          .collection('states')
          .doc(location['stateId'])
          .collection('districts')
          .doc(location['districtId'])
          .collection('bodies')
          .doc(location['bodyId'])
          .collection('wards')
          .doc(location['wardId'])
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .get();

      return snapshot.docs.length;
    }).asBroadcastStream();
  }

  /// Get real-time profile views stream for a candidate
  Stream<int> getProfileViewsStream(String candidateId) {
    final streamKey = 'profile_views_$candidateId';

    // Cancel existing subscription if any
    _activeSubscriptions[streamKey]?.cancel();

    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.value(0);
    }

    // Profile views are stored in candidate analytics
    return _getCandidateDocumentStream(candidateId).map((doc) {
      if (doc == null || !doc.exists || doc.data() == null) return 0;
      final data = doc.data() as Map<String, dynamic>;
      final analytics = data['extra_info']?['analytics'] as Map<String, dynamic>?;
      return analytics?['profile_views'] ?? 0;
    });
  }

  /// Get real-time manifesto views stream for a candidate
  Stream<int> getManifestoViewsStream(String candidateId) {
    final streamKey = 'manifesto_views_$candidateId';

    // Cancel existing subscription if any
    _activeSubscriptions[streamKey]?.cancel();

    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.value(0);
    }

    return _getCandidateDocumentStream(candidateId).map((doc) {
      if (doc == null || !doc.exists || doc.data() == null) return 0;
      final data = doc.data() as Map<String, dynamic>;
      final analytics = data['extra_info']?['analytics'] as Map<String, dynamic>?;
      return analytics?['manifesto_views'] ?? 0;
    });
  }

  /// Get real-time engagement rate stream for a candidate
  Stream<double> getEngagementRateStream(String candidateId) {
    final streamKey = 'engagement_rate_$candidateId';

    // Cancel existing subscription if any
    _activeSubscriptions[streamKey]?.cancel();

    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.value(0.0);
    }

    return _getCandidateDocumentStream(candidateId).map((doc) {
      if (doc == null || !doc.exists || doc.data() == null) return 0.0;
      final data = doc.data() as Map<String, dynamic>;
      final analytics = data['extra_info']?['analytics'] as Map<String, dynamic>?;
      return (analytics?['engagement_rate'] ?? 0.0).toDouble();
    });
  }

  /// Get combined analytics stream with multiple metrics
  Stream<Map<String, dynamic>> getCombinedAnalyticsStream(String candidateId) {
    final streamKey = 'combined_analytics_$candidateId';

    // Cancel existing subscription if any
    _activeSubscriptions[streamKey]?.cancel();

    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.value({
        'followerCount': 0,
        'profileViews': 0,
        'manifestoViews': 0,
        'engagementRate': 0.0,
      });
    }

    return _getCandidateDocumentStream(candidateId).asyncMap((doc) async {
      if (doc == null || !doc.exists) {
        return {
          'followerCount': 0,
          'profileViews': 0,
          'manifestoViews': 0,
          'engagementRate': 0.0,
        };
      }

      final data = doc.data() as Map<String, dynamic>;
      final analytics = data['extra_info']?['analytics'] as Map<String, dynamic>?;

      // Get follower count separately
      final location = await _getCandidateLocation(candidateId);
      int followerCount = 0;
      if (location != null) {
        final snapshot = await _firestore
            .collection('states')
            .doc(location['stateId'])
            .collection('districts')
            .doc(location['districtId'])
            .collection('bodies')
            .doc(location['bodyId'])
            .collection('wards')
            .doc(location['wardId'])
            .collection('candidates')
            .doc(candidateId)
            .collection('followers')
            .get();
        followerCount = snapshot.docs.length;
      }

      return {
        'followerCount': followerCount,
        'profileViews': analytics?['profile_views'] ?? 0,
        'manifestoViews': analytics?['manifesto_views'] ?? 0,
        'engagementRate': (analytics?['engagement_rate'] ?? 0.0).toDouble(),
      };
    }).asBroadcastStream();
  }

  /// Get candidate document stream
  Stream<DocumentSnapshot?> _getCandidateDocumentStream(String candidateId) {
    return _getCandidateLocationStream(candidateId).asyncMap((location) async {
      if (location == null) {
        // Return null for location not found
        return null;
      }

      return _firestore
          .collection('states')
          .doc(location['stateId'])
          .collection('districts')
          .doc(location['districtId'])
          .collection('bodies')
          .doc(location['bodyId'])
          .collection('wards')
          .doc(location['wardId'])
          .collection('candidates')
          .doc(candidateId)
          .snapshots()
          .first;
    });
  }

  /// Get candidate location (state, district, body, ward)
  Future<Map<String, String>?> _getCandidateLocation(String candidateId) async {
    try {
      // First try to get from index
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();

      if (indexDoc.exists) {
        final data = indexDoc.data()!;
        return {
          'stateId': data['stateId'],
          'districtId': data['districtId'],
          'bodyId': data['bodyId'],
          'wardId': data['wardId'],
        };
      }

      // Fallback: Search across all states
      final statesSnapshot = await _firestore.collection('states').get();

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (var bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (var wardDoc in wardsSnapshot.docs) {
              final candidateDoc = await wardDoc.reference
                  .collection('candidates')
                  .doc(candidateId)
                  .get();

              if (candidateDoc.exists) {
                return {
                  'stateId': stateDoc.id,
                  'districtId': districtDoc.id,
                  'bodyId': bodyDoc.id,
                  'wardId': wardDoc.id,
                };
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      AppLogger.common('Error getting candidate location: $e');
      return null;
    }
  }

  /// Get candidate location as a stream
  Stream<Map<String, String>?> _getCandidateLocationStream(String candidateId) {
    return Stream.fromFuture(_getCandidateLocation(candidateId));
  }

  /// Cancel all active subscriptions
  void cancelAllSubscriptions() {
    for (var subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    AppLogger.common('Cancelled all real-time analytics subscriptions');
  }

  /// Cancel subscription for specific stream
  void cancelSubscription(String streamKey) {
    _activeSubscriptions[streamKey]?.cancel();
    _activeSubscriptions.remove(streamKey);
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'activeSubscriptions': _activeSubscriptions.length,
      'subscriptionKeys': _activeSubscriptions.keys.toList(),
    };
  }
}
