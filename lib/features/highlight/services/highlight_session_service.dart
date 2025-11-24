import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../deviceInfo/services/device_service.dart';
import '../../../services/screen_focus_service.dart';
import '../../../utils/app_logger.dart';

/// Represents an app session for highlight tracking
class HighlightSession {
  final String sessionId;
  final String deviceId;
  final DateTime startTime;
  DateTime lastActivity;
  final Set<String> viewedHighlights;

  HighlightSession({
    required this.sessionId,
    required this.deviceId,
    required this.startTime,
    DateTime? lastActivity,
    Set<String>? viewedHighlights,
  }) :
    lastActivity = lastActivity ?? startTime,
    viewedHighlights = viewedHighlights ?? {};

  /// Check if session is still active (within 30 minutes of last activity)
  bool get isActive {
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(lastActivity);
    return timeSinceLastActivity.inMinutes < 30; // 30 minute session timeout
  }

  /// Check if a highlight has been viewed in this session
  bool hasViewedHighlight(String highlightId) {
    return viewedHighlights.contains(highlightId);
  }

  /// Mark a highlight as viewed in this session
  void markHighlightViewed(String highlightId) {
    viewedHighlights.add(highlightId);
    lastActivity = DateTime.now();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'deviceId': deviceId,
      'startTime': startTime.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'viewedHighlights': viewedHighlights.toList(),
    };
  }

  /// Create from JSON
  factory HighlightSession.fromJson(Map<String, dynamic> json) {
    return HighlightSession(
      sessionId: json['sessionId'],
      deviceId: json['deviceId'],
      startTime: DateTime.parse(json['startTime']),
      lastActivity: DateTime.parse(json['lastActivity']),
      viewedHighlights: Set<String>.from(json['viewedHighlights'] ?? []),
    );
  }
}

/// Service to manage highlight viewing sessions
class HighlightSessionService {
  static final HighlightSessionService _instance = HighlightSessionService._internal();
  factory HighlightSessionService() => _instance;

  HighlightSessionService._internal();

  static const String _sessionKey = 'highlight_session';
  static const int _sessionTimeoutMinutes = 30;

  final DeviceService _deviceService = DeviceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScreenFocusService _focusService = ScreenFocusService();

  HighlightSession? _currentSession;

  /// Get the current active session, creating one if needed
  Future<HighlightSession> getCurrentSession() async {
    if (_currentSession != null && _currentSession!.isActive) {
      return _currentSession!;
    }

    // Check for device changes first
    await hasDeviceChanged();

    // Try to load from storage
    _currentSession = await _loadSessionFromStorage();

    // If no valid session exists, create a new one
    if (_currentSession == null || !_currentSession!.isActive) {
      _currentSession = await _createNewSession();
    }

    return _currentSession!;
  }

  /// Check if a highlight has been viewed in the current session
  Future<bool> hasViewedHighlightInSession(String highlightId) async {
    final session = await getCurrentSession();
    return session.hasViewedHighlight(highlightId);
  }

  /// Mark a highlight as viewed in the current session
  Future<void> markHighlightViewed(String highlightId) async {
    final session = await getCurrentSession();
    session.markHighlightViewed(highlightId);
    await _saveSessionToStorage(session);

    AppLogger.common('👁️ Highlight $highlightId marked as viewed in session ${session.sessionId}');
  }

