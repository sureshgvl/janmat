import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({super.key, required this.chatRoom});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatController controller = Get.find<ChatController>();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }


  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            // Room avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRoomColor(widget.chatRoom),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getRoomIcon(widget.chatRoom),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Room info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main title (City name for ward rooms)
                  Text(
                    _getRoomDisplayTitle(widget.chatRoom),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Subtitle (Ward name or description)
                  Text(
                    _getRoomDisplaySubtitle(widget.chatRoom),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () => _showRoomOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: GetBuilder<ChatController>(
              builder: (controller) {
                final messages = controller.messages;
                if (messages.isEmpty) {
                  _previousMessageCount = 0;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation in ${widget.chatRoom.title ?? _getDefaultRoomTitle(widget.chatRoom)}',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Check if messages increased (new message received)
                if (messages.length > _previousMessageCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
                _previousMessageCount = messages.length;

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == controller.currentUser?.uid;
                    return _buildMessageBubble(message, isCurrentUser);
                  },
                );
              },
            ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
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
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser ? const Color(0xFF005C4B) : Colors.white,
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
                    _buildMessageContent(message, isCurrentUser),

                    // Timestamp and read status in same row
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeago.format(message.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrentUser ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.readBy.length > 1 ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.readBy.length > 1 ? Colors.lightBlue : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),

                    // Reactions
                    if (message.reactions != null && message.reactions!.isNotEmpty)
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

  Widget _buildMessageContent(Message message, bool isCurrentUser) {
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => _showAttachmentOptions(),
          ),

          // Voice recording button
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => _toggleVoiceRecording(),
          ),

          // Text input
          Expanded(
            child: GetBuilder<ChatController>(
              builder: (controller) => TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: controller.canSendMessage
                      ? 'Type a message...'
                      : 'Watch ad to send more messages',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                enabled: controller.canSendMessage,
              ),
            ),
          ),

          // Send button
          const SizedBox(width: 8),
          GetBuilder<ChatController>(
            builder: (controller) => Container(
              decoration: BoxDecoration(
                color: controller.canSendMessage ? Colors.blue : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: controller.canSendMessage ? _sendMessage : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = messageController.text.trim();
    if (text.isNotEmpty) {
      controller.sendTextMessage(text);
      messageController.clear();
      _scrollToBottom();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Send Image'),
              onTap: () {
                Get.back();
                controller.sendImageMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: const Text('Create Poll'),
              onTap: () {
                Get.back();
                _showCreatePollDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVoiceRecording() {
    // TODO: Implement voice recording
    Get.snackbar('Coming Soon', 'Voice recording will be available soon!');
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('Add Reaction'),
              onTap: () {
                Get.back();
                _showEmojiPicker(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Message'),
              onTap: () {
                Get.back();
                _reportMessage(message);
              },
            ),
            if (message.senderId == controller.currentUser?.uid) ...[
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Message'),
                onTap: () {
                  Get.back();
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(Message message) {
    // TODO: Implement emoji picker
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
                    Get.back();
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

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    final optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Poll'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              const SizedBox(height: 16),
              ...List.generate(optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: optionControllers[index],
                    decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                  ),
                );
              }),
              TextButton(
                onPressed: () {
                  setState(() {
                    optionControllers.add(TextEditingController());
                  });
                },
                child: const Text('Add Option'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final question = questionController.text.trim();
              final options = optionControllers
                  .map((c) => c.text.trim())
                  .where((text) => text.isNotEmpty)
                  .toList();

              if (question.isNotEmpty && options.length >= 2) {
                controller.createPoll(question, options);
                Get.back();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRoomOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Room Info'),
              onTap: () {
                Get.back();
                _showRoomInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Leave Room'),
              onTap: () {
                Get.back();
                _leaveRoom();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.chatRoom.title ?? _getDefaultRoomTitle(widget.chatRoom)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${widget.chatRoom.type == 'public' ? 'Public' : 'Private'}'),
            if (widget.chatRoom.description != null)
              Text('Description: ${widget.chatRoom.description}'),
            Text('Created: ${timeago.format(widget.chatRoom.createdAt)}'),
            if (widget.chatRoom.members != null)
              Text('Members: ${widget.chatRoom.members!.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _leaveRoom() {
    controller.clearCurrentChat();
    Get.back();
  }

  void _reportMessage(Message message) {
    // TODO: Implement message reporting
    Get.snackbar('Reported', 'Message has been reported to moderators');
  }

  void _deleteMessage(Message message) {
    // TODO: Implement message deletion
    Get.snackbar('Deleted', 'Message deleted');
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Helper methods for WhatsApp-style display
  Color _getRoomColor(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return Colors.blue.shade600; // Blue for ward chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Colors.green.shade600; // Green for candidate chats
    } else {
      return Colors.purple.shade600; // Purple for other chats
    }
  }

  IconData _getRoomIcon(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return Icons.location_city; // City icon for ward chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Icons.person; // Person icon for candidate chats
    } else {
      return Icons.group; // Group icon for other chats
    }
  }

  String _getRoomDisplayTitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, title is the city name
      return chatRoom.title ?? 'City Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, title is candidate name
      return chatRoom.title ?? 'Candidate Chat';
    } else {
      return chatRoom.title ?? chatRoom.roomId;
    }
  }

  String _getRoomDisplaySubtitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, subtitle is the ward name
      return chatRoom.description ?? 'Ward Discussion';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, subtitle is description
      return chatRoom.description ?? 'Official Updates';
    } else {
      return chatRoom.description ?? 'Group Chat';
    }
  }

  String _getDefaultRoomTitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return 'Ward ${chatRoom.roomId.replaceAll('ward_', '')} Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return 'Candidate Discussion';
    } else {
      return chatRoom.roomId;
    }
  }
}