import 'dart:io';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../utils/app_logger.dart';

/// Handles voice recording functionality
class VoiceRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  var isRecording = false.obs;
  String? currentRecordingPath;

  /// Start voice recording
  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory(
          path.join(appDir.path, 'voice_recordings'),
        );

        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }

        final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
        currentRecordingPath = path.join(recordingsDir.path, fileName);

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: currentRecordingPath!);
        isRecording.value = true;

        AppLogger.chat(
          'VoiceRecorderService: Started voice recording: $currentRecordingPath',
        );
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      AppLogger.chat('VoiceRecorderService: Failed to start voice recording: $e');
      isRecording.value = false;
      rethrow;
    }
  }

  /// Stop voice recording
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      isRecording.value = false;

      if (path != null) {
        AppLogger.chat('VoiceRecorderService: Stopped voice recording: $path');
        return path;
      } else {
        AppLogger.chat(
          'VoiceRecorderService: Voice recording failed - no path returned',
        );
        return null;
      }
    } catch (e) {
      AppLogger.chat('VoiceRecorderService: Failed to stop voice recording: $e');
      isRecording.value = false;
      return null;
    }
  }

  /// Check if currently recording
  bool get isCurrentlyRecording => isRecording.value;

  /// Get current recording path
  String? get currentPath => currentRecordingPath;

  /// Clean up resources
  void dispose() {
    _audioRecorder.dispose();
  }
}
