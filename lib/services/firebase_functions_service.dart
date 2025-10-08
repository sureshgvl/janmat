import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:janmat/utils/app_logger.dart';
import 'dart:convert';
import '../utils/performance_monitor.dart';

/// Firebase Functions service for server-side operations
/// Note: This implementation uses HTTP calls. For production, consider using cloud_functions package
class FirebaseFunctionsService {
  static final FirebaseFunctionsService _instance =
      FirebaseFunctionsService._internal();
  factory FirebaseFunctionsService() => _instance;

  FirebaseFunctionsService._internal();

  final PerformanceMonitor _monitor = PerformanceMonitor();
  final String _baseUrl = kDebugMode
      ? 'http://localhost:5001/janmat/us-central1' // Emulator URL
      : 'https://us-central1-janmat.cloudfunctions.net'; // Production URL

  /// Bulk process candidates (server-side)
  Future<Map<String, dynamic>> bulkProcessCandidates({
    required String operation,
    required List<String> candidateIds,
    Map<String, dynamic>? parameters,
  }) async {
    _monitor.startTimer('bulk_process_candidates');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bulkProcessCandidates'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'operation': operation,
          'candidateIds': candidateIds,
          'parameters': parameters ?? {},
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('bulk_process_candidates');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('bulk_process_candidates');
      throw Exception('Failed to bulk process candidates: $e');
    }
  }

  /// Generate analytics report (server-side)
  Future<Map<String, dynamic>> generateAnalyticsReport({
    required String reportType,
    required String districtId,
    String? bodyId,
    String? wardId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _monitor.startTimer('generate_analytics_report');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generateAnalyticsReport'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reportType': reportType,
          'districtId': districtId,
          'bodyId': bodyId,
          'wardId': wardId,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('generate_analytics_report');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('generate_analytics_report');
      throw Exception('Failed to generate analytics report: $e');
    }
  }

  /// Process candidate search with advanced filtering (server-side)
  Future<Map<String, dynamic>> advancedCandidateSearch({
    required String query,
    required String districtId,
    String? bodyId,
    String? wardId,
    List<String>? partyFilter,
    List<String>? statusFilter,
    bool? approvedOnly,
    int limit = 50,
    String? startAfter,
  }) async {
    _monitor.startTimer('advanced_candidate_search');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/advancedCandidateSearch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'districtId': districtId,
          'bodyId': bodyId,
          'wardId': wardId,
          'partyFilter': partyFilter,
          'statusFilter': statusFilter,
          'approvedOnly': approvedOnly,
          'limit': limit,
          'startAfter': startAfter,
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('advanced_candidate_search');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('advanced_candidate_search');
      throw Exception('Failed to perform advanced search: $e');
    }
  }

  /// Calculate election statistics (server-side)
  Future<Map<String, dynamic>> calculateElectionStats({
    required String districtId,
    String? bodyId,
    String? wardId,
    bool includeTrends = true,
  }) async {
    _monitor.startTimer('calculate_election_stats');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculateElectionStats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'districtId': districtId,
          'bodyId': bodyId,
          'wardId': wardId,
          'includeTrends': includeTrends,
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('calculate_election_stats');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('calculate_election_stats');
      throw Exception('Failed to calculate election stats: $e');
    }
  }

  /// Process bulk notifications (server-side)
  Future<Map<String, dynamic>> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    _monitor.startTimer('send_bulk_notifications');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendBulkNotifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userIds': userIds,
          'title': title,
          'message': message,
          'imageUrl': imageUrl,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('send_bulk_notifications');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('send_bulk_notifications');
      throw Exception('Failed to send bulk notifications: $e');
    }
  }

  /// Generate candidate recommendations (server-side ML)
  Future<Map<String, dynamic>> generateCandidateRecommendations({
    required String userId,
    required String districtId,
    String? bodyId,
    String? wardId,
    int limit = 10,
  }) async {
    _monitor.startTimer('generate_recommendations');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generateCandidateRecommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'districtId': districtId,
          'bodyId': bodyId,
          'wardId': wardId,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('generate_recommendations');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('generate_recommendations');
      throw Exception('Failed to generate recommendations: $e');
    }
  }

  /// Validate candidate data (server-side)
  Future<Map<String, dynamic>> validateCandidateData({
    required Map<String, dynamic> candidateData,
    bool strictValidation = true,
  }) async {
    _monitor.startTimer('validate_candidate_data');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/validateCandidateData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'candidateData': candidateData,
          'strictValidation': strictValidation,
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('validate_candidate_data');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('validate_candidate_data');
      throw Exception('Failed to validate candidate data: $e');
    }
  }

  /// Process image optimization (server-side)
  Future<Map<String, dynamic>> optimizeCandidateImage({
    required String imageUrl,
    required String candidateId,
    List<String>? formats,
    List<int>? sizes,
  }) async {
    _monitor.startTimer('optimize_candidate_image');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/optimizeCandidateImage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageUrl': imageUrl,
          'candidateId': candidateId,
          'formats': formats ?? ['webp', 'jpg'],
          'sizes': sizes ?? [100, 300, 600],
        }),
      );

      if (response.statusCode == 200) {
        _monitor.stopTimer('optimize_candidate_image');
        _monitor.trackFirebaseRead('functions', 1);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _monitor.stopTimer('optimize_candidate_image');
      throw Exception('Failed to optimize candidate image: $e');
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return _monitor.getFirebaseSummary();
  }

  /// Test function connectivity
  Future<bool> testConnectivity() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/ping'));
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Firebase Functions connectivity test failed: $e');
      return false;
    }
  }
}

