import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'i_sync_service.dart';

class WebSyncService implements ISyncService {
  static WebSyncService? _instance;
  Box<Map>? _syncBox;
  Box<Map>? _mediaBox;
  Timer? _visibilityTimer;
  Timer? _onlineTimer;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  WebSyncService._internal();

  factory WebSyncService() {
    _instance ??= WebSyncService._internal();
    return _instance!;
  }

  Future<void> _ensureBoxesInitialized() async {
    if (_syncBox == null) {
      _syncBox = await Hive.openBox<Map>('syncQueue');
    }
    if (_mediaBox == null) {
      _mediaBox = await Hive.openBox<Map>('mediaQueue');
    }
  }

  @override
  Future<void> start() async {
    await _ensureBoxesInitialized();

    // Listen for visibility changes (tab becomes visible)
    html.document.addEventListener('visibilitychange', _handleVisibilityChange);

    // Listen for online events
    html.window.addEventListener('online', _handleOnline);

    _checkAutomaticSync();
  }

  void _handleVisibilityChange(html.Event event) {
    if (html.document.hidden == false) {
      _visibilityTimer?.cancel();
      _visibilityTimer = Timer(const Duration(seconds: 2), () {
        _checkAutomaticSync();
      });
    }
  }

  void _handleOnline(html.Event event) {
    _onlineTimer?.cancel();
    _onlineTimer = Timer(const Duration(seconds: 2), () {
      _checkAutomaticSync();
    });
  }

  void _checkAutomaticSync() {
    if (html.window.navigator.onLine == true) {
      processQueue();
    }
  }

  @override
  Future<void> pause() async {
    html.document.removeEventListener('visibilitychange', _handleVisibilityChange);
    html.window.removeEventListener('online', _handleOnline);
    _visibilityTimer?.cancel();
    _onlineTimer?.cancel();
  }

  @override
  Future<int> getPendingCount() async {
    await _ensureBoxesInitialized();
    return _syncBox!.values.where((op) => op['status'] == 'pending').length;
  }

  @override
  Future<void> queueOperation(SyncOperation op) async {
    await _ensureBoxesInitialized();
    final opMap = op.toJson();
    opMap['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    await _syncBox!.put(op.id, opMap);
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
    await _ensureBoxesInitialized();

    if (webFile is! html.File) return;

    final opId = _uuid.v4();
    final operation = SyncOperation(
      id: opId,
      type: SyncOperationType.upload,
      candidateId: candidateId,
      target: 'media/$tempId',
      payload: {
        'tempId': tempId,
        'fileType': fileType,
        'size': webFile.size,
      },
    );

    // Store file bytes in Hive (limited size, use key for reference)
    final reader = html.FileReader();
    reader.readAsArrayBuffer(webFile);
    await reader.onLoadEnd.first;

    final bytes = reader.result as Uint8List;
    final mediaKey = 'media_${tempId}';
    await _mediaBox!.put(mediaKey, {
      'bytes': base64Encode(bytes),
      'tempId': tempId,
      'fileType': fileType,
      'size': webFile.size,
    });

    await queueOperation(operation);
  }

  @override
  Future<void> processQueue({int maxItems = 10}) async {
    await _ensureBoxesInitialized();

    if (html.window.navigator.onLine != true) return;

    final pendingOpsMap = Map<String, Map<dynamic, dynamic>>.fromEntries(
      _syncBox!.toMap().entries
        .where((entry) => entry.value['status'] == 'pending')
        .cast<MapEntry<String, Map<dynamic, dynamic>>>()
        .take(maxItems)
    );

    for (final entry in pendingOpsMap.entries) {
      try {
        await _syncBox!.put(entry.key, {...entry.value, 'status': 'processing'});

        final operation = SyncOperation.fromJson(
          Map<String, dynamic>.from(entry.value)
        );

        bool success = false;
        switch (operation.type) {
          case SyncOperationType.upload:
            success = await _processUpload(operation);
            break;
          case SyncOperationType.update:
            success = await _processUpdate(operation);
            break;
          case SyncOperationType.delete:
            success = await _processDelete(operation);
            break;
        }

        if (success) {
          await _syncBox!.put(entry.key, {...entry.value, 'status': 'completed'});
        } else {
          final current = Map<String, dynamic>.from(entry.value);
          current['status'] = 'pending';
          current['retries'] = (current['retries'] ?? 0) + 1;
          await _syncBox!.put(entry.key, current);
        }
      } catch (e) {
        final current = Map<String, dynamic>.from(entry.value);
        current['status'] = 'pending';
        current['retries'] = (current['retries'] ?? 0) + 1;
        await _syncBox!.put(entry.key, current);
        print('Web sync error for ${entry.key}: $e');
      }
    }
  }

  Future<bool> _processUpload(SyncOperation op) async {
    final mediaKey = 'media_${op.payload['tempId']}';
    final mediaData = _mediaBox!.get(mediaKey);
    if (mediaData == null) return false;

    final bytes = base64Decode(mediaData['bytes'] as String);
    final fileRef = _storage.ref().child('candidates/${op.candidateId}/media/${op.payload['tempId']}');

    try {
      await fileRef.putData(
        bytes,
        SettableMetadata(contentType: op.payload['fileType']),
      );

      final downloadUrl = await fileRef.getDownloadURL();

      await _firestore.collection('candidates').doc(op.candidateId).collection('media').doc(op.payload['tempId']).set({
        'id': op.payload['tempId'],
        'url': downloadUrl,
        'type': op.payload['fileType'],
        'size': op.payload['size'],
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Clean up media data
      await _mediaBox!.delete(mediaKey);

      return true;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  Future<bool> _processUpdate(SyncOperation op) async {
    final pathComponents = op.target.split('/');
    if (pathComponents.length < 2) return false;

    final collection = pathComponents[0];
    final docId = pathComponents[1];

    await _firestore.collection(collection).doc(docId).update(op.payload);
    return true;
  }

  Future<bool> _processDelete(SyncOperation op) async {
    final pathComponents = op.target.split('/');
    if (pathComponents.length < 2) return false;

    final collection = pathComponents[0];
    final docId = pathComponents[1];

    await _firestore.collection(collection).doc(docId).delete();
    return true;
  }

  @override
  Future<void> markSynced(String opId) async {
    await _ensureBoxesInitialized();
    final op = _syncBox!.get(opId);
    if (op != null) {
      await _syncBox!.put(opId, {...op, 'status': 'completed'});
    }
  }
}
