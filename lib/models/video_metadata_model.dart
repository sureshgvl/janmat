import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for processed video metadata after Cloudinary processing
class ProcessedVideo {
  final String id;
  final String originalUrl;
  final Map<String, VideoResolution> resolutions;
  final String? hlsUrl;
  final int duration; // in seconds
  final String thumbnailUrl;
  final VideoAnalytics analytics;
  final DateTime processedAt;
  final String status; // 'processing', 'completed', 'failed'
  final String? errorMessage;

  ProcessedVideo({
    required this.id,
    required this.originalUrl,
    required this.resolutions,
    this.hlsUrl,
    required this.duration,
    required this.thumbnailUrl,
    required this.analytics,
    required this.processedAt,
    required this.status,
    this.errorMessage,
  });

  /// Create from Cloudinary response
  factory ProcessedVideo.fromCloudinary(
    Map<String, dynamic> data,
    String videoId,
  ) {
    final resolutions = <String, VideoResolution>{};

    // Parse different resolution formats from Cloudinary
    if (data['derived'] != null) {
      final derived = data['derived'] as List<dynamic>;
      for (final item in derived) {
        if (item is Map<String, dynamic>) {
          final format = item['format'] as String?;
          final width = item['width'] as int?;
          final height = item['height'] as int?;
          final url = item['secure_url'] as String?;
          final bytes = item['bytes'] as int?;

          if (format == 'mp4' &&
              url != null &&
              width != null &&
              height != null) {
            final resolution = _getResolutionKey(width, height);
            resolutions[resolution] = VideoResolution(
              url: url,
              width: width,
              height: height,
              size: bytes ?? 0,
              bitrate: _calculateBitrate(
                bytes ?? 0,
                data['duration'] as num? ?? 0,
              ),
            );
          }
        }
      }
    }

    return ProcessedVideo(
      id: videoId,
      originalUrl: data['secure_url'] as String? ?? '',
      resolutions: resolutions,
      hlsUrl: data['hls_url'] as String?,
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      thumbnailUrl: _generateThumbnailUrl(data['secure_url'] as String? ?? ''),
      analytics: VideoAnalytics.empty(),
      processedAt: DateTime.now(),
      status: 'completed',
    );
  }

  /// Create from Firestore document
  factory ProcessedVideo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final resolutionsData = data['resolutions'] as Map<String, dynamic>? ?? {};
    final resolutions = <String, VideoResolution>{};

