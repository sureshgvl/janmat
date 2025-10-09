import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../features/candidate/models/candidate_model.dart';
import '../utils/app_logger.dart';

/// Service for exporting analytics data
class AnalyticsExportService {
  static final AnalyticsExportService _instance = AnalyticsExportService._internal();
  factory AnalyticsExportService() => _instance;

  AnalyticsExportService._internal();

  /// Export analytics data to CSV format
  Future<String> exportAnalyticsToCSV(Candidate candidate) async {
    try {
      final analytics = candidate.extraInfo?.analytics;
      if (analytics == null) {
        throw Exception('No analytics data available');
      }

      final buffer = StringBuffer();

      // Add header
      buffer.writeln('Analytics Report for ${candidate.name}');
      buffer.writeln('Generated on: ${DateTime.now().toString()}');
      buffer.writeln('');

      // Profile metrics
      buffer.writeln('PROFILE METRICS');
      buffer.writeln('Metric,Value');
      buffer.writeln('Profile Views,${analytics.profileViews ?? 0}');
      buffer.writeln('Manifesto Views,${analytics.manifestoViews ?? 0}');
      buffer.writeln('Engagement Rate,${analytics.engagementRate?.toStringAsFixed(2) ?? '0.00'}%');
      buffer.writeln('Followers,${candidate.followersCount}');
      buffer.writeln('Following,${candidate.followingCount}');
      buffer.writeln('Manifesto Likes,${analytics.manifestoLikes ?? 0}');
      buffer.writeln('Manifesto Comments,${analytics.manifestoComments ?? 0}');
      buffer.writeln('Poll Participation,${analytics.pollParticipation ?? 0}');
      buffer.writeln('');

      // Follower growth data
      if (analytics.followerGrowth != null && analytics.followerGrowth!.isNotEmpty) {
        buffer.writeln('FOLLOWER GROWTH TREND');
        buffer.writeln('Date,Followers,Growth,Profile Views');

        for (var data in analytics.followerGrowth!) {
          final date = data['date'] as DateTime;
          final followers = data['followers'] as int;
          final growth = data['growth'] as int;
          final views = data['profile_views'] as int? ?? 0;

          buffer.writeln('${date.toIso8601String().split('T')[0]},$followers,$growth,$views');
        }
        buffer.writeln('');
      }

      // Demographics data
      if (analytics.demographics != null) {
        buffer.writeln('DEMOGRAPHICS');
        buffer.writeln('Category,Metric,Count');

        final demo = analytics.demographics!;
        if (demo['age_groups'] != null) {
          (demo['age_groups'] as Map<String, dynamic>).forEach((age, count) {
            buffer.writeln('Age,$age,$count');
          });
        }

        if (demo['gender_distribution'] != null) {
          (demo['gender_distribution'] as Map<String, dynamic>).forEach((gender, count) {
            buffer.writeln('Gender,$gender,$count');
          });
        }

        if (demo['geographic_distribution'] != null) {
          (demo['geographic_distribution'] as Map<String, dynamic>).forEach((location, count) {
            buffer.writeln('Location,$location,$count');
          });
        }
        buffer.writeln('');
      }

      // Top performing content
      if (analytics.topPerformingContent != null) {
        buffer.writeln('TOP PERFORMING CONTENT');
        buffer.writeln('Content Type,Views,Likes,Shares,Engagement Rate');

        final content = analytics.topPerformingContent!;
        // This would need to be structured based on actual data format
        buffer.writeln('Sample Content,${content['views'] ?? 0},${content['likes'] ?? 0},${content['shares'] ?? 0},${content['engagement'] ?? 0}%');
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      AppLogger.common('❌ Failed to export analytics to CSV: $e');
      throw Exception('Failed to export analytics data: $e');
    }
  }

  /// Export analytics data to JSON format
  Future<String> exportAnalyticsToJSON(Candidate candidate) async {
    try {
      final analytics = candidate.extraInfo?.analytics;
      if (analytics == null) {
        throw Exception('No analytics data available');
      }

      final exportData = {
        'candidate': {
          'id': candidate.candidateId,
          'name': candidate.name,
          'party': candidate.party,
          'district': candidate.districtId,
          'state': candidate.stateId,
        },
        'export_timestamp': DateTime.now().toIso8601String(),
        'analytics': {
          'profile_views': analytics.profileViews ?? 0,
          'manifesto_views': analytics.manifestoViews ?? 0,
          'engagement_rate': analytics.engagementRate ?? 0.0,
          'followers_count': candidate.followersCount,
          'following_count': candidate.followingCount,
          'manifesto_likes': analytics.manifestoLikes ?? 0,
          'manifesto_comments': analytics.manifestoComments ?? 0,
          'poll_participation': analytics.pollParticipation ?? 0,
          'follower_growth': analytics.followerGrowth ?? [],
          'demographics': analytics.demographics ?? {},
          'top_performing_content': analytics.topPerformingContent ?? {},
        },
      };

      return JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      AppLogger.common('❌ Failed to export analytics to JSON: $e');
      throw Exception('Failed to export analytics data: $e');
    }
  }

  /// Share exported analytics data
  Future<void> shareAnalyticsData(Candidate candidate, {String format = 'csv'}) async {
    try {
      String content;
      String fileName;
      String mimeType;

      if (format == 'csv') {
        content = await exportAnalyticsToCSV(candidate);
        fileName = 'analytics_${candidate.candidateId}_${DateTime.now().millisecondsSinceEpoch}.csv';
        mimeType = 'text/csv';
      } else {
        content = await exportAnalyticsToJSON(candidate);
        fileName = 'analytics_${candidate.candidateId}_${DateTime.now().millisecondsSinceEpoch}.json';
        mimeType = 'application/json';
      }

      // Save to temporary file and share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Analytics Report - ${candidate.name}',
        text: 'Analytics data export for ${candidate.name}',
      );

      // Clean up temporary file
      await file.delete();

      AppLogger.common('📤 Shared analytics data for candidate: ${candidate.candidateId}');
    } catch (e) {
      AppLogger.common('❌ Failed to share analytics data: $e');
      throw Exception('Failed to share analytics data: $e');
    }
  }

