import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'package:uuid/uuid.dart';
import '../local_database_service.dart'; // Assuming this exists for DB path
import 'i_sync_service.dart';

// CallbackDispatcher for WorkManager
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = MobileSyncService._internal();
      await service._processQueueInternal();
      return true;
    } catch (e) {
      print('WorkManager error: $e');
      return false;
    }
  });
}

class MobileSyncService implements ISyncService {
  static MobileSyncService? _instance;
  Database? _database;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  MobileSyncService._internal();

  factory MobileSyncService() {
    _instance ??= MobileSyncService._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'sync_queue.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        candidateId TEXT NOT NULL,
        target TEXT NOT NULL,
        payload TEXT NOT NULL,
        retries INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        timestamp INTEGER DEFAULT 0,
        localPath TEXT,
        fileType TEXT
      )
    ''');
  }

  @override
  Future<void> start() async {
    await database; // Ensure DB is ready
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    Workmanager().registerPeriodicTask(
      'sync-task',
      'sync-queue',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  @override
  Future<void> pause() async {
    Workmanager().cancelByUniqueName('sync-task');
  }

  @override
  Future<int> getPendingCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM sync_queue WHERE status = 'pending'",
    ));
    return count ?? 0;
  }

  @override
  Future<void> queueOperation(SyncOperation op) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id': op.id,
        'type': op.type.toString().split('.').last,
        'candidateId': op.candidateId,
        'target': op.target,
        'payload': jsonEncode(op.payload),
        'retries': op.retries,
        'status': op.status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> queueUpload(
    String candidateId,
    String tempId,
    dynamic localFile,
    dynamic webFile,
    {
      required String fileType,
    }
  ) async {
    if (localFile == null || !await (localFile as File).exists()) return;

    final opId = _uuid.v4();
    final operation = SyncOperation(
      id: opId,
      type: SyncOperationType.upload,
      candidateId: candidateId,
      target: 'media/$tempId',
      payload: {
        'tempId': tempId,
        'fileType': fileType,
        'size': await localFile.length(),
      },
    );

    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id': opId,
        'type': 'upload',
        'candidateId': candidateId,
        'target': 'media/$tempId',
        'payload': jsonEncode(operation.payload),
        'retries': 0,
        'status': 'pending',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'localPath': localFile.path,
        'fileType': fileType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> processQueue({int maxItems = 10}) async {
    await _processQueueInternal(maxItems);
  }

  Future<void> _processQueueInternal([int maxItems = 10]) async {
    final db = await database;
    final pendingOps = await db.query(
      'sync_queue',
      where: "status = 'pending'",
      orderBy: 'timestamp ASC',
      limit: maxItems,
    );

    for (final opRow in pendingOps) {
      try {
        await db.update(
          'sync_queue',
          {'status': 'processing'},
          where: 'id = ?',
          whereArgs: [opRow['id']],
        );

        final operation = SyncOperation(
          id: opRow['id'] as String,
          type: SyncOperationType.values.firstWhere(
            (e) => e.toString().split('.').last == opRow['type'],
          ),
          candidateId: opRow['candidateId'] as String,
          target: opRow['target'] as String,
          payload: jsonDecode(opRow['payload'] as String),
          retries: opRow['retries'] as int,
          status: 'processing',
        );

        bool success = false;
        switch (operation.type) {
          case SyncOperationType.upload:
            success = await _processUpload(operation, opRow);
            break;
          case SyncOperationType.update:
            success = await _processUpdate(operation);
            break;
          case SyncOperationType.delete:
            success = await _processDelete(operation);
            break;
        }

        if (success) {
          await db.update(
            'sync_queue',
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [opRow['id']],
          );
        } else {
          await db.update(
            'sync_queue',
            {
              'status': 'pending',
              'retries': (opRow['retries'] as int) + 1,
            },
            where: 'id = ?',
            whereArgs: [opRow['id']],
          );
        }
      } catch (e) {
        print('Error processing operation ${opRow['id']}: $e');
        await db.update(
          'sync_queue',
          {'status': 'pending', 'retries': (opRow['retries'] as int) + 1},
          where: 'id = ?',
          whereArgs: [opRow['id']],
        );
      }
    }
  }

  Future<bool> _processUpload(SyncOperation op, Map<String, dynamic> row) async {
    final localPath = row['localPath'] as String?;
    if (localPath == null || !File(localPath).existsSync()) return false;

    final fileRef = _storage.ref().child('candidates/${op.candidateId}/media/${op.payload['tempId']}');
    final uploadTask = fileRef.putFile(File(localPath));

    await uploadTask;
    final downloadUrl = await fileRef.getDownloadURL();

    // Update Firestore media subcollection
    await _firestore.collection('candidates').doc(op.candidateId).collection('media').doc(op.payload['tempId']).set({
      'id': op.payload['tempId'],
      'url': downloadUrl,
      'type': op.payload['fileType'],
      'size': op.payload['size'],
      'uploadedAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    });

    // Optionally update candidate doc media list
    // Assume GetX CandidateController is updated via payload

    return true;
  }

  Future<bool> _processUpdate(SyncOperation op) async {
    final pathComponents = op.target.split('/');
    if (pathComponents.isEmpty) return false;

    final collection = pathComponents[0];
    final docId = pathComponents[1];

    await _firestore.collection(collection).doc(docId).update(op.payload);
    return true;
  }

  Future<bool> _processDelete(SyncOperation op) async {
    final pathComponents = op.target.split('/');
    if (pathComponents.isEmpty) return false;

    final collection = pathComponents[0];
    final docId = pathComponents[1];

    await _firestore.collection(collection).doc(docId).delete();
    return true;
  }

  @override
  Future<void> markSynced(String opId) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [opId],
    );
  }
}