    resolutionsData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        resolutions[key] = VideoResolution.fromMap(value);
      }
    });

    return ProcessedVideo(
      id: doc.id,
      originalUrl: data['originalUrl'] as String? ?? '',
      resolutions: resolutions,
      hlsUrl: data['hlsUrl'] as String?,
      duration: data['duration'] as int? ?? 0,
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      analytics: VideoAnalytics.fromMap(
        data['analytics'] as Map<String, dynamic>? ?? {},
      ),
      processedAt:
          (data['processedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'processing',
      errorMessage: data['errorMessage'] as String?,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    final resolutionsMap = <String, dynamic>{};
    resolutions.forEach((key, value) {
      resolutionsMap[key] = value.toMap();
    });

    return {
      'originalUrl': originalUrl,
      'resolutions': resolutionsMap,
      'hlsUrl': hlsUrl,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'analytics': analytics.toMap(),
      'processedAt': Timestamp.fromDate(processedAt),
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  /// Get the best quality URL for current network conditions
  String getOptimalUrl(String connectionType) {
    // Return highest quality for WiFi, lower quality for mobile
    if (connectionType == 'wifi') {
      return resolutions['1080p']?.url ??
          resolutions['720p']?.url ??
          resolutions['480p']?.url ??
          originalUrl;
    } else {
      return resolutions['480p']?.url ??
          resolutions['360p']?.url ??
          resolutions['240p']?.url ??
          originalUrl;
    }
  }

  /// Get video file size for a specific resolution
  int getFileSize(String resolution) {
    return resolutions[resolution]?.size ?? 0;
  }

  /// Check if video processing is complete
  bool get isProcessed => status == 'completed';

  /// Check if video processing failed
  bool get hasError => status == 'failed';

  static String _getResolutionKey(int width, int height) {
    if (width >= 1920 || height >= 1080) return '1080p';
    if (width >= 1280 || height >= 720) return '720p';
    if (width >= 854 || height >= 480) return '480p';
    if (width >= 640 || height >= 360) return '360p';
    return '240p';
  }

  static int _calculateBitrate(int bytes, num duration) {
    if (duration <= 0) return 0;
    return (bytes * 8) ~/ duration; // bits per second
  }

  static String _generateThumbnailUrl(String videoUrl) {
    // Generate thumbnail URL from video URL (Cloudinary format)
    if (videoUrl.contains('cloudinary.com')) {
      return videoUrl.replaceAll(
        '/upload/',
        '/upload/so_0,eo_1,f_jpg,w_320,h_180,c_fill/',
      );
    }
    return videoUrl; // Fallback
  }
}

/// Model for individual video resolution
class VideoResolution {
  final String url;
  final int width;
  final int height;
  final int size; // in bytes
  final int bitrate; // in bits per second

  VideoResolution({
    required this.url,
    required this.width,
    required this.height,
    required this.size,
    required this.bitrate,
  });

  factory VideoResolution.fromMap(Map<String, dynamic> map) {
    return VideoResolution(
      url: map['url'] as String? ?? '',
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
      size: map['size'] as int? ?? 0,
      bitrate: map['bitrate'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'width': width,
      'height': height,
      'size': size,
      'bitrate': bitrate,
    };
  }

  String get formattedSize {
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get resolutionLabel => '${height}p';
}

/// Model for video analytics
class VideoAnalytics {
  int totalViews;
  int uniqueViews;
  int watchTime; // in seconds
  Map<String, int> qualityViews; // { '720p': 150, '1080p': 75 }
  double dropOffRate; // percentage
  Map<String, int> deviceStats; // { 'mobile': 200, 'desktop': 50 }
  DateTime lastViewed;

  VideoAnalytics({
    required this.totalViews,
    required this.uniqueViews,
    required this.watchTime,
    required this.qualityViews,
    required this.dropOffRate,
    required this.deviceStats,
    required this.lastViewed,
  });

  factory VideoAnalytics.empty() {
    return VideoAnalytics(
      totalViews: 0,
      uniqueViews: 0,
      watchTime: 0,
      qualityViews: {},
      dropOffRate: 0.0,
      deviceStats: {},
      lastViewed: DateTime.now(),
    );
  }

  factory VideoAnalytics.fromMap(Map<String, dynamic> map) {
    final qualityViews = <String, int>{};
    final deviceStats = <String, int>{};

    (map['qualityViews'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      qualityViews[key] = value as int? ?? 0;
    });

    (map['deviceStats'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
      deviceStats[key] = value as int? ?? 0;
    });

    return VideoAnalytics(
      totalViews: map['totalViews'] as int? ?? 0,
      uniqueViews: map['uniqueViews'] as int? ?? 0,
      watchTime: map['watchTime'] as int? ?? 0,
      qualityViews: qualityViews,
      dropOffRate: (map['dropOffRate'] as num?)?.toDouble() ?? 0.0,
      deviceStats: deviceStats,
      lastViewed: (map['lastViewed'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalViews': totalViews,
      'uniqueViews': uniqueViews,
      'watchTime': watchTime,
      'qualityViews': qualityViews,
      'dropOffRate': dropOffRate,
      'deviceStats': deviceStats,
      'lastViewed': Timestamp.fromDate(lastViewed),
    };
  }

  /// Record a view
  void recordView(String quality, String deviceType) {
    totalViews++;
    qualityViews[quality] = (qualityViews[quality] ?? 0) + 1;
    deviceStats[deviceType] = (deviceStats[deviceType] ?? 0) + 1;
    lastViewed = DateTime.now();
  }

  /// Calculate average watch time
  double get averageWatchTime {
    if (totalViews == 0) return 0.0;
    return watchTime / totalViews;
  }

  /// Get most popular quality
  String get mostPopularQuality {
    if (qualityViews.isEmpty) return 'unknown';
    return qualityViews.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Video processing configuration
class VideoProcessingConfig {
  final int maxFileSize; // in MB
  final List<String> allowedFormats;
  final Map<String, VideoQualitySettings> qualitySettings;
  final bool enableHLS;
  final bool generateThumbnails;

  const VideoProcessingConfig({
    this.maxFileSize = 500,
    this.allowedFormats = const ['mp4', 'mov', 'avi', 'mkv'],
    this.qualitySettings = const {
      '1080p': VideoQualitySettings(
        width: 1920,
        height: 1080,
        bitrate: 4000000,
      ),
      '720p': VideoQualitySettings(width: 1280, height: 720, bitrate: 2500000),
      '480p': VideoQualitySettings(width: 854, height: 480, bitrate: 1200000),
      '360p': VideoQualitySettings(width: 640, height: 360, bitrate: 800000),
      '240p': VideoQualitySettings(width: 426, height: 240, bitrate: 400000),
    },
    this.enableHLS = true,
    this.generateThumbnails = true,
  });
}

/// Quality settings for video encoding
class VideoQualitySettings {
  final int width;
  final int height;
  final int bitrate; // in bits per second

  const VideoQualitySettings({
    required this.width,
    required this.height,
    required this.bitrate,
  });

  String get resolutionLabel => '${height}p';
  String get formattedBitrate =>
      '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';
}
