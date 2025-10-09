import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/user_model.dart';

/// Service for collecting and aggregating analytics data
class AnalyticsDataCollectionService {
  static final AnalyticsDataCollectionService _instance = AnalyticsDataCollectionService._internal();
  factory AnalyticsDataCollectionService() => _instance;

  AnalyticsDataCollectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track profile view event
  Future<void> trackProfileView({
    required String candidateId,
    String? viewerId,
    String? viewerRole,
    String? source, // 'search', 'feed', 'direct', etc.
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      final batch = _firestore.batch();

      // Record in candidate analytics
      final candidateAnalyticsRef = _getCandidateAnalyticsRef(candidateId);
      batch.update(candidateAnalyticsRef, {
        'profile_views': FieldValue.increment(1),
        'last_viewed_at': timestamp,
        'updated_at': timestamp,
      });

      // Record detailed view event
      final viewEventRef = candidateAnalyticsRef.collection('profile_views').doc();
      batch.set(viewEventRef, {
        'viewer_id': viewerId,
        'viewer_role': viewerRole ?? 'anonymous',
        'source': source ?? 'unknown',
        'timestamp': timestamp,
        'metadata': metadata,
        'user_agent': 'mobile_app', // Could be expanded for web tracking
      });

      // Update daily stats
      final today = DateTime.now();
      final dailyStatsRef = candidateAnalyticsRef
          .collection('daily_stats')
          .doc('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');

      batch.set(dailyStatsRef, {
        'date': Timestamp.fromDate(today),
        'profile_views': FieldValue.increment(1),
        'unique_viewers': viewerId != null ? FieldValue.arrayUnion([viewerId]) : [],
        'updated_at': timestamp,
      }, SetOptions(merge: true));

      await batch.commit();

      AppLogger.common('📊 Tracked profile view for candidate: $candidateId');
    } catch (e) {
      AppLogger.common('❌ Failed to track profile view: $e');
      // Don't throw - analytics failures shouldn't break user experience
    }
  }

  /// Track manifesto interaction
  Future<void> trackManifestoInteraction({
    required String candidateId,
    required String interactionType, // 'view', 'download', 'share', 'like', 'comment'
    String? userId,
    String? section, // specific section of manifesto
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      final batch = _firestore.batch();

      final candidateAnalyticsRef = _getCandidateAnalyticsRef(candidateId);

      // Update manifesto metrics
      final updateData = <String, dynamic>{
        'updated_at': timestamp,
      };

      switch (interactionType) {
        case 'view':
          updateData['manifesto_views'] = FieldValue.increment(1);
          break;
        case 'download':
          updateData['manifesto_downloads'] = FieldValue.increment(1);
          break;
        case 'share':
          updateData['manifesto_shares'] = FieldValue.increment(1);
          break;
        case 'like':
          updateData['manifesto_likes'] = FieldValue.increment(1);
          break;
        case 'comment':
          updateData['manifesto_comments'] = FieldValue.increment(1);
          break;
      }

      batch.update(candidateAnalyticsRef, updateData);

      // Record detailed interaction event
      final interactionRef = candidateAnalyticsRef.collection('manifesto_interactions').doc();
      batch.set(interactionRef, {
        'user_id': userId,
        'interaction_type': interactionType,
        'section': section,
        'timestamp': timestamp,
        'metadata': metadata,
      });

      await batch.commit();

      AppLogger.common('📊 Tracked manifesto interaction: $interactionType for candidate: $candidateId');
    } catch (e) {
      AppLogger.common('❌ Failed to track manifesto interaction: $e');
    }
  }

