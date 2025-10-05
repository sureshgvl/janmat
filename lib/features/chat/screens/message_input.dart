import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/chat_controller.dart';
import '../../../l10n/features/chat/chat_translations.dart';

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

  // Typing status
  Timer? _typingTimer;
  bool _isTyping = false;

  // Debug logging state tracking
  bool _lastIsSending = false;
  bool _lastCanSend = true;
  bool _lastShouldShowAds = false;

  @override
  void initState() {
    super.initState();
    // Set up typing listener
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _typingTimer?.cancel();
    _previewPlayer?.dispose();
    // Stop typing when leaving
    _updateTypingStatus(false);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.textController.text.trim();
    final shouldBeTyping = text.isNotEmpty;

    if (shouldBeTyping != _isTyping) {
      _isTyping = shouldBeTyping;
      _updateTypingStatus(_isTyping);

      if (_isTyping) {
        // Start timer to stop typing after 3 seconds of inactivity
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (_isTyping) {
            _isTyping = false;
            _updateTypingStatus(false);
          }
        });
      }
    } else if (_isTyping) {
      // Reset the timer when still typing
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (_isTyping) {
          _isTyping = false;
          _updateTypingStatus(false);
        }
      });
    }
  }

  void _updateTypingStatus(bool isTyping) {
    widget.controller.updateTypingStatus(isTyping);
  }

  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + 1,
          );
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

  Future<void> _sendRecording() async {
    if (_recordedFilePath != null) {
      debugPrint(
        '📤 UI DEBUG: Sending recorded voice message: $_recordedFilePath',
      );

      try {
        // Stop preview playback if playing
        if (_isPreviewPlaying) {
          await _previewPlayer?.pause();
        }

        // Send the recorded message
        await widget.controller.sendRecordedVoiceMessage(_recordedFilePath!);

        // Close the preview interface
        _closeRecordingPreview();

        debugPrint('✅ UI DEBUG: Voice message sent successfully');
      } catch (e) {
        debugPrint('❌ UI DEBUG: Failed to send voice message: $e');
        // Don't close preview on error so user can try again
      }
    }
  }

  void _cancelRecording() {
    debugPrint('🗑️ UI DEBUG: Cancelling voice recording');

    // Stop preview playback
    _previewPlayer?.stop();
    _previewPlayer?.dispose();
    _previewPlayer = null;

    if (_recordedFilePath != null) {
      // Delete the temporary file
      try {
        final file = File(_recordedFilePath!);
        if (file.existsSync()) {
          file.deleteSync();
          debugPrint(
            '🗑️ UI DEBUG: Deleted temporary recording file: $_recordedFilePath',
          );
        }
      } catch (e) {
        debugPrint('⚠️ UI DEBUG: Error deleting temp file: $e');
      }
    }

    _closeRecordingPreview();
  }

  void _closeRecordingPreview() {
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
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.4, // Responsive max height
        minHeight: 48, // Minimum height for input field
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording indicator or preview
            GetBuilder<ChatController>(
              builder: (controller) => controller.isRecording
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
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
                            ChatTranslations.recording(_formatDuration(_recordingDuration)),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      constraints: const BoxConstraints(
                        maxHeight: 120,
                      ), // Limit height
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with duration
                          Row(
                            children: [
                              Icon(
                                Icons.mic,
                                color: widget.controller.canSendMessage
                                    ? Colors.blue.shade600
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ChatTranslations.voiceMessage(_formatDuration(_recordingDuration)),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Progress and controls
                          if (_previewDuration != Duration.zero) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value:
                                  _previewPosition.inMilliseconds /
                                  _previewDuration.inMilliseconds,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                          ],

                          // Control buttons
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Play/Pause button
                              IconButton(
                                onPressed: _playPausePreview,
                                icon: Icon(
                                  _isPreviewPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: _isPreviewPlaying ? ChatTranslations.pause : ChatTranslations.play,
                              ),

                              // Send button
                              ElevatedButton.icon(
                                onPressed: widget.controller.canSendMessage
                                    ? _sendRecording
                                    : null,
                                icon: const Icon(Icons.send, size: 14),
                                label: Text(
                                  ChatTranslations.send,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(70, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),

                              // Delete button
                              IconButton(
                                onPressed: _cancelRecording,
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: ChatTranslations.deleteRecording,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // Input field with responsive height
            GetBuilder<ChatController>(
              builder: (controller) => TextField(
                controller: widget.textController,
                decoration: InputDecoration(
                  hintText: controller.canSendMessage
                      ? ChatTranslations.typeMessage
                      : controller.shouldShowWatchAdsButton
                      ? ChatTranslations.watchAdToEarnXP
                      : ChatTranslations.unableToSendMessages,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                maxLines: 4, // Limit to 4 lines to prevent excessive height
                minLines: 1,
                maxLength: 4096, // WhatsApp-like character limit
                enabled: controller.canSendMessage,
                textInputAction: TextInputAction.newline,
              ),
            ),

            // XP and Quota display row
            GetBuilder<ChatController>(
              builder: (controller) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    // XP Points display
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          ChatTranslations.xpPoints((controller.currentUser?.xpPoints ?? 0).toString()),
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
                          ChatTranslations.messagesCount(controller.remainingMessages.toString()),
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
                          const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ChatTranslations.premium,
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
                      onPressed: controller.canSendMessage
                          ? widget.onShowAttachmentOptions
                          : null,
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
                      onPressed: controller.canSendMessage
                          ? _toggleVoiceRecording
                          : null,
                      tooltip: controller.isRecording
                          ? ChatTranslations.stopRecording
                          : ChatTranslations.startVoiceRecording,
                    ),
                  ),

                  // Spacer to push send button to the right
                  const Expanded(child: SizedBox()),

                  // Send button or Watch Ads button
                  Obx(() {
                    final controller = Get.find<ChatController>();
                    final isSending = controller.isSendingMessage.value;
                    final canSend = controller.canSendMessage;
                    final shouldShowAds = controller.shouldShowWatchAdsButton;

                    // Only log when state actually changes to avoid spam
                    if (_lastIsSending != isSending || _lastCanSend != canSend || _lastShouldShowAds != shouldShowAds) {
                      debugPrint('🔄 MessageInput: State changed - isSendingMessage: $isSending, canSend: $canSend, shouldShowAds: $shouldShowAds');
                      _lastIsSending = isSending;
                      _lastCanSend = canSend;
                      _lastShouldShowAds = shouldShowAds;
                    }

                    if (canSend) {
                      // Show send button when user can send messages
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          key: ValueKey('send_button_$isSending'), // Force rebuild with unique key
                          icon: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: isSending
                              ? () {
                                  debugPrint('🚫 MessageInput: Send button pressed but disabled (sending in progress)');
                                  null;
                                }
                              : () {
                                  debugPrint('📤 MessageInput: Send button pressed - calling onSendMessage');
                                  widget.onSendMessage();
                                },
                        ),
                      );
                    } else if (shouldShowAds) {
                      // Show watch ads button when user cannot send but is not premium
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                          ),
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
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVoiceRecording() async {
    // Check if user can send message before proceeding
    if (!widget.controller.canSendMessage) {
      Get.snackbar(
        ChatTranslations.cannotSendMessage,
        ChatTranslations.noMessagesOrXP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (widget.controller.isRecording) {
      debugPrint('🎙️ UI DEBUG: Stopping voice recording for preview...');
      _stopRecordingTimer();

      try {
        // Stop recording but don't send yet - show preview instead
        final recordingPath = await widget.controller.stopVoiceRecordingOnly();
        debugPrint('✅ UI DEBUG: Voice recording stopped, path: $recordingPath');

        if (recordingPath != null) {
          // Show preview interface
          _showRecordingPreviewInterface(recordingPath);
        } else {
          Get.snackbar(
            ChatTranslations.recordingError,
            ChatTranslations.failedToSaveRecording,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (e) {
        debugPrint('❌ UI DEBUG: Failed to stop voice recording: $e');
        Get.snackbar(
          ChatTranslations.recordingError,
          ChatTranslations.failedToStopRecording,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        );
      }
    } else {
      debugPrint('🎙️ UI DEBUG: Starting voice recording...');
      _startRecordingTimer();
      await widget.controller.startVoiceRecording();
      debugPrint('✅ UI DEBUG: Voice recording started successfully');
    }
  }

  void _showRecordingPreviewInterface(String? recordingPath) {
    // Use provided path or get from controller
    final recordedPath =
        recordingPath ?? widget.controller.currentRecordingPath;
    if (recordedPath != null) {
      debugPrint('🎵 UI DEBUG: Showing recording preview for: $recordedPath');
      setState(() {
        _recordedFilePath = recordedPath;
        _showRecordingPreview = true;
        _recordingDuration = Duration.zero; // Reset for new recording
      });
      _initializePreviewPlayer();
    } else {
      debugPrint('⚠️ UI DEBUG: No recording path available for preview');
    }
  }
}

