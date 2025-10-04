import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  // Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Request photos permission (iOS)
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // Check microphone permission
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  // Check camera permission
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // Check storage permission
  static Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  // Check photos permission
  static Future<bool> hasPhotosPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  // Request all media permissions
  static Future<Map<Permission, PermissionStatus>>
  requestMediaPermissions() async {
    return await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  // Check if all media permissions are granted
  static Future<bool> hasAllMediaPermissions() async {
    final statuses = await Future.wait([
      Permission.camera.status,
      Permission.microphone.status,
      Permission.storage.status,
      Permission.photos.status,
    ]);

    return statuses.every((status) => status.isGranted);
  }

  // Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // Handle permission denied
  static Future<void> handlePermissionDenied(String permissionName) async {
    // Show dialog or snackbar explaining why permission is needed
    // This would typically be handled in the UI layer
  }

  // Check if permission is permanently denied
  static bool isPermanentlyDenied(PermissionStatus status) {
    return status.isPermanentlyDenied;
  }

  // Get permission status message
  static String getPermissionStatusMessage(
    Permission permission,
    PermissionStatus status,
  ) {
    if (status.isGranted) {
      return '${permission.toString().split('.').last} permission granted';
    } else if (status.isDenied) {
      return '${permission.toString().split('.').last} permission denied';
    } else if (status.isPermanentlyDenied) {
      return '${permission.toString().split('.').last} permission permanently denied. Please enable in settings.';
    } else {
      return '${permission.toString().split('.').last} permission status unknown';
    }
  }
}

