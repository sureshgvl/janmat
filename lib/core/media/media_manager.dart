import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Complete MediaManager class for safe file operations
/// Prevents dangling files, memory leaks, and handles replacements safely
class MediaManager {
  MediaManager._(); // private constructor
  static final MediaManager instance = MediaManager._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------------
  // 🔥 1. Upload New File (with progress)
  // ------------------------------
  Future<String> uploadFile({
    required Uint8List bytes,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(storagePath);
    final uploadTask = ref.putData(bytes);

    // Progress listener
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (snapshot.totalBytes > 0 && onProgress != null) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        onProgress(progress);
      }
    });

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  // ------------------------------
  // 🔥 2. Replace File Safely (upload new → update db → delete old)
  // ------------------------------
  Future<String> replaceFile({
    required Uint8List newBytes,
    required String newStoragePath,
    required String dbPath,
    String? oldFileUrl,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Upload new file
    final newUrl = await uploadFile(
      bytes: newBytes,
      storagePath: newStoragePath,
      onProgress: onProgress,
    );

    // 2. Update database
    await _db.doc(dbPath).set({'url': newUrl}, SetOptions(merge: true));

    // 3. Delete old file (async)
    if (oldFileUrl != null && oldFileUrl.isNotEmpty) {
      _safeDelete(oldFileUrl);
    }

    return newUrl;
  }

  // ------------------------------
  // 🔥 3. Delete File (safe)
  // ------------------------------
  Future<void> deleteFile(String fileUrl) async {
    try {
      await _storage.refFromURL(fileUrl).delete();
    } catch (_) {
      // ignore cleanup failures
    }
  }

  void _safeDelete(String fileUrl) {
    try {
      _storage.refFromURL(fileUrl).delete();
    } catch (_) {}
  }

  // ------------------------------
  // 🔥 4. Upload multiple files
  // ------------------------------
  Future<List<String>> uploadMultiple({
    required List<Uint8List> files,
    required String Function(int index) storagePathBuilder,
    void Function(int index, double progress)? onProgress,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < files.length; i++) {
      final url = await uploadFile(
        bytes: files[i],
        storagePath: storagePathBuilder(i),
        onProgress: (p) => onProgress?.call(i, p),
      );
      urls.add(url);
    }

    return urls;
  }

  // ------------------------------
  // 🔥 5. Replace multiple files safely
  // ------------------------------
  Future<List<String>> replaceMultiple({
    required List<Uint8List> newFiles,
    required List<String?> oldUrls,
    required String Function(int index) storagePathBuilder,
    required String dbPath,
    void Function(int index, double progress)? onProgress,
  }) async {
    final newUrls = <String>[];

    for (int i = 0; i < newFiles.length; i++) {
      final url = await uploadFile(
        bytes: newFiles[i],
        storagePath: storagePathBuilder(i),
        onProgress: (p) => onProgress?.call(i, p),
      );
      newUrls.add(url);
    }

    // Update full array in DB
    await _db.doc(dbPath).set({'urls': newUrls}, SetOptions(merge: true));

    // Delete old files in background
    for (var old in oldUrls) {
      if (old != null && old.isNotEmpty) {
        _safeDelete(old);
      }
    }

    return newUrls;
  }

  // ------------------------------
  // 🔥 6. Get file metadata
  // ------------------------------
  Future<FullMetadata?> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (_) {
      return null;
    }
  }

  // ------------------------------
  // 🔥 7. Check if file exists
  // ------------------------------
  Future<bool> fileExists(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }
}