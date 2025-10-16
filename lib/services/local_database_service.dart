import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../utils/app_logger.dart';
import '../models/district_model.dart';
import '../models/body_model.dart';
import '../models/ward_model.dart';
import '../models/district_spotlight_model.dart';
import '../features/candidate/models/candidate_model.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _dbName = 'janmat_local.db';
  static const int _dbVersion = 7; // Increment to add version column to district spotlights table

  // Table names
  static const String districtsTable = 'districts';
  static const String bodiesTable = 'bodies';
  static const String wardsTable = 'wards';
  static const String candidatesTable = 'candidates';
  static const String cacheMetadataTable = 'cache_metadata';
  static const String commentsTable = 'comments';
  static const String likesTable = 'likes';
  static const String pollsTable = 'polls';
  static const String districtSpotlightsTable = 'district_spotlights';

  // Cache metadata columns
  static const String columnCacheKey = 'cache_key';
  static const String columnLastUpdated = 'last_updated';
  static const String columnDataVersion = 'data_version';

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createDistrictsTable(db);
    await _createBodiesTable(db);
    await _createWardsTable(db);
    await _createCandidatesTable(db);
    await _createCacheMetadataTable(db);
    await _createCommentsTable(db);
    await _createLikesTable(db);
    await _createPollsTable(db);
    await _createDistrictSpotlightsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades
    if (oldVersion < 4 && newVersion >= 4) {
      // Upgrade to version 4: Add candidates table
      AppLogger.common('🔄 [SQLite] Upgrading database from v$oldVersion to v$newVersion - adding candidates table');

      // Check if candidates table exists, create if not
      final candidatesExists = await _tableExists(db, candidatesTable);
      if (!candidatesExists) {
        await _createCandidatesTable(db);
        AppLogger.common('✅ [SQLite] Created candidates table');
      } else {
        AppLogger.common('ℹ️ [SQLite] Candidates table already exists, skipping creation');
      }

      // Check if cache_metadata table exists, create if not
      final metadataExists = await _tableExists(db, cacheMetadataTable);
      if (!metadataExists) {
        await _createCacheMetadataTable(db);
        AppLogger.common('✅ [SQLite] Created cache_metadata table');
      } else {
        AppLogger.common('ℹ️ [SQLite] Cache_metadata table already exists, skipping creation');
      }

      AppLogger.common('✅ [SQLite] Database upgrade to v4 completed');
    }

    if (oldVersion < 5 && newVersion >= 5) {
      // Upgrade to version 5: Add manifesto interaction tables
      AppLogger.common('🔄 [SQLite] Upgrading database from v$oldVersion to v$newVersion - adding manifesto interaction tables');

      // Check if comments table exists, create if not
      final commentsExists = await _tableExists(db, commentsTable);
      if (!commentsExists) {
        await _createCommentsTable(db);
        AppLogger.common('✅ [SQLite] Created comments table');
      } else {
        AppLogger.common('ℹ️ [SQLite] Comments table already exists, skipping creation');
      }

      // Check if likes table exists, create if not
      final likesExists = await _tableExists(db, likesTable);
      if (!likesExists) {
        await _createLikesTable(db);
        AppLogger.common('✅ [SQLite] Created likes table');
      } else {
        AppLogger.common('ℹ️ [SQLite] Likes table already exists, skipping creation');
      }

      // Check if polls table exists, create if not
      final pollsExists = await _tableExists(db, pollsTable);
      if (!pollsExists) {
        await _createPollsTable(db);
        AppLogger.common('✅ [SQLite] Created polls table');
      } else {
        AppLogger.common('ℹ️ [SQLite] Polls table already exists, skipping creation');
      }

      AppLogger.common('✅ [SQLite] Database upgrade to v5 completed');
    }

    if (oldVersion < 6 && newVersion >= 6) {
      // Upgrade to version 6: Add district spotlights table
      AppLogger.common('🔄 [SQLite] Upgrading database from v$oldVersion to v$newVersion - adding district spotlights table');

      // Check if district spotlights table exists, create if not
      final districtSpotlightsExists = await _tableExists(db, districtSpotlightsTable);
      if (!districtSpotlightsExists) {
        await _createDistrictSpotlightsTable(db);
        AppLogger.common('✅ [SQLite] Created district spotlights table');
      } else {
        AppLogger.common('ℹ️ [SQLite] District spotlights table already exists, skipping creation');
      }

      AppLogger.common('✅ [SQLite] Database upgrade to v6 completed');
    }

    if (oldVersion < 7 && newVersion >= 7) {
      // Upgrade to version 7: Add version column to district spotlights table
      AppLogger.common('🔄 [SQLite] Upgrading database from v$oldVersion to v$newVersion - adding version column to district spotlights table');

      try {
        // Check if version column exists, add if not
        final result = await db.rawQuery("PRAGMA table_info($districtSpotlightsTable)");
        final hasVersionColumn = result.any((column) => column['name'] == 'version');

        if (!hasVersionColumn) {
          await db.execute('ALTER TABLE $districtSpotlightsTable ADD COLUMN version TEXT');
          AppLogger.common('✅ [SQLite] Added version column to district spotlights table');
        } else {
          AppLogger.common('ℹ️ [SQLite] Version column already exists in district spotlights table');
        }

        AppLogger.common('✅ [SQLite] Database upgrade to v7 completed');
      } catch (e) {
        AppLogger.common('❌ [SQLite] Error upgrading to v7: $e');
        // Continue with upgrade even if this fails
      }
    }
  }

  // Helper method to check if a table exists
  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Create districts table
  Future<void> _createDistrictsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $districtsTable (
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
        UNIQUE(id)
      )
    ''');
  }

  // Create bodies table
  Future<void> _createBodiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $bodiesTable (
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
        UNIQUE(id),
        FOREIGN KEY (districtId) REFERENCES $districtsTable (id)
      )
    ''');
  }

  // Create wards table
  Future<void> _createWardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $wardsTable (
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
        UNIQUE(id),
        FOREIGN KEY (districtId) REFERENCES $districtsTable (id),
        FOREIGN KEY (bodyId) REFERENCES $bodiesTable (id)
      )
    ''');
  }

  // Create candidates table
  Future<void> _createCandidatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $candidatesTable (
        id TEXT PRIMARY KEY,
        wardId TEXT NOT NULL,
        districtId TEXT NOT NULL,
        bodyId TEXT NOT NULL,
        stateId TEXT NOT NULL,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        party TEXT NOT NULL,
        photo TEXT,
        followersCount INTEGER DEFAULT 0,
        data TEXT NOT NULL,
        lastUpdated TEXT NOT NULL,
        UNIQUE(id),
        FOREIGN KEY (wardId) REFERENCES $wardsTable (id)
      )
    ''');
  }

  // Create cache metadata table
  Future<void> _createCacheMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE $cacheMetadataTable (
        $columnCacheKey TEXT PRIMARY KEY,
        $columnLastUpdated TEXT NOT NULL,
        $columnDataVersion INTEGER DEFAULT 1
      )
    ''');
  }

  // Create comments table
  Future<void> _createCommentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $commentsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        postId TEXT NOT NULL,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        parentId TEXT,
        synced INTEGER DEFAULT 0,
        syncAction TEXT,
        UNIQUE(id)
      )
    ''');
  }

  // Create likes table
  Future<void> _createLikesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $likesTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        postId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        syncAction TEXT,
        UNIQUE(id)
      )
    ''');
  }

  // Create polls table
  Future<void> _createPollsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $pollsTable (
        manifestoId TEXT NOT NULL,
        userId TEXT NOT NULL,
        option TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        syncAction TEXT,
        PRIMARY KEY (manifestoId, userId)
      )
    ''');
  }

  // Create district spotlights table
  Future<void> _createDistrictSpotlightsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $districtSpotlightsTable (
        id TEXT PRIMARY KEY,
        stateId TEXT NOT NULL,
        districtId TEXT NOT NULL,
        partyId TEXT,
        fullImage TEXT NOT NULL,
        bannerImage TEXT,
        isActive INTEGER NOT NULL,
        createdAt TEXT,
        updatedAt TEXT,
        lastFetched TEXT NOT NULL,
        version TEXT,
        UNIQUE(stateId, districtId)
      )
    ''');
  }

  // District operations
  Future<void> insertDistricts(List<District> districts) async {
    AppLogger.common('📍 [SQLite] Starting to insert ${districts.length} districts into local database');
    final db = await database;
    final batch = db.batch();
    for (var district in districts) {
      batch.insert(
        districtsTable,
        district.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
    await updateCacheMetadata('districts');
    AppLogger.common('✅ [SQLite] Successfully inserted ${districts.length} districts into local database');
    if (districts.isNotEmpty) {
      AppLogger.common('📍 [SQLite] Sample districts cached: ${districts.take(2).map((d) => '${d.id}:${d.name}').join(', ')}');
    }
  }

  Future<District?> getDistrict(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      districtsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return District.fromJson(maps.first);
    }
    return null;
  }

  Future<void> insertBodies(List<Body> bodies) async {
    AppLogger.common('🏛️ [SQLite] Starting to insert ${bodies.length} bodies into local database');
    final db = await database;
    final batch = db.batch();
    for (var body in bodies) {
      batch.insert(
        bodiesTable,
        body.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
    await updateCacheMetadata('bodies');
    AppLogger.common('✅ [SQLite] Successfully inserted ${bodies.length} bodies into local database');
    if (bodies.isNotEmpty) {
      AppLogger.common('🏛️ [SQLite] Sample bodies cached: ${bodies.take(2).map((b) => '${b.id}:${b.name}').join(', ')}');
    }
  }

  Future<Body?> getBody(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      bodiesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Body.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Body>> getBodiesForDistrict(String districtId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      bodiesTable,
      where: 'districtId = ?',
      whereArgs: [districtId],
    );
    return maps.map((map) => Body.fromJson(map)).toList();
  }

  Future<void> insertWards(List<Ward> wards) async {
    AppLogger.common('🏛️ [SQLite] Starting to insert ${wards.length} wards into local database');
    final db = await database;
    final batch = db.batch();
    for (var ward in wards) {
      final wardData = ward.toJson();
      AppLogger.common('🏛️ [SQLite] Ward data before conversion: id=${wardData['id']}, districtId=${wardData['districtId']}, bodyId=${wardData['bodyId']}, name=${wardData['name']}');
      // Convert areas list to comma-separated string for SQLite storage
      if (wardData['areas'] != null && wardData['areas'] is List) {
        wardData['areas'] = (wardData['areas'] as List).join(',');
      }
      AppLogger.common('🏛️ [SQLite] Ward data after conversion: $wardData');
      batch.insert(
        wardsTable,
        wardData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
    await updateCacheMetadata('wards');
    AppLogger.common('✅ [SQLite] Successfully inserted ${wards.length} wards into local database');
    if (wards.isNotEmpty) {
      AppLogger.common('🏛️ [SQLite] Sample wards cached: ${wards.take(2).map((w) => '${w.id}:${w.name}').join(', ')}');
    }
  }

  Future<Ward?> getWard(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      wardsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final wardData = Map<String, dynamic>.from(maps.first);
      // Convert areas string back to List<String> for Ward.fromJson
      if (wardData['areas'] != null && wardData['areas'] is String) {
        wardData['areas'] = (wardData['areas'] as String).split(',').where((s) => s.isNotEmpty).toList();
      }
      return Ward.fromJson(wardData);
    }
    return null;
  }

  // Candidate operations
  Future<void> insertCandidates(List<Candidate> candidates, String wardId) async {
    final startTime = DateTime.now();
    AppLogger.common('💾 [SQLite:Candidates] Starting batch insert operation - Candidates to insert: ${candidates.length}, Ward ID: $wardId');

    final db = await database;
    final batch = db.batch();

    for (var candidate in candidates) {
      final candidateData = {
        'id': candidate.candidateId,
        'wardId': wardId,
        'districtId': candidate.districtId,
        'bodyId': candidate.bodyId,
        'stateId': candidate.stateId ?? 'maharashtra',
        'userId': candidate.userId ?? '',
        'name': candidate.name,
        'party': candidate.party,
        'photo': candidate.photo,
        'followersCount': candidate.followersCount,
        'data': candidate.toJson().toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      batch.insert(
        candidatesTable,
        candidateData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final batchStartTime = DateTime.now();
    await batch.commit();
    final batchTime = DateTime.now().difference(batchStartTime).inMilliseconds;

    final metadataStartTime = DateTime.now();
    await updateCacheMetadata('candidates_$wardId');
    final metadataTime = DateTime.now().difference(metadataStartTime).inMilliseconds;

    final totalTime = DateTime.now().difference(startTime).inMilliseconds;

    AppLogger.common('✅ [SQLite:Candidates] Batch insert completed successfully - Total time: ${totalTime}ms, Batch commit: ${batchTime}ms, Metadata update: ${metadataTime}ms, Cache key: candidates_$wardId');
  }

  Future<List<Candidate>?> getCandidatesForWard(String wardId) async {
    final startTime = DateTime.now();
    try {
      AppLogger.common('🔍 [SQLite:Candidates] Querying candidates for ward: $wardId');

      // Check if candidates cache is valid (24 hours)
      final cacheCheckStart = DateTime.now();
      final lastUpdate = await getLastUpdateTime('candidates_$wardId');
      final cacheAge = lastUpdate != null ? DateTime.now().difference(lastUpdate) : null;
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < const Duration(hours: 24);
      final cacheCheckTime = DateTime.now().difference(cacheCheckStart).inMilliseconds;

      AppLogger.common('📊 [SQLite:Candidates] Cache validation for ward: $wardId - Last update: ${lastUpdate?.toIso8601String() ?? 'Never'}, Cache age: ${cacheAge?.inMinutes ?? 'N/A'} minutes, Is valid: $isCacheValid, Validation time: ${cacheCheckTime}ms');

      if (!isCacheValid) {
        AppLogger.common('🔄 [SQLite:Candidates] Cache expired or missing for ward: $wardId');
        return null;
      }

      final db = await database;
      final queryStartTime = DateTime.now();
      final List<Map<String, dynamic>> maps = await db.query(
        candidatesTable,
        where: 'wardId = ?',
        whereArgs: [wardId],
      );
      final queryTime = DateTime.now().difference(queryStartTime).inMilliseconds;

      if (maps.isEmpty) {
        AppLogger.common('🔄 [SQLite:Candidates] No candidates found in database for ward: $wardId');
        return null;
      }

      final parseStartTime = DateTime.now();
      final candidates = maps.map((map) {
        // Parse the JSON data back to Candidate
        final data = map['data'] as String;
        return Candidate.fromJson(Map<String, dynamic>.from(json.decode(data)));
      }).toList();
      final parseTime = DateTime.now().difference(parseStartTime).inMilliseconds;

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;

      AppLogger.common('✅ [SQLite:Candidates] Successfully loaded candidates from cache - Ward: $wardId, Candidates: ${candidates.length}, Parse time: ${parseTime}ms, Total time: ${totalTime}ms, Sample: ${candidates.take(2).map((c) => '${c.candidateId}:${c.name}').join(', ')}');

      return candidates;
    } catch (e) {
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.common('❌ [SQLite:Candidates] Error loading candidates (${totalTime}ms): $e');
      return null;
    }
  }

  // Get ward name by IDs (optimized query for candidate profile)
  Future<String?> getWardName(String districtId, String bodyId, String wardId, [String? stateId]) async {
    AppLogger.common('🔍 [SQLite] getWardName: Querying for stateId=$stateId, districtId=$districtId, bodyId=$bodyId, wardId=$wardId');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      wardsTable,
      columns: ['name'],
      where: stateId != null ? 'districtId = ? AND bodyId = ? AND id = ? AND stateId = ?' : 'districtId = ? AND bodyId = ? AND id = ?',
      whereArgs: stateId != null ? [districtId, bodyId, wardId, stateId] : [districtId, bodyId, wardId],
    );
    AppLogger.common('🔍 [SQLite] getWardName: Found ${maps.length} results');
    if (maps.isNotEmpty) {
      final name = maps.first['name'] as String?;
      AppLogger.common('🔍 [SQLite] getWardName: Returning ward name: "$name"');
      return name;
    }
    AppLogger.common('🔍 [SQLite] getWardName: No ward found, returning null');
    return null;
  }

  // Get district name by ID
  Future<String?> getDistrictName(String districtId, [String? stateId]) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      districtsTable,
      columns: ['name'],
      where: stateId != null ? 'id = ? AND stateId = ?' : 'id = ?',
      whereArgs: stateId != null ? [districtId, stateId] : [districtId],
    );
    if (maps.isNotEmpty) {
      return maps.first['name'] as String?;
    }
    return null;
  }

  // Get body name by ID
  Future<String?> getBodyName(String bodyId, [String? stateId]) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      bodiesTable,
      columns: ['name'],
      where: stateId != null ? 'id = ? AND stateId = ?' : 'id = ?',
      whereArgs: stateId != null ? [bodyId, stateId] : [bodyId],
    );
    if (maps.isNotEmpty) {
      return maps.first['name'] as String?;
    }
    return null;
  }

  // Cache metadata operations
  Future<void> updateCacheMetadata(String cacheKey) async {
    final db = await database;
    await db.insert(
      cacheMetadataTable,
      {
        columnCacheKey: cacheKey,
        columnLastUpdated: DateTime.now().toIso8601String(),
        columnDataVersion: 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getLastUpdateTime(String cacheKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      cacheMetadataTable,
      columns: [columnLastUpdated],
      where: '$columnCacheKey = ?',
      whereArgs: [cacheKey],
    );
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first[columnLastUpdated] as String);
    }
    return null;
  }

  // Clear all data (useful for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(districtsTable);
    await db.delete(bodiesTable);
    await db.delete(wardsTable);
    await db.delete(candidatesTable);
    await db.delete(commentsTable);
    await db.delete(likesTable);
    await db.delete(pollsTable);
    await db.delete(districtSpotlightsTable);
    await db.delete(cacheMetadataTable);
  }

  // Get database statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    final districtCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $districtsTable'),
    ) ?? 0;
    final bodyCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $bodiesTable'),
    ) ?? 0;
    final wardCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $wardsTable'),
    ) ?? 0;
    final candidateCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $candidatesTable'),
    ) ?? 0;
    final commentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $commentsTable'),
    ) ?? 0;
    final likeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $likesTable'),
    ) ?? 0;
    final pollCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $pollsTable'),
    ) ?? 0;
    final districtSpotlightCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $districtSpotlightsTable'),
    ) ?? 0;

    return {
      'districts': districtCount,
      'bodies': bodyCount,
      'wards': wardCount,
      'candidates': candidateCount,
      'comments': commentCount,
      'likes': likeCount,
      'polls': pollCount,
      'district_spotlights': districtSpotlightCount,
    };
  }

  // Get candidate location data (district name, body name, ward name)
  Future<Map<String, String?>> getCandidateLocationData(
    String districtId,
    String bodyId,
    String wardId,
    [String? stateId]
  ) async {
    final effectiveStateId = stateId ?? 'maharashtra'; // Default fallback
    AppLogger.common('🔍 [SQLite] Fetching location data for candidate: state=$effectiveStateId, district=$districtId, body=$bodyId, ward=$wardId');
    try {
      final districtName = await getDistrictName(districtId, effectiveStateId);
      final bodyName = await getBodyName(bodyId, effectiveStateId);
      final wardName = await getWardName(districtId, bodyId, wardId, effectiveStateId);

      final result = {
        'districtName': districtName,
        'bodyName': bodyName,
        'wardName': wardName,
      };

      AppLogger.common('✅ [SQLite] Location data retrieved: District="$districtName", Body="$bodyName", Ward="$wardName"');
      return result;
    } catch (e) {
      AppLogger.common('❌ [LocalDatabaseService] Error getting candidate location data: $e');
      final fallbackResult = {
        'districtName': districtId,
        'bodyName': bodyId,
        'wardName': 'Ward $wardId',
      };
      AppLogger.common('⚠️ [SQLite] Using fallback location data: $fallbackResult');
      return fallbackResult;
    }
  }

  // District Spotlight operations
  Future<void> insertDistrictSpotlight(DistrictSpotlight spotlight, String stateId, String districtId) async {
    final db = await database;
    final spotlightData = {
      'id': spotlight.id ?? '${stateId}_${districtId}',
      'stateId': stateId,
      'districtId': districtId,
      'partyId': spotlight.partyId,
      'fullImage': spotlight.fullImage,
      'bannerImage': spotlight.bannerImage,
      'isActive': spotlight.isActive ? 1 : 0,
      'createdAt': spotlight.createdAt?.toIso8601String(),
      'updatedAt': spotlight.updatedAt?.toIso8601String(),
      'lastFetched': DateTime.now().toIso8601String(),
      'version': spotlight.version,
    };

    await db.insert(
      districtSpotlightsTable,
      spotlightData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await updateCacheMetadata('district_spotlight_${stateId}_${districtId}');
    AppLogger.districtSpotlight('✅ [SQLite:DistrictSpotlight] Inserted district spotlight for $stateId/$districtId');
  }

  Future<DistrictSpotlight?> getDistrictSpotlight(String stateId, String districtId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      districtSpotlightsTable,
      where: 'stateId = ? AND districtId = ?',
      whereArgs: [stateId, districtId],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return DistrictSpotlight(
        id: map['id'],
        partyId: map['partyId'],
        fullImage: map['fullImage'],
        bannerImage: map['bannerImage'],
        isActive: map['isActive'] == 1,
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
        updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
        version: map['version'],
      );
    }
    return null;
  }

  Future<DateTime?> getDistrictSpotlightLastFetched(String stateId, String districtId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      districtSpotlightsTable,
      columns: ['lastFetched'],
      where: 'stateId = ? AND districtId = ?',
      whereArgs: [stateId, districtId],
    );

    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['lastFetched']);
    }
    return null;
  }

  // Delete district spotlight for a specific district
  Future<void> clearDistrictSpotlight(String stateId, String districtId) async {
    final db = await database;
    await db.delete(
      districtSpotlightsTable,
      where: 'stateId = ? AND districtId = ?',
      whereArgs: [stateId, districtId],
    );
    AppLogger.districtSpotlight('🗑️ [SQLite:DistrictSpotlight] Cleared district spotlight cache for $stateId/$districtId');
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