  /// Track content engagement
  Future<void> trackContentEngagement({
    required String candidateId,
    required String contentType, // 'post', 'event', 'poll', 'highlight'
    required String contentId,
    required String engagementType, // 'view', 'like', 'share', 'comment', 'click'
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      final batch = _firestore.batch();

      final candidateAnalyticsRef = _getCandidateAnalyticsRef(candidateId);

      // Update content engagement metrics
      final engagementRef = candidateAnalyticsRef.collection('content_engagement').doc(contentId);
      batch.set(engagementRef, {
        'content_type': contentType,
        'content_id': contentId,
        'total_views': engagementType == 'view' ? FieldValue.increment(1) : 0,
        'total_likes': engagementType == 'like' ? FieldValue.increment(1) : 0,
        'total_shares': engagementType == 'share' ? FieldValue.increment(1) : 0,
        'total_comments': engagementType == 'comment' ? FieldValue.increment(1) : 0,
        'total_clicks': engagementType == 'click' ? FieldValue.increment(1) : 0,
        'last_engaged_at': timestamp,
        'updated_at': timestamp,
      }, SetOptions(merge: true));

      // Record individual engagement event
      final eventRef = engagementRef.collection('events').doc();
      batch.set(eventRef, {
        'user_id': userId,
        'engagement_type': engagementType,
        'timestamp': timestamp,
        'metadata': metadata,
      });

      await batch.commit();

      AppLogger.common('📊 Tracked content engagement: $engagementType on $contentType for candidate: $candidateId');
    } catch (e) {
      AppLogger.common('❌ Failed to track content engagement: $e');
    }
  }

  /// Aggregate demographic data
  Future<void> aggregateDemographicData(String candidateId) async {
    try {
      final candidateAnalyticsRef = _getCandidateAnalyticsRef(candidateId);

      // Get follower demographics
      final followersSnapshot = await _getCandidateFollowersSnapshot(candidateId);
      final demographics = await _calculateDemographics(followersSnapshot.docs);

      // Update demographics in analytics
      await candidateAnalyticsRef.update({
        'demographics': demographics,
        'demographics_last_updated': FieldValue.serverTimestamp(),
      });

      AppLogger.common('📊 Aggregated demographic data for candidate: $candidateId');
    } catch (e) {
      AppLogger.common('❌ Failed to aggregate demographic data: $e');
    }
  }

  /// Calculate growth trends
  Future<void> calculateGrowthTrends(String candidateId) async {
    try {
      final candidateAnalyticsRef = _getCandidateAnalyticsRef(candidateId);

      // Get historical data for the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final dailyStatsQuery = candidateAnalyticsRef
          .collection('daily_stats')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('date', descending: false);

      final dailyStatsSnapshot = await dailyStatsQuery.get();

      final growthData = <Map<String, dynamic>>[];
      int previousFollowers = 0;

      for (var doc in dailyStatsSnapshot.docs) {
        final data = doc.data();
        final followers = (data['unique_viewers'] as List?)?.length ?? 0;
        final date = (data['date'] as Timestamp).toDate();

        growthData.add({
          'date': date,
          'followers': followers,
          'growth': followers - previousFollowers,
          'profile_views': data['profile_views'] ?? 0,
        });

        previousFollowers = followers;
      }

      // Calculate trends
      final trends = _calculateTrends(growthData);

      await candidateAnalyticsRef.update({
        'follower_growth': growthData,
        'growth_trends': trends,
        'trends_last_calculated': FieldValue.serverTimestamp(),
      });

      AppLogger.common('📊 Calculated growth trends for candidate: $candidateId');
    } catch (e) {
      AppLogger.common('❌ Failed to calculate growth trends: $e');
    }
  }

  /// Get candidate analytics reference
  DocumentReference _getCandidateAnalyticsRef(String candidateId) {
    return _firestore.collection('candidate_analytics').doc(candidateId);
  }

  /// Get candidate followers snapshot
  Future<QuerySnapshot> _getCandidateFollowersSnapshot(String candidateId) async {
    // This would need to be implemented based on the candidate location structure
    // For now, return empty snapshot
    return Future.value() as Future<QuerySnapshot>;
  }

  /// Calculate demographics from follower data
  Future<Map<String, dynamic>> _calculateDemographics(List<QueryDocumentSnapshot> followers) async {
    final demographics = <String, dynamic>{
      'total_followers': followers.length,
      'age_groups': <String, int>{},
      'gender_distribution': <String, int>{},
      'geographic_distribution': <String, int>{},
      'interests': <String, int>{},
    };

    for (var followerDoc in followers) {
      final followerData = followerDoc.data() as Map<String, dynamic>;
      final userId = followerDoc.id;

      try {
        // Get user profile data
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;

          // Age groups
          final age = userData['age'] as int?;
          if (age != null) {
            final ageGroup = _getAgeGroup(age);
            demographics['age_groups'][ageGroup] = (demographics['age_groups'][ageGroup] ?? 0) + 1;
          }

          // Gender distribution
          final gender = userData['gender'] as String?;
          if (gender != null) {
            demographics['gender_distribution'][gender] = (demographics['gender_distribution'][gender] ?? 0) + 1;
          }

          // Geographic distribution (simplified)
          final state = userData['state'] as String?;
          if (state != null) {
            demographics['geographic_distribution'][state] = (demographics['geographic_distribution'][state] ?? 0) + 1;
          }
        }
      } catch (e) {
        AppLogger.common('⚠️ Failed to get demographic data for user $userId: $e');
      }
    }

