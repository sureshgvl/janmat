// Conditional import for web platform
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'universal_storage.dart';
import 'dart:html' as html;

/// Web-specific storage implementation using localStorage
class WebStorage implements UniversalStorage {
  static const String _janmatLogsKey = 'janmat_logs_session';
  static const int _maxLogsToKeep = 100; // Keep only last 100 logs to prevent localStorage bloat

  @override
  Future<void> init() async {
    // Initialize session
    final sessionStart = '\n\n=== JANMAT LOGS SESSION STARTED WEB ${DateTime.now()} ===\n';
    await writeLog(sessionStart);
  }

  @override
  Future<void> writeLog(String message) async {
    try {
      // Get existing logs
      final existingLogs = _getLogsFromStorage();

      // Add timestamp
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] $message';

      // Add to beginning of list (most recent first)
      existingLogs.insert(0, logEntry);

      // Keep only the most recent logs
      if (existingLogs.length > _maxLogsToKeep) {
        existingLogs.removeRange(_maxLogsToKeep, existingLogs.length);
      }

      // Save back to localStorage
      await _saveLogsToStorage(existingLogs);

    } catch (e) {
      // Fallback to localStorage directly if JSON fails
      try {
        final encoder = JsonEncoder();
        await _saveRawLog(encoder.convert({'timestamp': DateTime.now().toIso8601String(), 'message': message}));
      } catch (_) {
        // Last resort - just save the message directly
        await _saveRawLog(message);
      }
    }
  }

  @override
  Future<void> close() async {
    final sessionEnd = '=== JANMAT LOGS SESSION ENDED WEB ${DateTime.now()} ===\n\n';
    await writeLog(sessionEnd);
  }

  List<String> _getLogsFromStorage() {
    try {
      final stored = _getLocalStorageItem(_janmatLogsKey);
      if (stored == null || stored.isEmpty) return [];

      final decoded = json.decode(stored) as List;
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveLogsToStorage(List<String> logs) async {
    try {
      await _setLocalStorageItem(_janmatLogsKey, json.encode(logs));
    } catch (e) {
      // If JSON serialization fails, try compressing logs
      final compressedLogs = logs.take(10).toList(); // Keep only 10 most recent
      await _setLocalStorageItem(_janmatLogsKey, json.encode(compressedLogs));
    }
  }

  Future<void> _saveRawLog(String log) async {
    try {
      await _setLocalStorageItem('${_janmatLogsKey}_raw', log);
    } catch (e) {
      // Silent failure - localStorage might be full
    }
  }

  String? _getLocalStorageItem(String key) {
    if (!kIsWeb) return null;

    try {
      return html.window.localStorage[key];
    } catch (e) {
      return null;
    }
  }

  Future<void> _setLocalStorageItem(String key, String value) async {
    if (!kIsWeb) return;

    try {
      html.window.localStorage[key] = value;
    } catch (e) {
      // localStorage quota exceeded or other issues - try to clear old logs
      try {
        // Clear old logs to make space
        html.window.localStorage.remove(_janmatLogsKey);
        html.window.localStorage[key] = value;
      } catch (_) {
        // If that fails too, silently ignore
      }
    }
  }
}

UniversalStorage createUniversalStorage() {
  return WebStorage();
}
