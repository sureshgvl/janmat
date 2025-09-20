import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../l10n/app_localizations.dart';
import '../controllers/chat_controller.dart';
import '../controllers/message_controller.dart';
import '../../../models/chat_model.dart';
import 'message_bubble.dart';
import 'message_input.dart';
import '../widgets/poll_dialog_widget.dart';
import 'chat_room_helpers.dart';

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
    // Select the chat room when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectChatRoom(widget.chatRoom);
      _scrollToBottom();
      _markVisibleMessagesAsRead();
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
            // Room info or user info for private chats
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _getHeaderInfo(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main title (User name for private chats, room name for public)
                        Text(
                          data['title'] ??
                              _getRoomDisplayTitle(widget.chatRoom),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Subtitle (Phone for private chats, description for public)
                        Text(
                          data['subtitle'] ??
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
                    );
                  } else {
                    // Fallback to room info
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                    );
                  }
                },
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
          // Messages list - Use MessageController directly for immediate updates
          Expanded(
            child: GetBuilder<MessageController>(
              builder: (messageController) {
                return Obx(() {
                  debugPrint(
                    '🔄 ChatRoomScreen: Rebuilding with ${messageController.messages.length} messages',
                  );
                  final messages = messageController.messages;

                  // Show loading indicator only when we're actively loading and have no cached data
                  if (messages.isEmpty && controller.isLoading.value) {
                    _previousMessageCount = 0;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.loadingMessages,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show empty state if messages are loaded but empty (not loading anymore)
                  if (messages.isEmpty && !controller.isLoading.value) {
                    _previousMessageCount = 0;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noMessagesYet,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.startConversation(
                              widget.chatRoom.title ??
                                  _getDefaultRoomTitle(widget.chatRoom),
                            ),
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
                      final isCurrentUser =
                          message.senderId == controller.currentUser?.uid;

                      debugPrint(
                        '🔄 ChatRoomScreen: Rendering message ${index + 1}/${messages.length} - ID: ${message.messageId}, Text: "${message.text}", Sender: ${message.senderId}, Status: ${message.status}',
                      );

                      return _buildMessageBubble(message, isCurrentUser);
                    },
                  );
                });
              },
            ),
          ),

          // Typing indicators
          _buildTypingIndicators(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicators() {
    return GetBuilder<ChatController>(
      builder: (controller) {
        final typingUsers = controller.typingStatuses
            .where((status) => status.userId != controller.currentUser?.uid)
            .toList();

        if (typingUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        final typingNames = typingUsers
            .map((status) => status.userName ?? 'Someone')
            .toList();

        String typingText;
        if (typingNames.length == 1) {
          typingText = '${typingNames[0]} is typing...';
        } else if (typingNames.length == 2) {
          typingText = '${typingNames[0]} and ${typingNames[1]} are typing...';
        } else {
          typingText = '${typingNames[0]}, ${typingNames[1]} and ${typingNames.length - 2} others are typing...';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  typingText,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return MessageBubble(
      message: message,
      isCurrentUser: isCurrentUser,
      controller: controller,
      context: context,
    );
  }

  void _showPollVotingDialog(Message message, String pollId) {
    showDialog(
      context: context,
      builder: (context) => PollVotingDialog(
        pollId: pollId,
        question: message.text.replaceFirst('📊 ', ''),
        currentUserId: controller.currentUser?.uid ?? '',
      ),
    );
  }

  Widget _buildMessageInput() {
    return MessageInput(
      controller: controller,
      textController: messageController,
      onSendMessage: _sendMessage,
      onShowAttachmentOptions: _showAttachmentOptions,
    );
  }

  void _sendMessage() async {
    final text = messageController.text.trim();
    debugPrint('🚀 ChatRoomScreen: _sendMessage called with text: "$text"');

    if (text.isNotEmpty &&
        controller.currentChatRoom.value != null &&
        controller.currentUser != null) {
      debugPrint('📤 ChatRoomScreen: All conditions met, proceeding to send...');

      // Stop typing before sending
      controller.updateTypingStatus(false);

      debugPrint('📤 ChatRoomScreen: Calling controller.sendTextMessage...');
      // Use ChatController's send method which handles quota/XP
      await controller.sendTextMessage(text);
      debugPrint('✅ ChatRoomScreen: controller.sendTextMessage completed');

      messageController.clear(); // Clear the text controller
      _scrollToBottom();
    } else {
      debugPrint('⚠️ ChatRoomScreen: Cannot send message - conditions not met');
      debugPrint('   Text: "$text" (length: ${text.length})');
      debugPrint('   Chat room: ${controller.currentChatRoom.value?.roomId}');
      debugPrint('   Current user: ${controller.currentUser?.uid}');
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
              title: Text(AppLocalizations.of(context)!.sendImage),
              onTap: () {
                Get.back();
                controller.sendImageMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: Text(AppLocalizations.of(context)!.createPoll),
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

  void _showCreatePollDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePollDialog(
        onPollCreated: (question, options, {DateTime? expiresAt}) {
          debugPrint(
            '📊 Creating poll: "$question" with ${options.length} options${expiresAt != null ? ', expires at: $expiresAt' : ', no expiration'}',
          );
          controller.createPoll(question, options, expiresAt: expiresAt);
          Navigator.of(context).pop(); // Close the poll creation dialog

          // Show success message
          Get.snackbar(
            AppLocalizations.of(context)!.pollCreated,
            AppLocalizations.of(context)!.pollSharedInChat,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            duration: const Duration(seconds: 3),
          );
        },
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
              title: Text(AppLocalizations.of(context)!.roomInfo),
              onTap: () {
                Get.back();
                _showRoomInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: Text(AppLocalizations.of(context)!.leaveRoom),
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
        title: Text(
          widget.chatRoom.title ?? _getDefaultRoomTitle(widget.chatRoom),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.type}: ${widget.chatRoom.type == 'public' ? AppLocalizations.of(context)!.public : AppLocalizations.of(context)!.private}',
            ),
            Text('Description: ${widget.chatRoom.description}'),
            Text('Created: ${timeago.format(widget.chatRoom.createdAt)}'),
            if (widget.chatRoom.members != null)
              Text('Members: ${widget.chatRoom.members!.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _leaveRoom() {
    controller.clearCurrentChat();
    Get.back();
  }

  void _scrollToBottom() {
    ChatRoomHelpers.scrollToBottom(scrollController);
    // Mark messages as read after scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markVisibleMessagesAsRead();
    });
  }

  Future<void> _markMessageAsRead(String messageId, String userId) async {
    try {
      await controller.markMessageAsRead(
        widget.chatRoom.roomId,
        messageId,
        userId,
      );
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  void _markVisibleMessagesAsRead() {
    final userId = controller.currentUser?.uid;
    if (userId == null || widget.chatRoom.roomId.isEmpty) return;

    // Get visible messages (simplified - mark recent messages as read)
    final messages = controller.messages;
    if (messages.isEmpty) return;

    // Mark the last few messages as read (visible ones)
    final visibleMessageCount = 10; // Assume last 10 messages are visible
    final startIndex = messages.length > visibleMessageCount ? messages.length - visibleMessageCount : 0;
    final messagesToMark = messages.sublist(startIndex);

    for (final message in messagesToMark) {
      if (!message.readBy.contains(userId) && message.senderId != userId) {
        // Mark as read using repository directly
        _markMessageAsRead(message.messageId, userId);
      }
    }
  }

  // Helper methods using ChatRoomHelpers
  Color _getRoomColor(ChatRoom chatRoom) {
    return ChatRoomHelpers.getRoomColor(chatRoom);
  }

  IconData _getRoomIcon(ChatRoom chatRoom) {
    return ChatRoomHelpers.getRoomIcon(chatRoom);
  }

  String _getRoomDisplayTitle(ChatRoom chatRoom) {
    return ChatRoomHelpers.getRoomDisplayTitle(chatRoom);
  }

  String _getRoomDisplaySubtitle(ChatRoom chatRoom) {
    return ChatRoomHelpers.getRoomDisplaySubtitle(chatRoom);
  }

  String _getDefaultRoomTitle(ChatRoom chatRoom) {
    return ChatRoomHelpers.getDefaultRoomTitle(chatRoom);
  }

  Future<Map<String, dynamic>?> _getHeaderInfo() async {
    // For private chats, show the other participant's info
    if (widget.chatRoom.type == 'private') {
      final userInfo = await controller.getPrivateChatUserInfo(widget.chatRoom.roomId);
      if (userInfo != null) {
        return {
          'title': userInfo['name'] ?? 'Unknown User',
          'subtitle': userInfo['phone'] ?? 'Private conversation',
        };
      }
    }

    // For public rooms, return null to use default room info
    return null;
  }
}
