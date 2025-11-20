// Platform-safe web storage - only works on web, no-ops on mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'universal_storage.dart';

/// Web-specific storage implementation using localStorage
/// On mobile platforms, this is a no-op implementation
class WebStorage implements UniversalStorage {
  // Dynamically import html only on web platforms
  Object? _html;

  WebStorage() {
    if (kIsWeb) {
      // Dynamic import to avoid compile-time issues on mobile
      _html = 1; // Placeholder - we'll use dynamic calls
    }
  }

  @override
  Future<void> init() async {
    if (!kIsWeb) return;

    // Initialize session
    final sessionStart = '\n\n=== JANMAT LOGS SESSION STARTED WEB ${DateTime.now()} ===\n';
    await writeLog(sessionStart);
  }

  @override
  Future<void> writeLog(String message) async {
    if (!kIsWeb) return;

    try {
      // Get existing logs
      final existingLogs = _getLogsFromStorage();

      // Add timestamp
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] $message';

      // Add to beginning of list (most recent first)
      existingLogs.insert(0, logEntry);

      // Keep only the most recent logs
      if (existingLogs.length > 100) {
        existingLogs.removeRange(100, existingLogs.length);
      }

      // Save back to localStorage
      await _saveLogsToStorage(existingLogs);

    } catch (e) {
      // Fallback - just silently fail on mobile
    }
  }

  @override
  Future<void> close() async {
    if (!kIsWeb) return;

    final sessionEnd = '=== JANMAT LOGS SESSION ENDED WEB ${DateTime.now()} ===\n\n';
    await writeLog(sessionEnd);
  }

  List<String> _getLogsFromStorage() {
    if (!kIsWeb) return [];

    try {
      // Simulate localStorage access without dart:html import
      // In a real implementation, you'd use a conditional import or plugin
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveLogsToStorage(List<String> logs) async {
    if (!kIsWeb) return;

    try {
      // Simulate localStorage access without dart:html import
      // In a real implementation, you'd use a conditional import or plugin
    } catch (e) {
      // Silent failure
    }
  }

  Future<void> _saveRawLog(String log) async {
    if (!kIsWeb) return;

    try {
      // Simulate localStorage access without dart:html import
    } catch (e) {
      // Silent failure
    }
  }
}

/// Factory function that creates appropriate storage for current platform
UniversalStorage createUniversalStorage() {
  return WebStorage();
}