    return demographics;
  }

  /// Calculate growth trends and analytics
  Map<String, dynamic> _calculateTrends(List<Map<String, dynamic>> growthData) {
    if (growthData.isEmpty) {
      return {
        'average_daily_growth': 0.0,
        'growth_rate': 0.0,
        'trend_direction': 'stable',
        'peak_growth_day': null,
        'total_growth_30d': 0,
      };
    }

    final totalGrowth = growthData.last['followers'] - growthData.first['followers'];
    final averageDailyGrowth = growthData.length > 1 ? totalGrowth / growthData.length : 0.0;

    // Calculate growth rate (percentage)
    final initialFollowers = growthData.first['followers'];
    final growthRate = initialFollowers > 0 ? (totalGrowth / initialFollowers) * 100 : 0.0;

    // Determine trend direction
    String trendDirection = 'stable';
    if (averageDailyGrowth > 0.5) {
      trendDirection = 'growing';
    } else if (averageDailyGrowth < -0.5) {
      trendDirection = 'declining';
    }

    // Find peak growth day
    Map<String, dynamic>? peakGrowthDay;
    int maxGrowth = 0;
    for (var data in growthData) {
      final growth = data['growth'] as int;
      if (growth > maxGrowth) {
        maxGrowth = growth;
        peakGrowthDay = data;
      }
    }

    return {
      'average_daily_growth': averageDailyGrowth,
      'growth_rate': growthRate,
      'trend_direction': trendDirection,
      'peak_growth_day': peakGrowthDay,
      'total_growth_30d': totalGrowth,
    };
  }

  /// Get age group from age
  String _getAgeGroup(int age) {
    if (age < 18) return 'under_18';
    if (age < 25) return '18_24';
    if (age < 35) return '25_34';
    if (age < 45) return '35_44';
    if (age < 55) return '45_54';
    if (age < 65) return '55_64';
    return '65_plus';
  }

  /// Batch update analytics data (for scheduled jobs)
  Future<void> batchUpdateAnalytics() async {
    try {
      AppLogger.common('🔄 Starting batch analytics update...');

      // Get all candidates with analytics
      final candidatesSnapshot = await _firestore.collection('candidate_analytics').get();

      for (var candidateDoc in candidatesSnapshot.docs) {
        final candidateId = candidateDoc.id;

        // Update demographics
        await aggregateDemographicData(candidateId);

        // Update growth trends
        await calculateGrowthTrends(candidateId);

        // Small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      AppLogger.common('✅ Batch analytics update completed');
    } catch (e) {
      AppLogger.common('❌ Batch analytics update failed: $e');
    }
  }

  /// Clean up old analytics data (for maintenance)
  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      // Clean up old profile view events
      final analyticsSnapshot = await _firestore.collection('candidate_analytics').get();

      for (var candidateDoc in analyticsSnapshot.docs) {
        final candidateId = candidateDoc.id;
        final candidateAnalyticsRef = _getCandidateAnalyticsRef(candidateId);

        // Clean up old profile view events
        final oldViewsQuery = candidateAnalyticsRef
            .collection('profile_views')
            .where('timestamp', isLessThan: cutoffTimestamp);

        final oldViewsSnapshot = await oldViewsQuery.get();
        final batch = _firestore.batch();

        for (var doc in oldViewsSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Clean up old interaction events
        final oldInteractionsQuery = candidateAnalyticsRef
            .collection('manifesto_interactions')
            .where('timestamp', isLessThan: cutoffTimestamp);

        final oldInteractionsSnapshot = await oldInteractionsQuery.get();
        for (var doc in oldInteractionsSnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      AppLogger.common('🧹 Cleaned up old analytics data older than $daysToKeep days');
    } catch (e) {
      AppLogger.common('❌ Failed to cleanup old analytics data: $e');
    }
  }
}