import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../controllers/chat_controller.dart';

class MessageInput extends StatefulWidget {
  final ChatController controller;
  final TextEditingController textController;
  final VoidCallback onSendMessage;
  final VoidCallback onShowAttachmentOptions;

  const MessageInput({
    super.key,
    required this.controller,
    required this.textController,
    required this.onSendMessage,
    required this.onShowAttachmentOptions,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String? _recordedFilePath;
  bool _showRecordingPreview = false;
  AudioPlayer? _previewPlayer;
  bool _isPreviewPlaying = false;
  Duration _previewPosition = Duration.zero;
  Duration _previewDuration = Duration.zero;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _previewPlayer?.dispose();
    super.dispose();
  }

  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (mounted) {
      setState(() {
        _recordingDuration = Duration.zero;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _initializePreviewPlayer() {
    _previewPlayer = AudioPlayer();

    _previewPlayer?.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPreviewPlaying = state.playing;
        });
      }
    });

    _previewPlayer?.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _previewPosition = position;
        });
      }
    });

    _previewPlayer?.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _previewDuration = duration;
        });
      }
    });
  }

  Future<void> _playPausePreview() async {
    if (_previewPlayer == null || _recordedFilePath == null) return;

    try {
      if (_isPreviewPlaying) {
        await _previewPlayer!.pause();
      } else {
        if (_previewPlayer!.audioSource == null) {
          await _previewPlayer!.setFilePath(_recordedFilePath!);
        }
        await _previewPlayer!.play();
      }
    } catch (e) {
      debugPrint('Error playing preview: $e');
    }
  }

  void _sendRecording() {
    if (_recordedFilePath != null) {
      // The recording is already saved by stopVoiceRecording, just close the preview
      _cancelRecording();
    }
  }

  void _cancelRecording() {
    _previewPlayer?.stop();
    _previewPlayer?.dispose();
    _previewPlayer = null;

    if (_recordedFilePath != null) {
      // Delete the temporary file
      try {
        // Note: In a real app, you might want to delete the file here
        // But for now, we'll just clear the state
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
    }

    setState(() {
      _recordedFilePath = null;
      _showRecordingPreview = false;
      _isPreviewPlaying = false;
      _previewPosition = Duration.zero;
      _previewDuration = Duration.zero;
      _recordingDuration = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240), // Further increased to prevent overflow
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator or preview
          GetBuilder<ChatController>(
            builder: (controller) => controller.isRecording
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic, color: Colors.red, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Recording ${_formatDuration(_recordingDuration)}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : _showRecordingPreview
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.mic,
                                  color: widget.controller.canSendMessage ? Colors.blue.shade600 : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Voice message recorded (${_formatDuration(_recordingDuration)})',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Play/Pause button
                                IconButton(
                                  onPressed: _playPausePreview,
                                  icon: Icon(
                                    _isPreviewPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.blue.shade600,
                                  ),
                                  tooltip: _isPreviewPlaying ? 'Pause' : 'Play',
                                ),

                                // Send button
                                ElevatedButton.icon(
                                  onPressed: widget.controller.canSendMessage ? _sendRecording : null,
                                  icon: const Icon(Icons.send, size: 16),
                                  label: const Text('Send'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),

                                // Delete button
                                IconButton(
                                  onPressed: _cancelRecording,
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete recording',
                                ),
                              ],
                            ),

                            // Progress indicator
                            if (_previewDuration != Duration.zero)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(
                                  value: _previewPosition.inMilliseconds / _previewDuration.inMilliseconds,
                                  backgroundColor: Colors.blue.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
          // Input field with controlled height
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 48, // Minimum height for single line
              maxHeight: 120, // Maximum height before scrolling
            ),
            child: GetBuilder<ChatController>(
              builder: (controller) => TextField(
                controller: widget.textController,
                decoration: InputDecoration(
                  hintText: controller.canSendMessage
                      ? 'Type a message...'
                      : controller.shouldShowWatchAdsButton
                          ? 'Watch ad to earn XP and send messages'
                          : 'Unable to send messages',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  // Character counter for long messages
                  counterText: widget.textController.text.length > 1000
                      ? '${widget.textController.text.length}/4096'
                      : null,
                  counterStyle: TextStyle(
                    fontSize: 12,
                    color: widget.textController.text.length > 3500
                        ? Colors.red
                        : Colors.grey.shade600,
                  ),
                ),
                maxLines: null, // Allow multiple lines
                maxLength: 4096, // WhatsApp-like character limit
                enabled: controller.canSendMessage,
                textInputAction: TextInputAction.newline,
                onChanged: (text) {
                  // Auto-resize logic will be handled by the constraints
                },
              ),
            ),
          ),

          // XP and Quota display row
          GetBuilder<ChatController>(
            builder: (controller) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // XP Points display
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'XP: ${controller.currentUser?.xpPoints ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Chat Quota display
                  Row(
                    children: [
                      const Icon(Icons.message, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Messages: ${controller.remainingMessages}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Premium indicator (if applicable)
                  if (controller.currentUser?.premium == true) ...[
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom row with buttons (always at bottom like WhatsApp)
          Container(
            height: 48, // Fixed height for button row
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Attachment button
                GetBuilder<ChatController>(
                  builder: (controller) => IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: controller.canSendMessage ? null : Colors.grey,
                    ),
                    onPressed: controller.canSendMessage ? widget.onShowAttachmentOptions : null,
                  ),
                ),

                // Voice recording button
                GetBuilder<ChatController>(
                  builder: (controller) => IconButton(
                    icon: Icon(
                      controller.isRecording ? Icons.stop : Icons.mic,
                      color: controller.canSendMessage
                          ? (controller.isRecording ? Colors.red : null)
                          : Colors.grey,
                    ),
                    onPressed: controller.canSendMessage ? _toggleVoiceRecording : null,
                    tooltip: controller.isRecording ? 'Stop recording' : 'Start voice recording',
                  ),
                ),

                // Spacer to push send button to the right
                const Expanded(child: SizedBox()),

                // Send button or Watch Ads button
                GetBuilder<ChatController>(
                  builder: (controller) {
                    if (controller.canSendMessage) {
                      // Show send button when user can send messages
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: controller.isSendingMessage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: controller.isSendingMessage ? null : widget.onSendMessage,
                        ),
                      );
                    } else if (controller.shouldShowWatchAdsButton) {
                      // Show watch ads button when user cannot send but is not premium
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                          onPressed: () => controller.watchRewardedAdForXP(),
                          tooltip: 'Watch ad to earn XP',
                        ),
                      );
                    } else {
                      // Show disabled send button for premium users who somehow can't send
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: null,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVoiceRecording() {
    // Check if user can send message before proceeding
    if (!widget.controller.canSendMessage) {
      Get.snackbar(
        'Cannot Send Message',
        'You have no remaining messages or XP. Please watch an ad to earn XP.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (widget.controller.isRecording) {
      _stopRecordingTimer();
      // Instead of immediately sending, show preview
      _showRecordingPreviewInterface();
    } else {
      _startRecordingTimer();
      widget.controller.startVoiceRecording();
    }
  }

  void _showRecordingPreviewInterface() {
    // Get the recorded file path from controller
    final recordedPath = widget.controller.currentRecordingPath;
    if (recordedPath != null) {
      setState(() {
        _recordedFilePath = recordedPath;
        _showRecordingPreview = true;
      });
      _initializePreviewPlayer();
    }
  }
}