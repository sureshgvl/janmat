import 'package:firebase_storage/firebase_storage.dart';
import 'media_file.dart';
import 'media_uploader_advanced.dart';

/// Service for uploading files to Firebase Storage
class UploadService {
  final storage = FirebaseStorage.instance;

  Future<Map<String, String>> uploadFiles({
    required String candidateId,
    required List<MediaFile> files,
    required Function(String, UploadProgress) onProgress,
  }) async {
    Map<String, String> result = {};

    for (var f in files) {
      final task = storage
          .ref("candidates/$candidateId/${f.type}/${f.name}")
          .putData(f.bytes);

      task.snapshotEvents.listen((event) {
        onProgress(
          f.id,
          UploadProgress(
            percent: (event.bytesTransferred / event.totalBytes) * 100,
            transferred: event.bytesTransferred,
            total: event.totalBytes,
            speedKBps: 0,
            eta: const Duration(seconds: 1),
          ),
        );
      });

      final url = await (await task).ref.getDownloadURL();
      result[f.type] = url;
    }

    return result;
  }

  Future<void> deleteFile(String url) async {
    await storage.refFromURL(url).delete();
  }
}
