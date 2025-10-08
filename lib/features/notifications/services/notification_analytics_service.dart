import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import '../models/notification_type.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/notification_repository_impl.dart';

/// Service for tracking and analyzing notification effectiveness
class NotificationAnalyticsService {
  final NotificationRepository _notificationRepository = NotificationRepositoryImpl();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track notification delivery
  Future<void> trackNotificationDelivered({
    required String userId,
    required String notificationId,
    required NotificationType type,
    required String deliveryMethod, // 'push', 'in_app', 'both'
  }) async {
    try {
      await _firestore.collection('notification_analytics').add({
        'userId': userId,
        'notificationId': notificationId,
        'type': type.name,
        'event': 'delivered',
        'deliveryMethod': deliveryMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      });

      AppLogger.common('📊 Tracked notification delivery: $notificationId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to track notification delivery', error: e);
    }
  }

  /// Track notification opened/tapped
  Future<void> trackNotificationOpened({
    required String userId,
    required String notificationId,
    required NotificationType type,
    required String deliveryMethod,
  }) async {
    try {
      await _firestore.collection('notification_analytics').add({
        'userId': userId,
        'notificationId': notificationId,
        'type': type.name,
        'event': 'opened',
        'deliveryMethod': deliveryMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      });

      AppLogger.common('📊 Tracked notification opened: $notificationId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to track notification opened', error: e);
    }
  }

  /// Track notification dismissed
  Future<void> trackNotificationDismissed({
    required String userId,
    required String notificationId,
    required NotificationType type,
  }) async {
    try {
      await _firestore.collection('notification_analytics').add({
        'userId': userId,
        'notificationId': notificationId,
        'type': type.name,
        'event': 'dismissed',
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      });

      AppLogger.common('📊 Tracked notification dismissed: $notificationId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to track notification dismissed', error: e);
    }
  }

  /// Get notification analytics for a user
  Future<Map<String, dynamic>> getUserNotificationAnalytics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final snapshot = await _firestore
          .collection('notification_analytics')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final analytics = <String, dynamic>{
        'totalDelivered': 0,
        'totalOpened': 0,
        'totalDismissed': 0,
        'openRate': 0.0,
        'byType': <String, Map<String, int>>{},
        'byDeliveryMethod': <String, Map<String, int>>{},
        'dailyStats': <String, Map<String, int>>{},
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final event = data['event'] as String;
        final type = data['type'] as String;
        final deliveryMethod = data['deliveryMethod'] as String? ?? 'unknown';
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dayKey = timestamp.toIso8601String().split('T')[0];

        // Count events
        switch (event) {
          case 'delivered':
            analytics['totalDelivered'] = (analytics['totalDelivered'] as int) + 1;
            break;
          case 'opened':
            analytics['totalOpened'] = (analytics['totalOpened'] as int) + 1;
            break;
          case 'dismissed':
            analytics['totalDismissed'] = (analytics['totalDismissed'] as int) + 1;
            break;
        }

        // Group by type
        analytics['byType'][type] ??= {'delivered': 0, 'opened': 0, 'dismissed': 0};
        analytics['byType'][type][event] = (analytics['byType'][type][event] as int) + 1;

        // Group by delivery method
        analytics['byDeliveryMethod'][deliveryMethod] ??= {'delivered': 0, 'opened': 0, 'dismissed': 0};
        analytics['byDeliveryMethod'][deliveryMethod][event] = (analytics['byDeliveryMethod'][deliveryMethod][event] as int) + 1;

        // Daily stats
        analytics['dailyStats'][dayKey] ??= {'delivered': 0, 'opened': 0, 'dismissed': 0};
        analytics['dailyStats'][dayKey][event] = (analytics['dailyStats'][dayKey][event] as int) + 1;
      }

      // Calculate open rate
      final totalDelivered = analytics['totalDelivered'] as int;
      final totalOpened = analytics['totalOpened'] as int;
      if (totalDelivered > 0) {
        analytics['openRate'] = (totalOpened / totalDelivered) * 100;
      }

