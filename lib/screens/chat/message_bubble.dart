import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_model.dart';
import '../../controllers/chat_controller.dart';
import 'poll_dialogs.dart';

class MessageBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDeleted = message.isDeleted ?? false;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            GestureDetector(
              onLongPress: isDeleted ? null : () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDeleted
                      ? Colors.grey.shade200
                      : (isCurrentUser ? const Color(0xFF005C4B) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    topRight: const Radius.circular(8),
                    bottomLeft: isCurrentUser ? const Radius.circular(8) : const Radius.circular(4),
                    bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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

                    // Timestamp and read status in same row
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(message.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDeleted
                                ? Colors.grey.shade500
                                : (isCurrentUser ? Colors.white.withOpacity(0.7) : Colors.grey.shade600),
                          ),
                        ),
                        if (isCurrentUser && !isDeleted) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.readBy.length > 1 ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.readBy.length > 1 ? Colors.lightBlue : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),

                    // Reactions (only show if message is not deleted)
                    if (!isDeleted && message.reactions != null && message.reactions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: message.reactions!.map((reaction) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
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
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    switch (message.type) {
      case 'text':
        return Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.3,
          ),
        );

      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.mediaUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            if (message.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ],
          ],
        );

      case 'audio':
        return Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: textColor,
              ),
              onPressed: () {
                // TODO: Implement audio playback
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Voice message',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        );

      case 'poll':
        return _buildPollContent();

      default:
        return Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.3,
          ),
        );
    }
  }

  Widget _buildPollContent() {
    final pollId = message.metadata?['pollId'] as String?;

    if (pollId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.white.withOpacity(0.1) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrentUser ? Colors.white.withOpacity(0.3) : Colors.blue.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.poll,
              color: isCurrentUser ? Colors.white : Colors.blue.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text.isNotEmpty ? message.text : 'Poll created',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
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
          color: isCurrentUser ? Colors.white.withOpacity(0.1) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrentUser ? Colors.white.withOpacity(0.3) : Colors.blue.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.poll,
                  color: isCurrentUser ? Colors.white : Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.text.replaceFirst('📊 ', ''),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
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
                color: isCurrentUser ? Colors.white.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap to vote on this poll',
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isCurrentUser ? Colors.white.withOpacity(0.7) : Colors.grey.shade400,
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
    final isDeleted = message.isDeleted ?? false;

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
            if (message.senderId == controller.currentUser?.uid && !isDeleted) ...[
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
            const Text('Add Reaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: emojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.addReaction(message.messageId, emoji);
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
        question: message.text.replaceFirst('📊 ', ''),
        currentUserId: controller.currentUser?.uid ?? '',
      ),
    );
  }

  void _reportMessage() {
    controller.reportMessage(message.messageId, 'Reported by user');
  }

  void _deleteMessage() {
    controller.deleteMessage(message.messageId);
  }
}