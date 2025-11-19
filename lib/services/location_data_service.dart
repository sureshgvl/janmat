import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import '../models/state_model.dart';
import '../models/district_model.dart';
import '../models/body_model.dart';
import '../models/ward_model.dart';
import '../utils/app_logger.dart';
import '../utils/maharashtra_utils.dart';
import '../features/language/controller/language_controller.dart';

/// Service for caching and retrieving location data (states, districts, bodies, wards)
/// Uses SQLite for local caching with Firebase as source of truth
class LocationDataService {
  static final LocationDataService _instance = LocationDataService._internal();
  static LocationDataService get instance => _instance;

  LocationDataService._internal();

  Database? _database;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize the database (SQLite on mobile, SharedPreferences on web)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // Use SharedPreferences for web (limited but sufficient for current usage)
        _prefs = await SharedPreferences.getInstance();
        AppLogger.common('✅ LocationDataService initialized for web (using SharedPreferences cache)');
      } else {
        // Use SQLite for mobile platforms
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'location_data.db');

        _database = await openDatabase(
          path,
          version: 1,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        AppLogger.common('✅ LocationDataService initialized for mobile (using SQLite)');
      }

      _isInitialized = true;
    } catch (e) {
      AppLogger.commonError('❌ Failed to initialize LocationDataService: $e');
      if (!kIsWeb) {
        rethrow;
      } else {
        _isInitialized = true; // Continue without cache on web errors
        AppLogger.common('⚠️ Continuing without cache on web due to initialization error');
      }
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // States table
    await db.execute('''
      CREATE TABLE states (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        marathiName TEXT,
        code TEXT,
        isActive INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        lastSyncedAt TEXT
      )
    ''');

    // Districts table
    await db.execute('''
      CREATE TABLE districts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        stateId TEXT NOT NULL,
        municipalCorporation TEXT,
        municipalCouncil TEXT,
        nagarPanchayat TEXT,
        zillaParishad TEXT,
        panchayatSamiti TEXT,
        municipalCorporationPdfUrl TEXT,
        municipalCouncilPdfUrl TEXT,
        nagarPanchayatPdfUrl TEXT,
        zillaParishadPdfUrl TEXT,
        panchayatSamitiPdfUrl TEXT,
        createdAt TEXT,
        isActive INTEGER,
        lastSyncedAt TEXT,
        FOREIGN KEY (stateId) REFERENCES states (id)
      )
    ''');

    // Bodies table
    await db.execute('''
      CREATE TABLE bodies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        districtId TEXT NOT NULL,
        stateId TEXT NOT NULL,
        ward_count INTEGER,
        area_to_ward TEXT,
        source TEXT,
        special TEXT,
        createdAt TEXT,
        lastSyncedAt TEXT,
        FOREIGN KEY (districtId) REFERENCES districts (id),
        FOREIGN KEY (stateId) REFERENCES states (id)
      )
    ''');

    // Wards table
    await db.execute('''
      CREATE TABLE wards (
        id TEXT PRIMARY KEY,
        districtId TEXT NOT NULL,
        bodyId TEXT NOT NULL,
        name TEXT NOT NULL,
        number INTEGER,
        stateId TEXT NOT NULL,
        population_total INTEGER,
        sc_population INTEGER,
        st_population INTEGER,
        areas TEXT,
        assembly_constituency TEXT,
        parliamentary_constituency TEXT,
        createdAt TEXT,
        lastSyncedAt TEXT,
        FOREIGN KEY (districtId) REFERENCES districts (id),
        FOREIGN KEY (bodyId) REFERENCES bodies (id),
        FOREIGN KEY (stateId) REFERENCES states (id)
      )
    ''');

    AppLogger.common('✅ Location database tables created');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema changes here
  }

  /// Ensure database is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
  }

  /// Get state by ID - check local cache first, then Firebase
  Future<State?> getState(String stateId) async {
    await _ensureInitialized();

    try {
      // Check local cache first
      final cachedState = await _getStateFromCache(stateId);
      if (cachedState != null) {
        return cachedState;
      }

      // Fetch from Firebase
      final stateDoc = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .get();

      if (stateDoc.exists) {
        final state = State.fromJson(stateDoc.data()!);
        await _cacheState(state);
        return state;
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error getting state $stateId: $e');
      return null;
    }
  }

  /// Get district by ID - check local cache first, then Firebase
  Future<District?> getDistrict(String districtId, {String? stateId}) async {
    await _ensureInitialized();

    try {
      // Check local cache first
      final cachedDistrict = await _getDistrictFromCache(districtId, stateId: stateId);
      if (cachedDistrict != null) {
        return cachedDistrict;
      }

      // Fetch from Firebase using hierarchical path
      if (stateId != null) {
        final districtDoc = await FirebaseFirestore.instance
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .get();

        if (districtDoc.exists) {
          final district = District.fromJson(districtDoc.data()!);
          await _cacheDistrict(district);
          return district;
        }
      } else {
        // Fallback: search in Maharashtra (legacy behavior)
        final districtDoc = await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc(districtId)
            .get();

        if (districtDoc.exists) {
          final district = District.fromJson(districtDoc.data()!);
          await _cacheDistrict(district);
          return district;
        }
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error getting district $districtId: $e');
      return null;
    }
  }

  /// Get body by ID - check local cache first, then Firebase
  Future<Body?> getBody(String bodyId, {String? stateId, String? districtId}) async {
    await _ensureInitialized();

    try {
      // Check local cache first
      final cachedBody = await _getBodyFromCache(bodyId, stateId: stateId, districtId: districtId);
      if (cachedBody != null) {
        return cachedBody;
      }

      // Fetch from Firebase using hierarchical path
      Map<String, dynamic>? bodyDoc;
      if (stateId != null && districtId != null) {
        // Use provided hierarchical path
        bodyDoc = await _findBodyInFirebase(stateId, districtId, bodyId);
      } else {
        // Fallback: search across all districts (less efficient)
        bodyDoc = await _findBodyInFirebaseLegacy(bodyId);
      }

      if (bodyDoc != null) {
        final body = Body.fromJson(bodyDoc);
        await _cacheBody(body);
        return body;
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error getting body $bodyId: $e');
      return null;
    }
  }

  /// Get ward by ID - check local cache first, then Firebase
  Future<Ward?> getWard(String wardId, {String? stateId, String? districtId, String? bodyId}) async {
    await _ensureInitialized();

    try {
      // Check local cache first
      final cachedWard = await _getWardFromCache(wardId, stateId: stateId, districtId: districtId, bodyId: bodyId);
      if (cachedWard != null) {
        return cachedWard;
      }

      // Fetch from Firebase using hierarchical path
      Map<String, dynamic>? wardDoc;
      if (stateId != null && districtId != null && bodyId != null) {
        // Use provided hierarchical path
        wardDoc = await _findWardInFirebase(stateId, districtId, bodyId, wardId);
      } else {
        // Fallback: search across all districts and bodies (less efficient)
        wardDoc = await _findWardInFirebaseLegacy(wardId);
      }

      if (wardDoc != null) {
        final ward = Ward.fromJson(wardDoc);
        await _cacheWard(ward);
        return ward;
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error getting ward $wardId: $e');
      return null;
    }
  }

  /// Get current language code from LanguageController
  String _getCurrentLanguageCode() {
    try {
      final languageController = Get.find<LanguageController>();
      return languageController.currentLanguageCode;
    } catch (e) {
      // Fallback to English if controller not found
      return 'en';
    }
  }

  /// Get location names by IDs - optimized method for UI display with language support
  Future<Map<String, String>> getLocationNames({
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    await _ensureInitialized();

    final result = <String, String>{};
    final currentLanguage = _getCurrentLanguageCode();

    try {
      // Get state name with language support
      if (stateId != null) {
        final state = await getState(stateId);
        if (state != null) {
          // Use Marathi name if language is Marathi and available
          result['stateName'] = (currentLanguage == 'mr' && state.marathiName != null)
              ? state.marathiName!
              : state.name;
        } else {
          result['stateName'] = stateId;
        }
      }

      // Get district name with language support
      if (districtId != null) {
        // Use MaharashtraUtils for district names (has multilingual support)
        result['districtName'] = MaharashtraUtils.getDistrictDisplayNameWithLocale(
          districtId,
          currentLanguage,
        );
      }

      // Get body name (bodies don't have language variants in current model)
      if (bodyId != null) {
        final body = await getBody(bodyId, stateId: stateId, districtId: districtId);
        result['bodyName'] = body?.name ?? bodyId;
      }

      // Get ward name (wards don't have language variants in current model)
      if (wardId != null) {
        final ward = await getWard(wardId, stateId: stateId, districtId: districtId, bodyId: bodyId);
        result['wardName'] = ward?.name ?? wardId;
      }

      return result;
    } catch (e) {
      AppLogger.commonError('❌ Error getting location names: $e');
      // Return fallback values
      return {
        if (stateId != null) 'stateName': stateId,
        if (districtId != null) 'districtName': districtId,
        if (bodyId != null) 'bodyName': bodyId,
        if (wardId != null) 'wardName': wardId,
      };
    }
  }

  /// Batch get location names for multiple locations (efficient for lists)
  Future<Map<String, Map<String, String>>> batchGetLocationNames(
    List<Map<String, String>> locationRequests,
  ) async {
    await _ensureInitialized();

    final result = <String, Map<String, String>>{};
    final currentLanguage = _getCurrentLanguageCode();

    try {
      // Collect unique IDs to minimize database calls
      final uniqueStateIds = <String>{};
      final uniqueDistrictIds = <String>{};
      final uniqueBodyIds = <String>{};
      final uniqueWardIds = <String>{};

      for (var request in locationRequests) {
        if (request['stateId'] != null) uniqueStateIds.add(request['stateId']!);
        if (request['districtId'] != null) uniqueDistrictIds.add(request['districtId']!);
        if (request['bodyId'] != null) uniqueBodyIds.add(request['bodyId']!);
        if (request['wardId'] != null) uniqueWardIds.add(request['wardId']!);
      }

      // Batch fetch unique entities
      final states = await Future.wait(uniqueStateIds.map(getState));
      final bodies = await Future.wait(uniqueBodyIds.map((bodyId) {
        // For batch operations, we need to find the corresponding stateId and districtId
        // This is a limitation - batch operations work best when hierarchical context is provided
        return getBody(bodyId); // Will use legacy search if no context provided
      }));
      final wards = await Future.wait(uniqueWardIds.map((wardId) {
        // Same limitation for wards
        return getWard(wardId); // Will use legacy search if no context provided
      }));

      // Create lookup maps
      final stateMap = Map.fromEntries(states.whereType<State>().map((s) => MapEntry(s.id, s)));
      final bodyMap = Map.fromEntries(bodies.whereType<Body>().map((b) => MapEntry(b.id, b)));
      final wardMap = Map.fromEntries(wards.whereType<Ward>().map((w) => MapEntry(w.id, w)));

      // Build results for each request with language support
      for (var i = 0; i < locationRequests.length; i++) {
        final request = locationRequests[i];
        final names = <String, String>{};

        // State name with language support
        if (request['stateId'] != null) {
          final state = stateMap[request['stateId']];
          if (state != null) {
            names['stateName'] = (currentLanguage == 'mr' && state.marathiName != null)
                ? state.marathiName!
                : state.name;
          } else {
            names['stateName'] = request['stateId']!;
          }
        }

        // District name with language support
        if (request['districtId'] != null) {
          names['districtName'] = MaharashtraUtils.getDistrictDisplayNameWithLocale(
            request['districtId']!,
            currentLanguage,
          );
        }

        // Body name (no language variants)
        if (request['bodyId'] != null) {
          names['bodyName'] = bodyMap[request['bodyId']]?.name ?? request['bodyId']!;
        }

        // Ward name (no language variants)
        if (request['wardId'] != null) {
          names['wardName'] = wardMap[request['wardId']]?.name ?? request['wardId']!;
        }

        result['request_$i'] = names;
      }

      return result;
    } catch (e) {
      AppLogger.commonError('❌ Error in batch location names: $e');
      // Return fallback results
      final fallback = <String, Map<String, String>>{};
      for (var i = 0; i < locationRequests.length; i++) {
        final request = locationRequests[i];
        fallback['request_$i'] = {
          if (request['stateId'] != null) 'stateName': request['stateId']!,
          if (request['districtId'] != null) 'districtName': request['districtId']!,
          if (request['bodyId'] != null) 'bodyName': request['bodyId']!,
          if (request['wardId'] != null) 'wardName': request['wardId']!,
        };
      }
      return fallback;
    }
  }

  // ===== PRIVATE CACHE METHODS =====

  Future<State?> _getStateFromCache(String stateId) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final jsonStr = _prefs!.getString('state_$stateId');
        if (jsonStr != null) {
          final data = json.decode(jsonStr);
          return State.fromJson(data);
        }
      }
    } else {
      final maps = await _database!.query(
        'states',
        where: 'id = ?',
        whereArgs: [stateId],
      );

      if (maps.isNotEmpty) {
        // Convert integer back to boolean for State model
        final data = Map<String, dynamic>.from(maps.first);
        if (data['isActive'] != null) {
          data['isActive'] = (data['isActive'] as int) == 1;
        }
        return State.fromJson(data);
      }
    }
    return null;
  }

  Future<District?> _getDistrictFromCache(String districtId, {String? stateId}) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final jsonStr = _prefs!.getString('district_$districtId${stateId != null ? '_${stateId}' : ''}');
        if (jsonStr != null) {
          final data = json.decode(jsonStr);
          return District.fromJson(data);
        }
      }
    } else {
      final maps = await _database!.query(
        'districts',
        where: stateId != null ? 'id = ? AND stateId = ?' : 'id = ?',
        whereArgs: stateId != null ? [districtId, stateId] : [districtId],
      );

      if (maps.isNotEmpty) {
        return District.fromJson(maps.first);
      }
    }
    return null;
  }

  Future<Body?> _getBodyFromCache(String bodyId, {String? stateId, String? districtId}) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final jsonStr = _prefs!.getString('body_$bodyId${districtId != null ? '_${districtId}' : ''}');
        if (jsonStr != null) {
          final data = json.decode(jsonStr);
          return Body.fromJson(data);
        }
      }
    } else {
      final maps = await _database!.query(
        'bodies',
        where: (stateId != null && districtId != null) ? 'id = ? AND stateId = ? AND districtId = ?' : 'id = ?',
        whereArgs: (stateId != null && districtId != null) ? [bodyId, stateId, districtId] : [bodyId],
      );

      if (maps.isNotEmpty) {
        return Body.fromJson(maps.first);
      }
    }
    return null;
  }

  Future<Ward?> _getWardFromCache(String wardId, {String? stateId, String? districtId, String? bodyId}) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final jsonStr = _prefs!.getString('ward_$wardId${bodyId != null ? '_${bodyId}' : ''}');
        if (jsonStr != null) {
          final data = json.decode(jsonStr);
          return Ward.fromJson(data);
        }
      }
    } else {
      final maps = await _database!.query(
        'wards',
        where: (stateId != null && districtId != null && bodyId != null) ? 'id = ? AND stateId = ? AND districtId = ? AND bodyId = ?' : 'id = ?',
        whereArgs: (stateId != null && districtId != null && bodyId != null) ? [wardId, stateId, districtId, bodyId] : [wardId],
      );

      if (maps.isNotEmpty) {
        // Convert comma-separated string back to List<String> for Ward model
        final data = Map<String, dynamic>.from(maps.first);
        if (data['areas'] != null && data['areas'] is String) {
          data['areas'] = (data['areas'] as String).split(',').where((s) => s.isNotEmpty).toList();
        }
        return Ward.fromJson(data);
      }
    }
    return null;
  }

  Future<void> _cacheState(State state) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final stateData = state.toJson();
        final jsonStr = json.encode(stateData);
        await _prefs!.setString('state_${state.id}', jsonStr);
      }
    } else {
      // Convert boolean to integer for SQLite compatibility
      final stateData = state.toJson();
      if (stateData['isActive'] != null) {
        stateData['isActive'] = (stateData['isActive'] as bool) ? 1 : 0;
      }

      await _database!.insert(
        'states',
        {
          ...stateData,
          'lastSyncedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _cacheDistrict(District district) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final districtData = district.toJson();
        final jsonStr = json.encode(districtData);
        await _prefs!.setString('district_${district.id}${district.stateId != null ? '_${district.stateId}' : ''}', jsonStr);
      }
    } else {
      await _database!.insert(
        'districts',
        {
          ...district.toJson(),
          'lastSyncedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _cacheBody(Body body) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final bodyData = body.toJson();
        final jsonStr = json.encode(bodyData);
        await _prefs!.setString('body_${body.id}_${body.districtId}', jsonStr);
      }
    } else {
      await _database!.insert(
        'bodies',
        {
          ...body.toJson(),
          'lastSyncedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _cacheWard(Ward ward) async {
    if (kIsWeb) {
      if (_prefs != null) {
        final wardData = ward.toJson();
        final jsonStr = json.encode(wardData);
        await _prefs!.setString('ward_${ward.id}_${ward.bodyId}', jsonStr);
      }
    } else {
      // Convert List<String> to JSON string for SQLite compatibility
      final wardData = ward.toJson();
      if (wardData['areas'] != null) {
        // Convert List<String> to JSON string
        wardData['areas'] = (wardData['areas'] as List<String>).join(',');
      }

      await _database!.insert(
        'wards',
        {
          ...wardData,
          'lastSyncedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ===== PRIVATE FIREBASE SEARCH METHODS =====

  /// Find body using hierarchical path: states/{stateId}/districts/{districtId}/bodies/{bodyId}
  Future<Map<String, dynamic>?> _findBodyInFirebase(String stateId, String districtId, String bodyId) async {
    try {
      final bodyDoc = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .get();

      if (bodyDoc.exists) {
        return bodyDoc.data();
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error finding body $bodyId in Firebase path: states/$stateId/districts/$districtId/bodies/$bodyId', error: e);
      return null;
    }
  }

  /// Find ward using hierarchical path: states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId}
  Future<Map<String, dynamic>?> _findWardInFirebase(String stateId, String districtId, String bodyId, String wardId) async {
    try {
      final wardDoc = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .get();

      if (wardDoc.exists) {
        return wardDoc.data();
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error finding ward $wardId in Firebase path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId', error: e);
      return null;
    }
  }

  /// Legacy method: Search across all districts for the body (inefficient)
  Future<Map<String, dynamic>?> _findBodyInFirebaseLegacy(String bodyId) async {
    try {
      // Search across all districts for the body
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .get();

      for (var districtDoc in districtsSnapshot.docs) {
        final bodyDoc = await districtDoc.reference
            .collection('bodies')
            .doc(bodyId)
            .get();

        if (bodyDoc.exists) {
          return bodyDoc.data();
        }
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error finding body in Firebase (legacy search): $e');
      return null;
    }
  }

  /// Legacy method: Search across all districts and bodies for the ward (inefficient)
  Future<Map<String, dynamic>?> _findWardInFirebaseLegacy(String wardId) async {
    try {
      // Search across all districts and bodies for the ward
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .get();

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference
            .collection('bodies')
            .get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardDoc = await bodyDoc.reference
              .collection('wards')
              .doc(wardId)
              .get();

          if (wardDoc.exists) {
            return wardDoc.data();
          }
        }
      }

      return null;
    } catch (e) {
      AppLogger.commonError('❌ Error finding ward in Firebase (legacy search): $e');
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensureInitialized();

    if (kIsWeb) {
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) =>
          key.startsWith('state_') || key.startsWith('district_') ||
          key.startsWith('body_') || key.startsWith('ward_')
        ).toList();
        for (var key in keys) {
          await _prefs!.remove(key);
        }
      }
    } else {
      await _database!.delete('wards');
      await _database!.delete('bodies');
      await _database!.delete('districts');
      await _database!.delete('states');
    }

    AppLogger.common('🗑️ Location data cache cleared');
  }

  /// Close database connection
  Future<void> dispose() async {
    if (!kIsWeb && _database != null) {
      await _database!.close();
      _database = null;
    }
    _prefs = null;
    _isInitialized = false;
  }
}
