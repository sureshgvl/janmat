import 'package:device_info_plus/device_info_plus.dart';

/// Model representing device information
/// Follows the same pattern as UserModel for consistency
class DeviceInfoModel {
  final String deviceId;
  final String deviceName;
  final String deviceModel;
  final String deviceType; // 'android', 'ios', 'web', etc.
  final String osVersion;
  final String appVersion;
  final String buildNumber;
  final int? sdkVersion; // Android only
  final String? manufacturer; // Android only
  final String? brand; // Android only
  final String? product; // Android only
  final String? device; // Android only
  final String? hardware; // Android only
  final String? identifierForVendor; // iOS only
  final String? localizedModel; // iOS only
  final String? systemName; // iOS only
  final bool isPhysicalDevice;
  final DateTime lastUpdated;

  DeviceInfoModel({
    required this.deviceId,
    required this.deviceName,
    required this.deviceModel,
    required this.deviceType,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    this.sdkVersion,
    this.manufacturer,
    this.brand,
    this.product,
    this.device,
    this.hardware,
    this.identifierForVendor,
    this.localizedModel,
    this.systemName,
    required this.isPhysicalDevice,
    required this.lastUpdated,
  });

  /// Create from device_info_plus AndroidDeviceInfo
  factory DeviceInfoModel.fromAndroidDeviceInfo(AndroidDeviceInfo info, String appVersion, String buildNumber) {
    return DeviceInfoModel(
      deviceId: info.id ?? 'unknown',
      deviceName: info.host ?? 'Unknown Device',
      deviceModel: info.model ?? 'Unknown Model',
      deviceType: 'android',
      osVersion: info.version.release ?? 'Unknown',
      appVersion: appVersion,
      buildNumber: buildNumber,
      sdkVersion: info.version.sdkInt,
      manufacturer: info.manufacturer,
      brand: info.brand,
      product: info.product,
      device: info.device,
      hardware: info.hardware,
      isPhysicalDevice: info.isPhysicalDevice ?? true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create from device_info_plus IosDeviceInfo
  factory DeviceInfoModel.fromIosDeviceInfo(IosDeviceInfo info, String appVersion, String buildNumber) {
    return DeviceInfoModel(
      deviceId: info.identifierForVendor ?? 'unknown',
      deviceName: info.name ?? 'Unknown Device',
      deviceModel: info.model ?? 'Unknown Model',
      deviceType: 'ios',
      osVersion: info.systemVersion ?? 'Unknown',
      appVersion: appVersion,
      buildNumber: buildNumber,
      identifierForVendor: info.identifierForVendor,
      localizedModel: info.localizedModel,
      systemName: info.systemName,
      isPhysicalDevice: info.isPhysicalDevice,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create from device_info_plus WebBrowserInfo
  factory DeviceInfoModel.fromWebBrowserInfo(WebBrowserInfo info, String appVersion, String buildNumber) {
    return DeviceInfoModel(
      deviceId: info.userAgent ?? 'web_unknown',
      deviceName: info.browserName.name ?? 'Web Browser',
      deviceModel: info.platform ?? 'Web',
      deviceType: 'web',
      osVersion: info.platform ?? 'Unknown',
      appVersion: appVersion,
      buildNumber: buildNumber,
      isPhysicalDevice: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create from JSON (for caching/storage)
  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceId: json['deviceId'] ?? 'unknown',
      deviceName: json['deviceName'] ?? 'Unknown Device',
      deviceModel: json['deviceModel'] ?? 'Unknown Model',
      deviceType: json['deviceType'] ?? 'unknown',
      osVersion: json['osVersion'] ?? 'Unknown',
      appVersion: json['appVersion'] ?? 'Unknown',
      buildNumber: json['buildNumber'] ?? 'Unknown',
      sdkVersion: json['sdkVersion'],
      manufacturer: json['manufacturer'],
      brand: json['brand'],
      product: json['product'],
      device: json['device'],
      hardware: json['hardware'],
      identifierForVendor: json['identifierForVendor'],
      localizedModel: json['localizedModel'],
      systemName: json['systemName'],
      isPhysicalDevice: json['isPhysicalDevice'] ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for caching/storage
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'deviceType': deviceType,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'sdkVersion': sdkVersion,
      'manufacturer': manufacturer,
      'brand': brand,
      'product': product,
      'device': device,
      'hardware': hardware,
      'identifierForVendor': identifierForVendor,
      'localizedModel': localizedModel,
      'systemName': systemName,
      'isPhysicalDevice': isPhysicalDevice,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  DeviceInfoModel copyWith({
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    String? deviceType,
    String? osVersion,
    String? appVersion,
    String? buildNumber,
    int? sdkVersion,
    String? manufacturer,
    String? brand,
    String? product,
    String? device,
    String? hardware,
    String? identifierForVendor,
    String? localizedModel,
    String? systemName,
    bool? isPhysicalDevice,
    DateTime? lastUpdated,
  }) {
    return DeviceInfoModel(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceType: deviceType ?? this.deviceType,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      manufacturer: manufacturer ?? this.manufacturer,
      brand: brand ?? this.brand,
      product: product ?? this.product,
      device: device ?? this.device,
      hardware: hardware ?? this.hardware,
      identifierForVendor: identifierForVendor ?? this.identifierForVendor,
      localizedModel: localizedModel ?? this.localizedModel,
      systemName: systemName ?? this.systemName,
      isPhysicalDevice: isPhysicalDevice ?? this.isPhysicalDevice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'DeviceInfoModel(deviceId: $deviceId, deviceName: $deviceName, deviceModel: $deviceModel, deviceType: $deviceType, osVersion: $osVersion, appVersion: $appVersion, buildNumber: $buildNumber, isPhysicalDevice: $isPhysicalDevice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfoModel &&
        other.deviceId == deviceId &&
        other.deviceName == deviceName &&
        other.deviceModel == deviceModel &&
        other.deviceType == deviceType &&
        other.osVersion == osVersion &&
        other.appVersion == appVersion &&
        other.buildNumber == buildNumber &&
        other.isPhysicalDevice == isPhysicalDevice;
  }

  @override
  int get hashCode {
    return deviceId.hashCode ^
        deviceName.hashCode ^
        deviceModel.hashCode ^
        deviceType.hashCode ^
        osVersion.hashCode ^
        appVersion.hashCode ^
        buildNumber.hashCode ^
        isPhysicalDevice.hashCode;
  }
}