  /// Track impression only if not already viewed in current session
  Future<bool> trackImpressionIfNotViewed({
    required String highlightId,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    // Only track impressions when home screen is focused
    if (!_focusService.isHomeScreenFocused) {
      // Silently skip tracking without logging when not on home screen
      return false;
    }

    final session = await getCurrentSession();
    final hasViewed = session.hasViewedHighlight(highlightId);

    if (hasViewed) {
     // AppLogger.common('⏭️ Highlight $highlightId already viewed in current session, skipping impression');
      return false; // Already viewed, no impression tracked
    }

    // Mark as viewed first
    session.markHighlightViewed(highlightId);
    await _saveSessionToStorage(session);

    AppLogger.common('👁️ Highlight $highlightId marked as viewed in session ${session.sessionId}');

    // Track the impression in Firestore
    try {
      await _trackImpressionInFirestore(
        highlightId: highlightId,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      AppLogger.common('✅ Tracked impression for highlight $highlightId (first view in session)');
      return true; // Impression tracked
    } catch (e) {
      AppLogger.commonError('❌ Failed to track impression for $highlightId', error: e);
      return false;
    }
  }

  /// End the current session (called when app is closed or becomes inactive)
  Future<void> endSession() async {
    if (_currentSession != null) {
      AppLogger.common('🏁 Ending highlight session ${_currentSession!.sessionId}');
      await _clearSessionFromStorage();
      _currentSession = null;
    }
  }

  /// Force refresh session (useful for testing or manual session reset)
  Future<void> refreshSession() async {
    await endSession();
    _currentSession = await _createNewSession();
  }

  /// Get session statistics for debugging
  Future<Map<String, dynamic>> getSessionStats() async {
    final session = await getCurrentSession();
    final now = DateTime.now();

    return {
      'sessionId': session.sessionId,
      'deviceId': session.deviceId,
      'startTime': session.startTime,
      'lastActivity': session.lastActivity,
      'duration': now.difference(session.startTime).inMinutes,
      'timeSinceLastActivity': now.difference(session.lastActivity).inMinutes,
      'isActive': session.isActive,
      'viewedHighlightsCount': session.viewedHighlights.length,
      'viewedHighlights': session.viewedHighlights.toList(),
    };
  }

  /// Clear all session data (useful for testing or manual reset)
  Future<void> clearAllSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      _currentSession = null;
      AppLogger.common('🗑️ All session data cleared');
    } catch (e) {
      AppLogger.commonError('❌ Failed to clear session data', error: e);
    }
  }

  /// Handle app data clearing (when user clears app data)
  Future<void> handleDataClearing() async {
    // This method can be called when app detects data clearing
    // For now, just clear the session - it will be recreated on next use
    await clearAllSessionData();
    AppLogger.common('📱 App data clearing detected - session reset');
  }

  /// Check if device has changed (handles device switching)
  Future<bool> hasDeviceChanged() async {
    try {
      final currentDeviceId = await _deviceService.getDeviceId();
      final session = await _loadSessionFromStorage();

      if (session == null) return false; // No session to compare

      final deviceChanged = session.deviceId != currentDeviceId;
      if (deviceChanged) {
        AppLogger.common('📱 Device changed from ${session.deviceId} to $currentDeviceId - resetting session');
        await clearAllSessionData();
      }

      return deviceChanged;
    } catch (e) {
      AppLogger.commonError('❌ Failed to check device change', error: e);
      return false;
    }
  }

  // Private methods

  Future<HighlightSession> _createNewSession() async {
    final deviceId = await _deviceService.getDeviceId();
    final sessionId = '${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final session = HighlightSession(
      sessionId: sessionId,
      deviceId: deviceId,
      startTime: now,
      lastActivity: now,
    );

    await _saveSessionToStorage(session);

    AppLogger.common('🆕 Created new highlight session: $sessionId for device: $deviceId');

    return session;
  }

  Future<HighlightSession?> _loadSessionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);

      if (sessionJson == null) return null;

      final session = HighlightSession.fromJson(jsonDecode(sessionJson));

      // Check if session is still valid
      if (session.isActive) {
        AppLogger.common('📂 Loaded existing session: ${session.sessionId}');
        return session;
      } else {
        // Session expired, clean it up
        await _clearSessionFromStorage();
        AppLogger.common('🗑️ Cleared expired session: ${session.sessionId}');
        return null;
      }
    } catch (e) {
      AppLogger.commonError('❌ Failed to load session from storage', error: e);
      return null;
    }
  }

  Future<void> _saveSessionToStorage(HighlightSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = jsonEncode(session.toJson());
      await prefs.setString(_sessionKey, sessionJson);
    } catch (e) {
      AppLogger.commonError('❌ Failed to save session to storage', error: e);
    }
  }

  Future<void> _clearSessionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e) {
      AppLogger.commonError('❌ Failed to clear session from storage', error: e);
    }
  }

  Future<void> _trackImpressionInFirestore({
    required String highlightId,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    // Use hierarchical path if location info is provided
    if (districtId != null && bodyId != null && wardId != null) {
      await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .doc(highlightId)
          .update({
            'views': FieldValue.increment(1),
            'lastShown': FieldValue.serverTimestamp(),
          });
    } 
  }
}
