import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/video_metadata_model.dart';

/// Service for processing videos through Cloudinary and managing video metadata
class VideoProcessingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  // Cloudinary configuration - should be moved to environment variables
  static const String _cloudName =
      'your_cloud_name'; // Replace with actual cloud name
  static const String _apiKey = 'your_api_key'; // Replace with actual API key
  static const String _apiSecret =
      'your_api_secret'; // Replace with actual API secret
  static const String _uploadPreset =
      'manifesto_videos'; // Cloudinary upload preset

  /// Upload and process video through Cloudinary
  Future<ProcessedVideo> uploadAndProcessVideo(
    File videoFile,
    String candidateId, {
    Function(double)? onProgress,
    VideoProcessingConfig? config,
  }) async {
    final videoId = _uuid.v4();
    final configToUse = config ?? const VideoProcessingConfig();

    try {
      // Step 1: Validate file
      await _validateVideoFile(videoFile, configToUse);

      // Step 2: Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection available');
      }

      // Step 3: Upload to Cloudinary
      final cloudinaryResponse = await _uploadToCloudinary(
        videoFile,
        videoId,
        onProgress: onProgress,
      );

      // Step 4: Create ProcessedVideo object
      final processedVideo = ProcessedVideo.fromCloudinary(
        cloudinaryResponse,
        videoId,
      );

      // Step 5: Save metadata to Firestore
      await _saveVideoMetadata(processedVideo, candidateId);

      // Step 6: Update candidate's manifesto with video URL
      await _updateCandidateManifesto(candidateId, processedVideo);

      return processedVideo;
    } catch (e) {
      // Save error state to Firestore
      await _saveVideoError(videoId, candidateId, e.toString());
      rethrow;
    }
  }

  /// Get processed video by ID
  Future<ProcessedVideo?> getProcessedVideo(String videoId) async {
    try {
      final doc = await _firestore
          .collection('processed_videos')
          .doc(videoId)
          .get();
      if (doc.exists) {
        return ProcessedVideo.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting processed video: $e');
      return null;
    }
  }

  /// Get all videos for a candidate
  Future<List<ProcessedVideo>> getCandidateVideos(String candidateId) async {
    try {
      final querySnapshot = await _firestore
          .collection('processed_videos')
          .where('candidateId', isEqualTo: candidateId)
          .orderBy('processedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProcessedVideo.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting candidate videos: $e');
      return [];
    }
  }

  /// Record video analytics
  Future<void> recordVideoView(
    String videoId,
    String quality,
    String deviceType,
    int watchDuration,
  ) async {
    try {
      final videoRef = _firestore.collection('processed_videos').doc(videoId);
      final doc = await videoRef.get();

      if (doc.exists) {
        final video = ProcessedVideo.fromFirestore(doc);
        video.analytics.recordView(quality, deviceType);

        // Update watch time
        final updatedAnalytics = video.analytics;
        updatedAnalytics.watchTime += watchDuration;

        await videoRef.update({'analytics': updatedAnalytics.toMap()});
      }
    } catch (e) {
      print('Error recording video view: $e');
    }
  }

  /// Delete video and cleanup resources
  Future<void> deleteVideo(String videoId, String candidateId) async {
    try {
      // Get video metadata
      final video = await getProcessedVideo(videoId);
      if (video == null) return;

      // Delete from Cloudinary (if needed)
      await _deleteFromCloudinary(video.originalUrl);

      // Delete from Firestore
      await _firestore.collection('processed_videos').doc(videoId).delete();

      // Update candidate's manifesto
      await _removeVideoFromCandidateManifesto(candidateId, videoId);

      print('Video $videoId deleted successfully');
    } catch (e) {
      print('Error deleting video: $e');
      rethrow;
    }
  }

  /// Compress video locally before upload (for very large files)
  Future<File?> compressVideo(File videoFile, {int quality = 80}) async {
    try {
      // This would use video_compress package
      // For now, return original file
      // TODO: Implement local video compression
      print('Video compression not yet implemented, returning original file');
      return videoFile;
    } catch (e) {
      print('Error compressing video: $e');
      return videoFile; // Return original on error
    }
  }

  /// Get optimal video URL based on network conditions
  Future<String> getOptimalVideoUrl(String videoId) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final connectionType = connectivityResult == ConnectivityResult.wifi
        ? 'wifi'
        : 'mobile';

    final video = await getProcessedVideo(videoId);
    if (video != null) {
      return video.getOptimalUrl(connectionType);
    }

    throw Exception('Video not found');
  }

  // Private helper methods

  Future<void> _validateVideoFile(
    File videoFile,
    VideoProcessingConfig config,
  ) async {
    // Check file size
    final fileSize = await videoFile.length();
    final fileSizeMB = fileSize / (1024 * 1024);

    if (fileSizeMB > config.maxFileSize) {
      throw Exception(
        'Video file too large: ${fileSizeMB.toStringAsFixed(1)}MB (max: ${config.maxFileSize}MB)',
      );
    }

    // Check file extension
    final extension = videoFile.path.split('.').last.toLowerCase();
    if (!config.allowedFormats.contains(extension)) {
      throw Exception(
        'Unsupported video format: $extension. Allowed: ${config.allowedFormats.join(', ')}',
      );
    }

    // Additional validation could be added here
    // - Check video duration
    // - Check video resolution
    // - Scan for malware (if needed)
  }

  Future<Map<String, dynamic>> _uploadToCloudinary(
    File videoFile,
    String videoId, {
    Function(double)? onProgress,
  }) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = videoId
      ..fields['resource_type'] = 'video'
      // Add transformation parameters for multiple resolutions
      ..fields['eager'] = jsonEncode([
        // 1080p
        {
          'width': 1920,
          'height': 1080,
          'crop': 'limit',
          'quality': 'auto',
          'bitrate': '4000k',
        },
        // 720p
        {
          'width': 1280,
          'height': 720,
          'crop': 'limit',
          'quality': 'auto',
          'bitrate': '2500k',
        },
        // 480p
        {
          'width': 854,
          'height': 480,
          'crop': 'limit',
          'quality': 'auto',
          'bitrate': '1200k',
        },
        // 360p
        {
          'width': 640,
          'height': 360,
          'crop': 'limit',
          'quality': 'auto',
          'bitrate': '800k',
        },
        // 240p
        {
          'width': 426,
          'height': 240,
          'crop': 'limit',
          'quality': 'auto',
          'bitrate': '400k',
        },
      ])
      ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Cloudinary upload successful for video: $videoId');
        return responseData;
      } else {
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload video to Cloudinary: $e');
    }
  }

  Future<void> _saveVideoMetadata(
    ProcessedVideo video,
    String candidateId,
  ) async {
    try {
      await _firestore.collection('processed_videos').doc(video.id).set({
        ...video.toFirestore(),
        'candidateId': candidateId,
      });
      print('Video metadata saved for video: ${video.id}');
    } catch (e) {
      print('Error saving video metadata: $e');
      rethrow;
    }
  }

  Future<void> _saveVideoError(
    String videoId,
    String candidateId,
    String error,
  ) async {
    try {
      await _firestore.collection('processed_videos').doc(videoId).set({
        'id': videoId,
        'candidateId': candidateId,
        'status': 'failed',
        'errorMessage': error,
        'processedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error saving video error: $e');
    }
  }

  Future<void> _updateCandidateManifesto(
    String candidateId,
    ProcessedVideo video,
  ) async {
    try {
      final candidateRef = _firestore.collection('candidates').doc(candidateId);
      final candidateDoc = await candidateRef.get();

      if (candidateDoc.exists) {
        final candidateData = candidateDoc.data() as Map<String, dynamic>;
        final manifesto =
            candidateData['manifesto'] as Map<String, dynamic>? ?? {};

        // Update manifesto with video information
        manifesto['videoUrl'] = video.originalUrl;
        manifesto['videoId'] = video.id;
        manifesto['videoDuration'] = video.duration;
        manifesto['videoThumbnail'] = video.thumbnailUrl;

        await candidateRef.update({
          'manifesto': manifesto,
          'updatedAt': Timestamp.now(),
        });

        print('Candidate manifesto updated with video: ${video.id}');
      }
    } catch (e) {
      print('Error updating candidate manifesto: $e');
      rethrow;
    }
  }

  Future<void> _removeVideoFromCandidateManifesto(
    String candidateId,
    String videoId,
  ) async {
    try {
      final candidateRef = _firestore.collection('candidates').doc(candidateId);
      final candidateDoc = await candidateRef.get();

      if (candidateDoc.exists) {
        final candidateData = candidateDoc.data() as Map<String, dynamic>;
        final manifesto =
            candidateData['manifesto'] as Map<String, dynamic>? ?? {};

        // Remove video information
        manifesto.remove('videoUrl');
        manifesto.remove('videoId');
        manifesto.remove('videoDuration');
        manifesto.remove('videoThumbnail');

        await candidateRef.update({
          'manifesto': manifesto,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error removing video from candidate manifesto: $e');
    }
  }

  Future<void> _deleteFromCloudinary(String videoUrl) async {
    try {
      // Extract public ID from Cloudinary URL
      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;
      final publicId = pathSegments.length > 1
          ? pathSegments.sublist(1).join('/').split('.').first
          : '';

      if (publicId.isNotEmpty) {
        final deleteUrl = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/video/destroy',
        );

        final response = await http.post(
          deleteUrl,
          body: {
            'public_id': publicId,
            'api_key': _apiKey,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        if (response.statusCode == 200) {
          print('Video deleted from Cloudinary: $publicId');
        } else {
          print('Failed to delete from Cloudinary: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
    }
  }

  /// Get video processing statistics
  Future<Map<String, dynamic>> getProcessingStats(String candidateId) async {
    try {
      final videos = await getCandidateVideos(candidateId);

      int totalViews = 0;
      int totalWatchTime = 0;
      final qualityUsage = <String, int>{};
      final deviceUsage = <String, int>{};

      for (final video in videos) {
        totalViews += video.analytics.totalViews;
        totalWatchTime += video.analytics.watchTime;

        video.analytics.qualityViews.forEach((quality, count) {
          qualityUsage[quality] = (qualityUsage[quality] ?? 0) + count;
        });

        video.analytics.deviceStats.forEach((device, count) {
          deviceUsage[device] = (deviceUsage[device] ?? 0) + count;
        });
      }

      return {
        'totalVideos': videos.length,
        'totalViews': totalViews,
        'totalWatchTime': totalWatchTime,
        'averageWatchTime': totalViews > 0 ? totalWatchTime / totalViews : 0,
        'qualityUsage': qualityUsage,
        'deviceUsage': deviceUsage,
        'storageUsed': videos.fold<int>(
          0,
          (sum, video) => sum + video.getFileSize('720p'),
        ),
      };
    } catch (e) {
      print('Error getting processing stats: $e');
      return {};
    }
  }

  /// Batch process multiple videos (for bulk operations)
  Future<List<ProcessedVideo>> batchProcessVideos(
    List<File> videoFiles,
    String candidateId, {
    Function(int, int)? onBatchProgress,
  }) async {
    final processedVideos = <ProcessedVideo>[];

    for (int i = 0; i < videoFiles.length; i++) {
      try {
        final video = await uploadAndProcessVideo(videoFiles[i], candidateId);
        processedVideos.add(video);
        onBatchProgress?.call(i + 1, videoFiles.length);
      } catch (e) {
        print('Error processing video ${i + 1}: $e');
        // Continue with next video
      }
    }

    return processedVideos;
  }
}

/// Extension methods for video processing
extension VideoProcessingExtensions on File {
  /// Get video file information
  Future<Map<String, dynamic>> getVideoInfo() async {
    try {
      // This would use video_compress or similar package
      // For now, return basic file info
      final fileSize = await length();
      final fileSizeMB = fileSize / (1024 * 1024);

      return {
        'fileSize': fileSize,
        'fileSizeMB': fileSizeMB,
        'fileName': uri.pathSegments.last,
        'extension': path.split('.').last.toLowerCase(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// Video processing result
class VideoProcessingResult {
  final bool success;
  final ProcessedVideo? video;
  final String? error;
  final double compressionRatio;

  VideoProcessingResult({
    required this.success,
    this.video,
    this.error,
    this.compressionRatio = 1.0,
  });

  factory VideoProcessingResult.success(
    ProcessedVideo video,
    double compressionRatio,
  ) {
    return VideoProcessingResult(
      success: true,
      video: video,
      compressionRatio: compressionRatio,
    );
  }

  factory VideoProcessingResult.failure(String error) {
    return VideoProcessingResult(success: false, error: error);
  }
}
