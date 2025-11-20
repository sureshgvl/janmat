import 'package:flutter/material.dart';
import 'package:janmat/features/chat/models/chat_message.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import '../../../utils/app_logger.dart';
import '../controllers/chat_controller.dart';
import '../../common/reusable_image_widget.dart';
import '../widgets/poll_dialog_widget.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final ChatController controller;
  final BuildContext context;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.controller,
    required this.context,
  });

  @override
  MessageBubbleState createState() => MessageBubbleState();
}

class MessageBubbleState extends State<MessageBubble> {
  Map<String, dynamic>? _senderInfo;
  bool _isLoadingSenderInfo = false;

  // Audio playback state
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    // Only fetch sender info if this is not the current user's message
    if (!widget.isCurrentUser) {
      _loadSenderInfo();
    }
    // Initialize audio player for audio messages
    if (widget.message.type == 'audio') {
      _initializeAudioPlayer();
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadSenderInfo() async {
    if (_isLoadingSenderInfo) return;

    setState(() {
      _isLoadingSenderInfo = true;
    });

    try {
      final senderInfo = await widget.controller.getSenderInfo(
        widget.message.senderId,
      );
      if (mounted) {
        setState(() {
          _senderInfo = senderInfo;
          _isLoadingSenderInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSenderInfo = false;
        });
      }
    }
  }

  void _initializeAudioPlayer() {
    _audioPlayer = AudioPlayer();

    // Listen to player state changes
    _audioPlayer?.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listen to position changes
    _audioPlayer?.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer?.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });
  }

  Future<void> _playPauseAudio() async {
    if (_audioPlayer == null || widget.message.mediaUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        if (_audioPlayer!.audioSource == null) {
          setState(() {
            _isLoadingAudio = true;
          });

          // Use local media path if available, otherwise remote URL
          final mediaUrl = widget.controller.getMediaUrl(
            widget.message.messageId,
            widget.message.mediaUrl,
          );
          if (mediaUrl != null) {
            await _audioPlayer!.setUrl(mediaUrl);
          }

          setState(() {
            _isLoadingAudio = false;
          });
        }

        await _audioPlayer!.play();
      }
    } catch (e) {
      AppLogger.ui('Error playing audio: $e', tag: 'CHAT');
      setState(() {
        _isLoadingAudio = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildReadReceiptIndicator() {
    final readCount = widget.message.readBy.length;

    if (readCount <= 1) {
      // Single checkmark for sent but not read
      return Icon(
        Icons.done,
        size: 14,
        color: Colors.grey.shade600,
      );
    } else {
      // Double checkmark for read by others
      return Tooltip(
        message: 'Read by ${readCount - 1} ${readCount - 1 == 1 ? 'person' : 'people'}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.done_all,
              size: 14,
              color: Colors.lightBlue,
            ),
            if (readCount > 2) ...[
              const SizedBox(width: 2),
              Text(
                '${readCount - 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.lightBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.message.isDeleted ?? false;

    return Align(
      alignment: widget.isCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: widget.isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender info (only for non-current user messages)
            if (!widget.isCurrentUser && _senderInfo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Role indicator for candidates
                    if (_senderInfo!['role'] == 'candidate')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CANDIDATE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    // Sender name
                    Text(
                      _senderInfo!['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    // Phone number (only visible to candidates for moderation)
                    if (widget.controller.currentUser?.role == 'candidate' &&
                        _senderInfo!['phone'] != null &&
                        _senderInfo!['phone'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '(${_senderInfo!['phone']})',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Message bubble
            GestureDetector(
              onLongPress: isDeleted
                  ? null
                  : () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDeleted
                      ? Colors.grey.shade200
                      : (widget.isCurrentUser
                            ? const Color(0xFFDCF8C6)
                            : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    topRight: const Radius.circular(8),
                    bottomLeft: widget.isCurrentUser
                        ? const Radius.circular(8)
                        : const Radius.circular(4),
                    bottomRight: widget.isCurrentUser
                        ? const Radius.circular(4)
                        : const Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    isDeleted
                        ? Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'This message was deleted',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : _buildMessageContent(),

                    // Timestamp and status indicators in same row
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(widget.message.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDeleted
                                ? Colors.grey.shade500
                                : (widget.isCurrentUser
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade600),
                          ),
                        ),
                        if (widget.isCurrentUser && !isDeleted) ...[
                          const SizedBox(width: 4),
                          // Show message status indicators
                          if (widget.message.status ==
                              MessageStatus.sending) ...[
                            const SizedBox(width: 2),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey,
                                ),
                              ),
                            ),
                          ] else if (widget.message.status ==
                              MessageStatus.failed) ...[
                            const SizedBox(width: 2),
                            GestureDetector(
                              onTap: () => widget.controller.retryMessage(
                                widget.message.messageId,
                              ),
                              child: Icon(
                                Icons.refresh,
                                size: 14,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ] else ...[
                            // Enhanced read receipts
                            _buildReadReceiptIndicator(),
                          ],
                        ],
                      ],
                    ),

                    // Reactions (only show if message is not deleted)
                    if (!isDeleted &&
                        widget.message.reactions != null &&
                        widget.message.reactions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: widget.message.reactions!.map((reaction) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isCurrentUser
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                reaction.emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    final textColor = widget.isCurrentUser ? Colors.black87 : Colors.black87;

    switch (widget.message.type) {
      case 'text':
        return _buildTextMessage(widget.message.text, textColor);

      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message.mediaUrl != null) ...[
              () {
                final mediaUrl = widget.controller.getMediaUrl(
                  widget.message.messageId,
                  widget.message.mediaUrl,
                )!;

                // Determine if the URL is local (file path) or remote (HTTP URL)
                final isLocalImage = !mediaUrl.startsWith('http');

                return ReusableImageWidget(
                  imageUrl: isLocalImage ? 'local:$mediaUrl' : mediaUrl,
                  isLocal: isLocalImage,
                  fit: BoxFit.cover,
                  maxWidth: 200,
                  maxHeight: 200,
                  borderRadius: BorderRadius.circular(8),
                  enableFullScreenView: true,
                  fullScreenTitle: 'Chat Image',
                );
              }(),
            ],
            if (widget.message.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.message.text,
                style: TextStyle(color: textColor, fontSize: 16, height: 1.3),
              ),
            ],
          ],
        );

      case 'audio':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isCurrentUser
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause button
              IconButton(
                icon: _isLoadingAudio
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.isCurrentUser
                            ? Colors.green.shade700
                            : Colors.blue.shade600,
                        size: 24,
                      ),
                onPressed: _playPauseAudio,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              // Waveform visualization (simplified)
              Container(
                width: 60,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    8,
                    (index) => Container(
                      width: 2,
                      height: _isPlaying ? (8 + (index % 3) * 4).toDouble() : 4,
                      decoration: BoxDecoration(
                        color: widget.isCurrentUser
                            ? Colors.green.shade400
                            : Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),

              // Duration display
              Text(
                _audioDuration != Duration.zero
                    ? '${_formatDuration(_currentPosition)} / ${_formatDuration(_audioDuration)}'
                    : 'Voice message',
                style: TextStyle(
                  color: widget.isCurrentUser
                      ? Colors.green.shade700
                      : Colors.blue.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

      case 'poll':
        return _buildPollContent();

      default:
        return Text(
          widget.message.text,
          style: TextStyle(color: textColor, fontSize: 16, height: 1.3),
        );
    }
  }

  Widget _buildPollContent() {
    final pollId = widget.message.metadata?['pollId'] as String?;

    if (pollId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isCurrentUser
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isCurrentUser
                ? Colors.grey.shade300
                : Colors.blue.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.poll,
              color: widget.isCurrentUser
                  ? Colors.black87
                  : Colors.blue.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message.text.isNotEmpty
                    ? widget.message.text
                    : 'Poll created',
                style: TextStyle(
                  color: widget.isCurrentUser ? Colors.black87 : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showPollVotingDialog(pollId),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isCurrentUser
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isCurrentUser
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.blue.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.poll,
                  color: widget.isCurrentUser
                      ? Colors.black87
                      : Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message.text.replaceFirst('📊 ', ''),
                    style: TextStyle(
                      color: widget.isCurrentUser
                          ? Colors.black87
                          : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isCurrentUser
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tap to vote on this poll',
                          style: TextStyle(
                            color: widget.isCurrentUser
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'May have expiration settings',
                          style: TextStyle(
                            color: widget.isCurrentUser
                                ? Colors.grey.shade600
                                : Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.isCurrentUser
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isDeleted = widget.message.isDeleted ?? false;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.add_reaction),
                title: const Text('Add Reaction'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEmojiPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report Message'),
                onTap: () {
                  Navigator.of(context).pop();
                  _reportMessage();
                },
              ),
            ],
            if (widget.message.senderId == widget.controller.currentUser?.uid &&
                !isDeleted) ...[
              // Show retry option for failed messages
              if (widget.message.status == MessageStatus.failed) ...[
                ListTile(
                  leading: Icon(Icons.refresh, color: Colors.red.shade600),
                  title: const Text('Retry Send'),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.controller.retryMessage(widget.message.messageId);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteMessage();
                },
              ),
            ],
            if (isDeleted) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This message has been deleted',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Reaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: emojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.controller.addReaction(
                      widget.message.messageId,
                      emoji,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showPollVotingDialog(String pollId) {
    showDialog(
      context: context,
      builder: (context) => PollVotingDialog(
        pollId: pollId,
        question: widget.message.text.replaceFirst('📊 ', ''),
        currentUserId: widget.controller.currentUser?.uid ?? '',
      ),
    ).then((_) {
      // Refresh messages to show updated poll results
      widget.controller.refreshCurrentChatMessages();
    });
  }

  void _reportMessage() {
    widget.controller.reportMessage(
      widget.message.messageId,
      'Reported by user',
    );
  }

  void _deleteMessage() {
    widget.controller.deleteMessage(widget.message.messageId);
  }

  Widget _buildTextMessage(String text, Color textColor) {
    const int maxLength = 500; // WhatsApp-like truncation length
    final bool isLongMessage = text.length > maxLength;

    if (!isLongMessage) {
      return Linkify(
        text: text,
        style: TextStyle(color: textColor, fontSize: 16, height: 1.3),
        linkStyle: TextStyle(
          color: Colors.blue.shade600,
          fontSize: 16,
          height: 1.3,
          decoration: TextDecoration.underline,
        ),
        onOpen: (link) async {
          if (await canLaunchUrl(Uri.parse(link.url))) {
            await launchUrl(
              Uri.parse(link.url),
              mode: LaunchMode.externalApplication,
            );
          }
        },
      );
    }

    // For long messages, show truncated version with "Read more"
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Linkify(
          text: '${text.substring(0, maxLength)}...',
          style: TextStyle(color: textColor, fontSize: 16, height: 1.3),
          linkStyle: TextStyle(
            color: Colors.blue.shade600,
            fontSize: 16,
            height: 1.3,
            decoration: TextDecoration.underline,
          ),
          onOpen: (link) async {
            if (await canLaunchUrl(Uri.parse(link.url))) {
              await launchUrl(
                Uri.parse(link.url),
                mode: LaunchMode.externalApplication,
              );
            }
          },
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showFullMessage(text),
          child: Text(
            'Read more',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullMessage(String fullText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Message'),
        content: SingleChildScrollView(
          child: Linkify(
            text: fullText,
            style: const TextStyle(fontSize: 16, height: 1.4),
            linkStyle: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 16,
              height: 1.4,
              decoration: TextDecoration.underline,
            ),
            onOpen: (link) async {
              if (await canLaunchUrl(Uri.parse(link.url))) {
                await launchUrl(
                  Uri.parse(link.url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
