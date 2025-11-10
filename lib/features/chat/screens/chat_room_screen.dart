import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:janmat/features/chat/models/chat_message.dart';
import 'package:janmat/features/chat/models/chat_room.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/chat/chat_translations.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../controllers/chat_controller.dart';
import '../controllers/message_controller.dart';
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

  // Group messages by date for date separators
  final List<dynamic> _groupedMessages = [];

  // Helper method to group messages by date
  void _groupMessagesByDate(List<Message> messages) {
    _groupedMessages.clear();

    if (messages.isEmpty) return;

    // Sort messages by timestamp (should already be sorted, but ensure it)
    final sortedMessages = List<Message>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    String? currentDate;
    List<Message> currentGroup = [];

    for (final message in sortedMessages) {
      final messageDate = _formatMessageDate(message.createdAt);

      if (currentDate != messageDate) {
        // Save previous group if exists
        if (currentGroup.isNotEmpty) {
          _groupedMessages.add({'type': 'messages', 'messages': currentGroup});
        }

        // Start new date group
        _groupedMessages.add({'type': 'date', 'date': messageDate});
        currentDate = messageDate;
        currentGroup = [message];
      } else {
        // Add to current group
        currentGroup.add(message);
      }
    }

    // Add the last group
    if (currentGroup.isNotEmpty) {
      _groupedMessages.add({'type': 'messages', 'messages': currentGroup});
    }
  }

  // Helper method to format date for display
  String _formatMessageDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      // Return day name for this week
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    } else {
      // Return formatted date for older messages
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void initState() {
    super.initState();
    // Select the chat room when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectChatRoom(widget.chatRoom);
      // Use smart scroll for initial load - always scroll to bottom
      _scrollToBottom(force: true);
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
      backgroundColor: const Color(0xFFE5DDD5),
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
                  AppLogger.chat(
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
                            'loadingMessages'.tr,
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
                            'noMessagesYet'.tr,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'startConversation'.tr.trArgs([
                              widget.chatRoom.title ??
                                  _getDefaultRoomTitle(widget.chatRoom),
                            ]),
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
                      // Use smart scroll for new messages - only scroll if user is near bottom
                      _smartScrollToBottom();
                    });
                  }
                  _previousMessageCount = messages.length;

                  // Group messages by date for date separators
                  _groupMessagesByDate(messages);

                  // Add load more button at the top if there are more messages
                  final hasMoreMessages = messageController.hasMoreMessages.value;
                  final isLoadingMore = messageController.isLoadingMore.value;

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _groupedMessages.length + (hasMoreMessages ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Load more button at the top
                      if (index == 0 && hasMoreMessages) {
                        return _buildLoadMoreButton(messageController, widget.chatRoom.roomId, isLoadingMore);
                      }

                      // Adjust index for the load more button
                      final adjustedIndex = hasMoreMessages ? index - 1 : index;

                      if (adjustedIndex < _groupedMessages.length) {
                        final item = _groupedMessages[adjustedIndex];

                        if (item['type'] == 'date') {
                          // Date separator
                          return _buildDateSeparator(item['date']);
                        } else if (item['type'] == 'messages') {
                          // Messages group
                          final messagesGroup = item['messages'] as List<Message>;
                          return Column(
                            children: messagesGroup.map((message) {
                              final isCurrentUser = message.senderId == controller.currentUser?.uid;

                              AppLogger.chat(
                                '🔄 ChatRoomScreen: Rendering message - ID: ${message.messageId}, Text: "${message.text}", Sender: ${message.senderId}, Status: ${message.status}',
                              );

                              return _buildMessageBubble(message, isCurrentUser);
                            }).toList(),
                          );
                        }
                      }

                      return const SizedBox.shrink();
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

  Widget _buildDateSeparator(String dateText) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(MessageController messageController, String roomId, bool isLoading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => messageController.loadMoreMessages(roomId),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.history, size: 16),
          label: Text(
            isLoading ? 'Loading...' : 'Load Earlier Messages',
            style: const TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  void _showPollVotingDialog(Message message, String pollId) {
    showDialog(
      context: context,
      builder: (context) => PollVotingDialog(
        pollId: pollId,
        question: message.text.replaceFirst('📊 ', ''),
        currentUserId: controller.currentUser?.uid ?? '',
        onDialogOpened: () {
          // Scroll to the poll message when dialog opens to ensure it's visible
          _scrollToPollMessage(message);
        },
        onVoteCompleted: () {
          // Scroll to the poll message after voting to show updated results
          _scrollToPollMessage(message);
        },
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
    AppLogger.chat('🚀 ChatRoomScreen: _sendMessage called with text: "$text"');

    // Wait for user data to be available if not already loaded
    if (controller.currentUser == null && controller.isUserAuthenticated) {
      AppLogger.chat('⏳ ChatRoomScreen: User data not loaded yet, waiting...');
      // Try to load user data
      await controller.getCompleteUserData();
      // Small delay to ensure reactive state updates
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (text.isNotEmpty &&
        controller.currentChatRoom.value != null &&
        controller.currentUser != null) {
      AppLogger.chat('📤 ChatRoomScreen: All conditions met, proceeding to send...');

      // Stop typing before sending
      controller.updateTypingStatus(false);

      AppLogger.chat('📤 ChatRoomScreen: Calling controller.sendTextMessage...');
      // Use ChatController's send method which handles quota/XP
      await controller.sendTextMessage(text);
      AppLogger.chat('✅ ChatRoomScreen: controller.sendTextMessage completed');

      messageController.clear(); // Clear the text controller

      // Always scroll to bottom after sending message to show the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(force: true);
      });
    } else {
      AppLogger.chat('⚠️ ChatRoomScreen: Cannot send message - conditions not met');
      AppLogger.chat('   Text: "$text" (length: ${text.length})');
      AppLogger.chat('   Chat room: ${controller.currentChatRoom.value?.roomId}');
      AppLogger.chat('   Current user: ${controller.currentUser?.uid}');
      AppLogger.chat('   Is authenticated: ${controller.isUserAuthenticated}');

      if (!controller.isUserAuthenticated) {
        SnackbarUtils.showError('Please log in to send messages');
      } else if (controller.currentUser == null) {
        SnackbarUtils.showError('Loading user data, please try again');
      }
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
              title: Text(ChatTranslations.sendImage),
              onTap: () {
                Get.back();
                controller.sendImageMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: Text(ChatTranslations.createPoll),
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
          AppLogger.chat(
            '📊 Creating poll: "$question" with ${options.length} options${expiresAt != null ? ', expires at: $expiresAt' : ', no expiration'}',
          );
          controller.createPoll(question, options, expiresAt: expiresAt);
          Navigator.of(context).pop(); // Close the poll creation dialog

          // Show success message
          SnackbarUtils.showSuccess('pollSharedInChat'.tr);
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
              title: Text('roomInfo'.tr),
              onTap: () {
                Get.back();
                _showRoomInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: Text('leaveRoom'.tr),
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
              '${ChatTranslations.roomType}: ${widget.chatRoom.type == 'public' ? ChatTranslations.publicRoom : ChatTranslations.privateRoom}',
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

  void _scrollToBottom({bool force = false}) {
    ChatRoomHelpers.scrollToBottom(scrollController, force: force);
    // Mark messages as read after scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markVisibleMessagesAsRead();
    });
  }

  // Enhanced scroll to bottom with smart behavior
  void _smartScrollToBottom() {
    // Check if user is already near bottom before scrolling
    final isNearBottom = ChatRoomHelpers.isNearBottom(scrollController);

    if (isNearBottom) {
      // User is near bottom, scroll smoothly
      _scrollToBottom(force: true);
    } else {
      // User is scrolled up, don't auto-scroll to avoid interrupting reading
      AppLogger.chat('User is scrolled up, skipping auto-scroll to preserve reading position');
    }
  }

  // Scroll to a specific poll message to show updated vote results
  void _scrollToPollMessage(Message pollMessage) {
    // Find the index of the poll message in the grouped messages
    for (int groupIndex = 0; groupIndex < _groupedMessages.length; groupIndex++) {
      final group = _groupedMessages[groupIndex];
      if (group['type'] == 'messages') {
        final messages = group['messages'] as List<Message>;
        final messageIndex = messages.indexWhere((msg) => msg.messageId == pollMessage.messageId);
        if (messageIndex != -1) {
          // Calculate the position in the ListView
          int listViewIndex = groupIndex; // Account for date separators and previous groups

          // Add the index within this message group
          listViewIndex += messageIndex;

          // Account for load more button if present
          final hasMoreMessages = controller.messages.isNotEmpty &&
              controller.messages.first.createdAt.isAfter(DateTime(2020)); // Rough check
          if (hasMoreMessages) {
            listViewIndex += 1; // Add 1 for the load more button
          }

          // Scroll to the calculated position
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollController.animateTo(
              listViewIndex * 100.0, // Rough estimate of item height
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });

          AppLogger.chat('Scrolling to poll message at list index: $listViewIndex');
          break;
        }
      }
    }
  }

  Future<void> _markMessageAsRead(String messageId, String userId) async {
    try {
      await controller.markMessageAsRead(
        widget.chatRoom.roomId,
        messageId,
        userId,
      );
    } catch (e) {
      AppLogger.chat('Error marking message as read: $e');
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
