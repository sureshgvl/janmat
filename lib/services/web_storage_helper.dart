import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Simple web storage helper using SharedPreferences
/// Simulates database operations for web platform
class WebStorageHelper {
  static SharedPreferences? _prefs;
  static const String _manifestoInteractionsKey = 'web_manifesto_interactions';
  static const String _offlineDraftsKey = 'web_offline_drafts';
  static const String _cacheMetadataKey = 'web_cache_metadata';
  static const String _locationDataKey = 'web_location_data';

  /// Initialize web storage
  static Future<void> init() async {
    if (!kIsWeb) return;
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Store manifesto interaction data
  static Future<void> saveManifestoInteraction(String key, Map<String, dynamic> data) async {
    if (!kIsWeb) return;
    await init();
    final existing = await getManifestoInteractions();
    existing[key] = data;
    final jsonData = json.encode(existing);
    await _prefs!.setString(_manifestoInteractionsKey, jsonData);
  }

  /// Get all manifesto interaction data
  static Future<Map<String, Map<String, dynamic>>> getManifestoInteractions() async {
    if (!kIsWeb) return {};
    await init();
    final jsonData = _prefs!.getString(_manifestoInteractionsKey);
    if (jsonData == null) return {};
    return Map<String, Map<String, dynamic>>.from(json.decode(jsonData));
  }

  /// Store offline draft data
  static Future<void> saveOfflineDraft(String key, Map<String, dynamic> data) async {
    if (!kIsWeb) return;
    await init();
    final existing = await getOfflineDrafts();
    existing[key] = data;
    final jsonData = json.encode(existing);
    await _prefs!.setString(_offlineDraftsKey, jsonData);
  }

  /// Get all offline draft data
  static Future<Map<String, Map<String, dynamic>>> getOfflineDrafts() async {
    if (!kIsWeb) return {};
    await init();
    final jsonData = _prefs!.getString(_offlineDraftsKey);
    if (jsonData == null) return {};
    return Map<String, Map<String, dynamic>>.from(json.decode(jsonData));
  }

  /// Delete data by key from specified collection
  static Future<void> deleteWebData(String collection, String key) async {
    if (!kIsWeb) return;
    await init();

    if (collection == 'manifesto_interactions') {
      final existing = await getManifestoInteractions();
      existing.remove(key);
      final jsonData = json.encode(existing);
      await _prefs!.setString(_manifestoInteractionsKey, jsonData);
    } else if (collection == 'offline_drafts') {
      final existing = await getOfflineDrafts();
      existing.remove(key);
      final jsonData = json.encode(existing);
      await _prefs!.setString(_offlineDraftsKey, jsonData);
    }
  }

  /// Clear all web storage data
  static Future<void> clearAllWebData() async {
    if (!kIsWeb) return;
    await init();
    await _prefs!.setString(_manifestoInteractionsKey, '{}');
    await _prefs!.setString(_offlineDraftsKey, '{}');
    await _prefs!.setString(_cacheMetadataKey, '{}');
  }

  /// Store cache metadata
  static Future<void> saveCacheMetadata(String key, Map<String, dynamic> data) async {
    if (!kIsWeb) return;
    await init();
    final existing = await getCacheMetadata();
    existing[key] = data;
    final jsonData = json.encode(existing);
    await _prefs!.setString(_cacheMetadataKey, jsonData);
  }

  /// Get cache metadata
  static Future<Map<String, Map<String, dynamic>>> getCacheMetadata() async {
    if (!kIsWeb) return {};
    await init();
    final jsonData = _prefs!.getString(_cacheMetadataKey);
    if (jsonData == null) return {};
    return Map<String, Map<String, dynamic>>.from(json.decode(jsonData));
  }

  /// Store location data for web
  static Future<void> saveLocationData(String locationKey, Map<String, String> data) async {
    if (!kIsWeb) return;
    await init();
    final locationData = await getLocationData();
    locationData[locationKey] = data;
    final jsonData = json.encode(locationData);
    await _prefs!.setString(_locationDataKey, jsonData);
  }

  /// Get location data for web
  static Future<Map<String, Map<String, String>>> getLocationData() async {
    if (!kIsWeb) return {};
    await init();
    final jsonData = _prefs!.getString(_locationDataKey);
    if (jsonData == null) return {};
    return Map<String, Map<String, String>>.from(
      json.decode(jsonData).map((k, v) => MapEntry(k, Map<String, String>.from(v)))
    );
  }
}
