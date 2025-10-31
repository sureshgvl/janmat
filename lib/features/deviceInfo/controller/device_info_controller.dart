import 'dart:io';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../model/device_info_model.dart';
import '../../../utils/app_logger.dart';

/// Centralized controller for managing device information across the entire app.
/// Eliminates redundant device info fetches by caching device data.
/// Follows the GetX controller pattern for consistency with the app architecture.
class DeviceInfoController extends GetxController {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Reactive device info
  final Rx<DeviceInfoModel?> deviceInfo = Rx<DeviceInfoModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  // Cache timestamps for data freshness
  DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(hours: 24); // Device info rarely changes

  // Getters for commonly accessed device properties
  String? get deviceId => deviceInfo.value?.deviceId;
  String? get deviceName => deviceInfo.value?.deviceName;
  String? get deviceModel => deviceInfo.value?.deviceModel;
  String? get deviceType => deviceInfo.value?.deviceType;
  String? get osVersion => deviceInfo.value?.osVersion;
  String? get appVersion => deviceInfo.value?.appVersion;
  String? get buildNumber => deviceInfo.value?.buildNumber;
  bool get isPhysicalDevice => deviceInfo.value?.isPhysicalDevice ?? true;

  // Reactive streams for components that need to react to device info changes
  Stream<DeviceInfoModel?> get deviceInfoStream => deviceInfo.stream;
  Stream<bool> get loadingStream => isLoading.stream;

  @override
  void onInit() {
    super.onInit();
    AppLogger.core('📱 DeviceInfoController initialized');
    loadDeviceInfo();
  }

  @override
  void onClose() {
    AppLogger.core('🧹 DeviceInfoController cleaned up');
    super.onClose();
  }

  /// Load device information with caching
  Future<void> loadDeviceInfo() async {
    try {
      isLoading.value = true;

      // Check if we have valid cached data
      if (_hasValidCache() && deviceInfo.value != null) {
        AppLogger.core('✅ Using cached device info');
        isInitialized.value = true;
        isLoading.value = false;
        return;
      }

      AppLogger.core('🔍 Loading device information');

      // Get package info for app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      // Get device info based on platform
      DeviceInfoModel? info;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info = DeviceInfoModel.fromAndroidDeviceInfo(androidInfo, appVersion, buildNumber);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info = DeviceInfoModel.fromIosDeviceInfo(iosInfo, appVersion, buildNumber);
      } else {
        // Web or other platforms
        final webInfo = await _deviceInfo.webBrowserInfo;
        info = DeviceInfoModel.fromWebBrowserInfo(webInfo, appVersion, buildNumber);
      }

      deviceInfo.value = info;
      _lastFetchTime = DateTime.now();
      isInitialized.value = true;

      AppLogger.core('📱 Device info loaded: ${info.deviceName} (${info.deviceType})');

    } catch (e) {
      AppLogger.coreError('❌ Failed to load device info', error: e);
      // Create fallback device info
      deviceInfo.value = DeviceInfoModel(
        deviceId: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
        deviceName: 'Unknown Device',
        deviceModel: 'Unknown Model',
        deviceType: Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown',
        osVersion: 'Unknown',
        appVersion: 'Unknown',
        buildNumber: 'Unknown',
        isPhysicalDevice: true,
        lastUpdated: DateTime.now(),
      );
      isInitialized.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Force refresh device information (useful for testing or when device changes)
  Future<void> refreshDeviceInfo() async {
    _lastFetchTime = null; // Invalidate cache
    await loadDeviceInfo();
  }

  /// Update app version info (when app is updated)
  Future<void> updateAppVersion() async {
    if (deviceInfo.value == null) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      deviceInfo.value = deviceInfo.value!.copyWith(
        appVersion: appVersion,
        buildNumber: buildNumber,
        lastUpdated: DateTime.now(),
      );

      AppLogger.core('📱 App version updated: $appVersion ($buildNumber)');
    } catch (e) {
      AppLogger.coreError('❌ Failed to update app version', error: e);
    }
  }

  /// Check if device is Android
  bool get isAndroid => deviceType == 'android';

  /// Check if device is iOS
  bool get isIOS => deviceType == 'ios';

  /// Check if device is Web
  bool get isWeb => deviceType == 'web';

  /// Get device info as a formatted string
  String getDeviceInfoString() {
    if (deviceInfo.value == null) return 'Device info not available';

    final info = deviceInfo.value!;
    return '${info.deviceName} (${info.deviceModel}) - ${info.osVersion} - App ${info.appVersion}';
  }

  /// Get device capabilities summary
  Map<String, dynamic> getDeviceCapabilities() {
    if (deviceInfo.value == null) return {};

    final info = deviceInfo.value!;
    return {
      'deviceType': info.deviceType,
      'isPhysicalDevice': info.isPhysicalDevice,
      'osVersion': info.osVersion,
      'appVersion': info.appVersion,
      'buildNumber': info.buildNumber,
      'supportsVibration': !isWeb, // Web doesn't support vibration
      'supportsPushNotifications': !isWeb, // Web has limited push support
      'supportsCamera': !isWeb, // Web has camera support but different API
      'supportsLocation': true, // All platforms support location
    };
  }

  /// Check if cache is valid
  bool _hasValidCache() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isLoading': isLoading.value,
      'isInitialized': isInitialized.value,
      'hasDeviceInfo': deviceInfo.value != null,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'isPhysicalDevice': isPhysicalDevice,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'cacheValid': _hasValidCache(),
    };
  }
}
