import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static final PrefsService _instance = PrefsService._internal();
  static late SharedPreferences _prefs;

  factory PrefsService() => _instance;

  PrefsService._internal();

  /// MUST be called before using PrefsService
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // -------------------------
  // BASIC GETTERS & SETTERS
  // -------------------------

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) =>
      _prefs.getDouble(key) ?? defaultValue;

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  List<String> getStringList(String key) =>
      _prefs.getStringList(key) ?? [];

  // -------------------------
  // JSON SUPPORT
  // -------------------------

  Future<void> setJson(String key, dynamic value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  dynamic getJson(String key) {
    final data = _prefs.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  // -------------------------
  // DELETE / CLEAR
  // -------------------------

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }

  bool contains(String key) => _prefs.containsKey(key);
}