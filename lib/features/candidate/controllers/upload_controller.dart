import 'package:get/get.dart';
import '../../../core/media/media_file.dart';
import '../../../core/media/file_picker_service.dart';
import '../../../core/media/media_uploader_advanced.dart';
import '../../../core/media/upload_service.dart';

/// Controller for managing file uploads with clean separation of concerns
class UploadController extends GetxController {
  var localFiles = <MediaFile>[].obs;
  var uploadedUrls = <String, String>{}.obs;
  var progress = <String, UploadProgress>{}.obs;

  final picker = FilePickerService();
  final storage = UploadService();

  Future<void> pickPdf() async => _pick("pdf");
  Future<void> pickImage() async => _pick("image");
  Future<void> pickVideo() async => _pick("video");

  Future<void> _pick(String type) async {
    final file = await picker.pickFile(type);
    if (file != null) {
      localFiles.removeWhere((x) => x.type == type);
      localFiles.add(file);
    }
  }

  Future<void> deleteFile(String url, String type) async {
    await storage.deleteFile(url);
    uploadedUrls[type] = "";
  }

  Future<Map<String, String>> uploadAll(String candidateId) async {
    uploadedUrls.clear();
    progress.clear();

    final urls = await storage.uploadFiles(
      candidateId: candidateId,
      files: localFiles,
      onProgress: (id, pr) => progress[id] = pr,
    );

    urls.forEach((type, url) => uploadedUrls[type] = url);
    localFiles.clear();

    return urls;
  }
}