  /// Generate analytics summary report
  Future<String> generateAnalyticsSummary(Candidate candidate) async {
    try {
      final analytics = candidate.extraInfo?.analytics;
      if (analytics == null) {
        return 'No analytics data available for ${candidate.name}';
      }

      final buffer = StringBuffer();
      buffer.writeln('📊 ANALYTICS SUMMARY REPORT');
      buffer.writeln('===========================');
      buffer.writeln('');
      buffer.writeln('Candidate: ${candidate.name}');
      buffer.writeln('Party: ${candidate.party}');
      buffer.writeln('Location: ${candidate.districtId}, ${candidate.stateId ?? 'India'}');
      buffer.writeln('Report Generated: ${DateTime.now().toString()}');
      buffer.writeln('');

      buffer.writeln('📈 KEY METRICS');
      buffer.writeln('--------------');
      buffer.writeln('Profile Views: ${analytics.profileViews ?? 0}');
      buffer.writeln('Manifesto Views: ${analytics.manifestoViews ?? 0}');
      buffer.writeln('Engagement Rate: ${(analytics.engagementRate ?? 0 * 100).toStringAsFixed(1)}%');
      buffer.writeln('Total Followers: ${candidate.followersCount}');
      buffer.writeln('Following: ${candidate.followingCount}');
      buffer.writeln('');

      buffer.writeln('📝 CONTENT ENGAGEMENT');
      buffer.writeln('---------------------');
      buffer.writeln('Manifesto Likes: ${analytics.manifestoLikes ?? 0}');
      buffer.writeln('Manifesto Comments: ${analytics.manifestoComments ?? 0}');
      buffer.writeln('Poll Participation: ${analytics.pollParticipation ?? 0}');
      buffer.writeln('');

      // Growth analysis
      if (analytics.followerGrowth != null && analytics.followerGrowth!.isNotEmpty) {
        final growth = analytics.followerGrowth!;
        final latest = growth.last;
        final previous = growth.length > 1 ? growth[growth.length - 2] : null;

        buffer.writeln('📈 GROWTH ANALYSIS');
        buffer.writeln('------------------');
        buffer.writeln('Current Followers: ${latest['followers']}');

        if (previous != null) {
          final growthAmount = (latest['followers'] as int) - (previous['followers'] as int);
          final growthPercent = previous['followers'] > 0
              ? (growthAmount / previous['followers'] * 100).toStringAsFixed(1)
              : '0.0';
          buffer.writeln('Recent Growth: ${growthAmount >= 0 ? '+' : ''}$growthAmount (${growthPercent}%)');
        }

        final totalGrowth = growth.isNotEmpty ? growth.last['followers'] - growth.first['followers'] : 0;
        buffer.writeln('30-Day Growth: ${totalGrowth >= 0 ? '+' : ''}$totalGrowth');
        buffer.writeln('');
      }

      buffer.writeln('🎯 INSIGHTS & RECOMMENDATIONS');
      buffer.writeln('------------------------------');

      // Generate insights based on data
      final profileViews = analytics.profileViews ?? 0;
      final manifestoViews = analytics.manifestoViews ?? 0;
      final followers = candidate.followersCount;

      if (profileViews < 100) {
        buffer.writeln('• Low profile visibility - Consider increasing social media presence');
      } else if (profileViews > 1000) {
        buffer.writeln('• Strong profile visibility - Continue current engagement strategies');
      }

      if (manifestoViews < profileViews * 0.5) {
        buffer.writeln('• Manifesto engagement could be improved - Promote manifesto content more actively');
      }

      if (followers < 50) {
        buffer.writeln('• Focus on building initial follower base through community engagement');
      } else if (followers > 500) {
        buffer.writeln('• Strong follower base - Leverage for campaign mobilization');
      }

      final engagementRate = analytics.engagementRate ?? 0;
      if (engagementRate < 0.05) {
        buffer.writeln('• Low engagement rate - Try interactive content like polls and Q&A sessions');
      } else if (engagementRate > 0.15) {
        buffer.writeln('• Excellent engagement - Maintain current interactive approach');
      }

      return buffer.toString();
    } catch (e) {
      AppLogger.common('❌ Failed to generate analytics summary: $e');
      return 'Error generating analytics summary: $e';
    }
  }
}