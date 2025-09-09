import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Upload profile photo
  Future<String?> uploadProfilePhoto(String userId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('profile_photos/$fileName');

      final uploadTask = storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile photo: $e');
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  // Upload manifesto PDF
  Future<String?> uploadManifestoPdf(String userId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final fileName = 'manifesto_${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storageRef = _storage.ref().child('manifestos/$fileName');

      UploadTask uploadTask;
      if (file.bytes != null) {
        // Web platform
        uploadTask = storageRef.putData(
          file.bytes!,
          SettableMetadata(contentType: 'application/pdf'),
        );
      } else {
        // Mobile platforms
        uploadTask = storageRef.putFile(
          File(file.path!),
          SettableMetadata(contentType: 'application/pdf'),
        );
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading manifesto PDF: $e');
      throw Exception('Failed to upload manifesto PDF: $e');
    }
  }

  // Upload candidate photo (for candidate profile)
  Future<String?> uploadCandidatePhoto(String candidateId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return null;

      final fileName = 'candidate_${candidateId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('candidate_photos/$fileName');

      final uploadTask = storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading candidate photo: $e');
      throw Exception('Failed to upload candidate photo: $e');
    }
  }

  // Generic file upload method
  Future<String?> uploadFile(
    String filePath,
    String storagePath,
    String contentType,
  ) async {
    try {
      final fileName = path.basename(filePath);
      final storageRef = _storage.ref().child('$storagePath/$fileName');

      final uploadTask = storageRef.putFile(
        File(filePath),
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      // Don't throw error for delete failures as file might not exist
    }
  }

  // Get file download URL
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting download URL: $e');
      return null;
    }
  }
}