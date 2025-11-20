import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
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

    // Trigger rebuild whenever text changes so button state updates immediately
    setState(() {});
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
      AppLogger.chat('Error playing preview: $e');
    }
  }

  Future<void> _sendRecording() async {
    if (_recordedFilePath != null) {
      AppLogger.chat(
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

        AppLogger.chat('✅ UI DEBUG: Voice message sent successfully');
      } catch (e) {
        AppLogger.chat('❌ UI DEBUG: Failed to send voice message: $e');
        // Don't close preview on error so user can try again
      }
    }
  }

  void _cancelRecording() {
    AppLogger.chat('🗑️ UI DEBUG: Cancelling voice recording');

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
          AppLogger.chat(
            '🗑️ UI DEBUG: Deleted temporary recording file: $_recordedFilePath',
          );
        }
      } catch (e) {
        AppLogger.chat('⚠️ UI DEBUG: Error deleting temp file: $e');
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator or preview (compact)
          GetBuilder<ChatController>(
            builder: (controller) => controller.isRecording || _showRecordingPreview
                ? Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: Colors.blue.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.isRecording
                              ? ChatTranslations.recording(_formatDuration(_recordingDuration))
                              : ChatTranslations.voiceMessage(_formatDuration(_recordingDuration)),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        // Quick actions for recording preview
                        if (_showRecordingPreview) ...[
                          IconButton(
                            onPressed: _playPausePreview,
                            icon: Icon(
                              _isPreviewPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.blue.shade600,
                              size: 18,
                            ),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          IconButton(
                            onPressed: _sendRecording,
                            icon: const Icon(Icons.send, color: Colors.blue, size: 18),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          IconButton(
                            onPressed: _cancelRecording,
                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ] else if (controller.isRecording) ...[
                          IconButton(
                            onPressed: () => _toggleVoiceRecording(),
                            icon: const Icon(Icons.stop, color: Colors.red, size: 18),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Single row with text input and buttons (WhatsApp style)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: GetBuilder<ChatController>(
                  builder: (controller) => IconButton(
                    icon: const Icon(Icons.add, size: 24),
                    color: controller.canSendMessage ? Colors.grey.shade600 : Colors.grey.shade400,
                    onPressed: controller.canSendMessage
                        ? widget.onShowAttachmentOptions
                        : null,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),

              // Text input field (expands to fill space)
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    maxHeight: 100, // Allow up to ~3-4 lines
                  ),
                  child: GetBuilder<ChatController>(
                    builder: (controller) => TextField(
                      controller: widget.textController,
                      decoration: InputDecoration(
                        hintText: controller.canSendMessage
                            ? ChatTranslations.typeMessage
                            : controller.shouldShowWatchAdsButton
                            ? ChatTranslations.watchAdToEarnXP
                            : ChatTranslations.unableToSendMessages,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        // Character counter (removed)
                        counterText: null,
                      ),
                      maxLines: null, // Allow multiple lines
                      minLines: 1,
                      // maxLength: 4096, // Removed to hide character counter
                      enabled: controller.canSendMessage,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button or voice/camera button
              Obx(() {
                final controller = Get.find<ChatController>();
                final hasText = widget.textController.text.trim().isNotEmpty;
                final canSend = controller.canSendMessage;
                final isSending = controller.isSendingMessage.value;
                final shouldShowAds = controller.shouldShowWatchAdsButton;

                // Only log when state actually changes
                if (_lastIsSending != isSending || _lastCanSend != canSend || _lastShouldShowAds != shouldShowAds) {
                  AppLogger.chat('🔄 MessageInput: State changed - hasText: $hasText, isSending: $isSending, canSend: $canSend, shouldShowAds: $shouldShowAds');
                  _lastIsSending = isSending;
                  _lastCanSend = canSend;
                  _lastShouldShowAds = shouldShowAds;
                }

                // ALWAYS show send button when there's text, regardless of quota
                if (hasText) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0084FF), // WhatsApp blue
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      key: ValueKey('send_button_$isSending'),
                      icon: isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: isSending ? null : () {
                        AppLogger.chat('📤 MessageInput: Send button clicked');
                        widget.onSendMessage();
                      },
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      tooltip: 'Send message',
                    ),
                  );
                }
                // Only show recording voice button if user can send messages
                else if (canSend) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: IconButton(
                      icon: Icon(
                        controller.isRecording ? Icons.stop : Icons.mic,
                        color: controller.isRecording ? Colors.red : Colors.grey.shade600,
                        size: 24,
                      ),
                      onPressed: _toggleVoiceRecording,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      tooltip: controller.isRecording
                          ? ChatTranslations.stopRecording
                          : ChatTranslations.startVoiceRecording,
                    ),
                  );
                } else if (shouldShowAds) {
                  // Show watch ads button when user cannot send but is not premium
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                      onPressed: () => controller.watchRewardedAdForXP(),
                      tooltip: 'Watch ad to earn XP',
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  );
                } else {
                  // Show disabled microphone when user absolutely cannot send
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.grey, size: 24),
                      onPressed: null,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      tooltip: 'Cannot send messages - upgrade to premium',
                    ),
                  );
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleVoiceRecording() async {
    // Check if user can send message before proceeding
    if (!widget.controller.canSendMessage) {
      SnackbarUtils.showError(ChatTranslations.noMessagesOrXP);
      return;
    }

    if (widget.controller.isRecording) {
      AppLogger.chat('🎙️ UI DEBUG: Stopping voice recording for preview...');
      _stopRecordingTimer();

      try {
        // Stop recording but don't send yet - show preview instead
        final recordingPath = await widget.controller.stopVoiceRecordingOnly();
        AppLogger.chat('✅ UI DEBUG: Voice recording stopped, path: $recordingPath');

        if (recordingPath != null) {
          // Show preview interface
          _showRecordingPreviewInterface(recordingPath);
        } else {
          SnackbarUtils.showError(ChatTranslations.failedToSaveRecording);
        }
      } catch (e) {
        AppLogger.chat('❌ UI DEBUG: Failed to stop voice recording: $e');
        SnackbarUtils.showError(ChatTranslations.failedToStopRecording);
      }
    } else {
      AppLogger.chat('🎙️ UI DEBUG: Starting voice recording...');
      _startRecordingTimer();
      await widget.controller.startVoiceRecording();
      AppLogger.chat('✅ UI DEBUG: Voice recording started successfully');
    }
  }

  void _showRecordingPreviewInterface(String? recordingPath) {
    // Use provided path or get from controller
    final recordedPath =
        recordingPath ?? widget.controller.currentRecordingPath;
    if (recordedPath != null) {
      AppLogger.chat('🎵 UI DEBUG: Showing recording preview for: $recordedPath');
      setState(() {
        _recordedFilePath = recordedPath;
        _showRecordingPreview = true;
        _recordingDuration = Duration.zero; // Reset for new recording
      });
      _initializePreviewPlayer();
    } else {
      AppLogger.chat('⚠️ UI DEBUG: No recording path available for preview');
    }
  }
}