      return analytics;
    } catch (e) {
      AppLogger.commonError('❌ Failed to get user notification analytics', error: e);
      return {};
    }
  }

  /// Get notification performance by type
  Future<Map<String, double>> getNotificationPerformanceByType(String userId) async {
    try {
      final analytics = await getUserNotificationAnalytics(userId);
      final byType = analytics['byType'] as Map<String, Map<String, int>>;

      final performance = <String, double>{};
      for (final entry in byType.entries) {
        final type = entry.key;
        final stats = entry.value;
        final delivered = stats['delivered'] ?? 0;
        final opened = stats['opened'] ?? 0;

        if (delivered > 0) {
          performance[type] = (opened / delivered) * 100;
        } else {
          performance[type] = 0.0;
        }
      }

      return performance;
    } catch (e) {
      AppLogger.commonError('❌ Failed to get notification performance by type', error: e);
      return {};
    }
  }

  /// Get overall notification effectiveness
  Future<Map<String, dynamic>> getOverallNotificationEffectiveness({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final snapshot = await _firestore
          .collection('notification_analytics')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final stats = <String, dynamic>{
        'totalDelivered': 0,
        'totalOpened': 0,
        'totalDismissed': 0,
        'overallOpenRate': 0.0,
        'mostEffectiveType': '',
        'leastEffectiveType': '',
        'platformBreakdown': <String, Map<String, int>>{},
      };

      final typeStats = <String, Map<String, int>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final event = data['event'] as String;
        final type = data['type'] as String;
        final platform = data['platform'] as String? ?? 'unknown';

        // Overall counts
        switch (event) {
          case 'delivered':
            stats['totalDelivered'] = (stats['totalDelivered'] as int) + 1;
            break;
          case 'opened':
            stats['totalOpened'] = (stats['totalOpened'] as int) + 1;
            break;
          case 'dismissed':
            stats['totalDismissed'] = (stats['totalDismissed'] as int) + 1;
            break;
        }

        // Type stats
        typeStats[type] ??= {'delivered': 0, 'opened': 0, 'dismissed': 0};
        typeStats[type]![event] = (typeStats[type]![event] as int) + 1;

        // Platform breakdown
        stats['platformBreakdown'][platform] ??= {'delivered': 0, 'opened': 0, 'dismissed': 0};
        stats['platformBreakdown'][platform][event] = (stats['platformBreakdown'][platform][event] as int) + 1;
      }

      // Calculate overall open rate
      final totalDelivered = stats['totalDelivered'] as int;
      final totalOpened = stats['totalOpened'] as int;
      if (totalDelivered > 0) {
        stats['overallOpenRate'] = (totalOpened / totalDelivered) * 100;
      }

      // Find most and least effective types
      String mostEffective = '';
      String leastEffective = '';
      double highestRate = 0.0;
      double lowestRate = 100.0;

      for (final entry in typeStats.entries) {
        final type = entry.key;
        final typeData = entry.value;
        final delivered = typeData['delivered'] ?? 0;
        final opened = typeData['opened'] ?? 0;

        if (delivered > 0) {
          final rate = (opened / delivered) * 100;
          if (rate > highestRate) {
            highestRate = rate;
            mostEffective = type;
          }
          if (rate < lowestRate) {
            lowestRate = rate;
            leastEffective = type;
          }
        }
      }

      stats['mostEffectiveType'] = mostEffective;
      stats['leastEffectiveType'] = leastEffective;

      return stats;
    } catch (e) {
      AppLogger.commonError('❌ Failed to get overall notification effectiveness', error: e);
      return {};
    }
  }

  /// Clean up old analytics data (older than specified days)
  Future<void> cleanupOldAnalytics(int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('notification_analytics')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.common('🧹 Cleaned up ${snapshot.docs.length} old analytics records');
    } catch (e) {
      AppLogger.commonError('❌ Failed to cleanup old analytics', error: e);
    }
  }

  /// Get platform information
  String _getPlatform() {
    // This would be more sophisticated in a real implementation
    // For now, return a simple platform identifier
    return 'mobile'; // Could be 'android', 'ios', 'web', etc.
  }
}
