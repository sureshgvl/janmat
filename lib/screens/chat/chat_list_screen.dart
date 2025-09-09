import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../l10n/app_localizations.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatController controller = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    // Fetch chat rooms when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatRooms),
        actions: [
          // Initialize sample data button (admin only)
          GetBuilder<ChatController>(
            builder: (controller) {
              final user = controller.currentUser;
              if (user != null && user.role == 'admin') {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: AppLocalizations.of(context)!.initializeSampleData,
                      onPressed: () => _showInitializeDataDialog(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: AppLocalizations.of(context)!.refreshWardRoom,
                      onPressed: () async {
                        await controller.refreshUserDataAndChat();
                        Get.snackbar(AppLocalizations.of(context)!.debug, AppLocalizations.of(context)!.userDataRefreshed);
                      },
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.sync),
                tooltip: AppLocalizations.of(context)!.refreshWardRoom,
                onPressed: () async {
                  await controller.refreshUserDataAndChat();
                  Get.snackbar(AppLocalizations.of(context)!.debug, AppLocalizations.of(context)!.userDataRefreshed);
                },
              );
            },
          ),

          // Quota indicator and refresh button
          Row(
            children: [
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppLocalizations.of(context)!.refreshChatRooms,
                onPressed: () async {
                  await controller.refreshChatRooms();
                  Get.snackbar(AppLocalizations.of(context)!.refreshed, AppLocalizations.of(context)!.chatRoomsUpdated);
                },
              ),

              // Quota indicator
              GetBuilder<ChatController>(
                builder: (controller) => Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.canSendMessage ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: controller.canSendMessage ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.canSendMessage ? Icons.message : Icons.warning,
                        size: 16,
                        color: controller.canSendMessage ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${controller.remainingMessages}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: controller.canSendMessage ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: GetBuilder<ChatController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      controller.clearError();
                      controller.fetchChatRooms();
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (controller.chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noChatRoomsAvailable,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.chatRoomsWillAppearHere(controller.currentUser?.name ?? 'Unknown'),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await controller.refreshChatRooms();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.refreshRooms),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.fetchChatRooms();
            },
            child: Column(
              children: [
                // Debug info (only show in debug mode)
                if (controller.chatRooms.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '${controller.chatRooms.length} chat rooms • ${controller.currentUser?.role ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.chatRooms.length,
                    itemBuilder: (context, index) {
                      final chatRoom = controller.chatRooms[index];
                      return _buildChatRoomCard(context, chatRoom);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_canCreateRooms()) _buildCreateRoomButton(),
          const SizedBox(height: 16),
          _buildQuotaWarningButtonExtended(),
        ].whereType<Widget>().toList(),
      ),
    );
  }

  Widget _buildChatRoomCard(BuildContext context, ChatRoom chatRoom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 1), // Minimal margin like WhatsApp
      elevation: 0, // No elevation like WhatsApp
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // No border radius like WhatsApp
      ),
      child: InkWell(
        onTap: () {
          controller.selectChatRoom(chatRoom);
          Get.to(() => ChatRoomScreen(chatRoom: chatRoom));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Chat room icon (WhatsApp style)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getRoomColor(chatRoom),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getRoomIcon(chatRoom),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Chat room info (WhatsApp style)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (City name as main title)
                    Text(
                      _getRoomDisplayTitle(chatRoom),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Subtitle (Ward name or description)
                    Text(
                      _getRoomDisplaySubtitle(chatRoom),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6b7280),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Last activity time (WhatsApp style)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        timeago.format(chatRoom.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9ca3af),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Room type indicator (small badge)
              if (chatRoom.type == 'private')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.private,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildQuotaWarningButton() {
    if (controller.canSendMessage) return null;

    return FloatingActionButton.extended(
      onPressed: () {
        _showQuotaDialog();
      },
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.warning),
      label: Text(AppLocalizations.of(context)!.watchAd),
    );
  }

  void _showQuotaDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context)!.messageLimitReached),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.messageLimitReachedDescription,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.remainingMessages(controller.remainingMessages.toString()),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          // Option 1: Watch Rewarded Ad
          TextButton.icon(
            onPressed: () {
              Get.back();
              _watchRewardedAdForXP();
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text(AppLocalizations.of(context)!.watchAdForXP),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),

          // Option 2: Buy XP
          TextButton.icon(
            onPressed: () {
              Get.back();
              Get.toNamed('/monetization');
            },
            icon: const Icon(Icons.shopping_cart),
            label: Text(AppLocalizations.of(context)!.buyXP),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),

          // Option 3: Cancel
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  void _watchAdForQuota() {
    // TODO: Implement actual ad watching
    // For now, just add some quota
    controller.addExtraQuota(10);
    Get.snackbar(
      'Success',
      AppLocalizations.of(context)!.earnedExtraMessages,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  void _watchRewardedAdForXP() async {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loadingRewardedAd),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    await controller.watchRewardedAdForXP();
    Get.back(); // Close loading dialog
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
      // Format: ward_cityId_wardId
      final parts = chatRoom.roomId.split('_');
      if (parts.length >= 3) {
        final cityId = parts[1];
        final wardId = parts[2];
        return 'Ward $wardId (${cityId.toUpperCase()}) Chat';
      }
      return 'Ward Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return 'Candidate Discussion';
    } else {
      return chatRoom.roomId;
    }
  }

  bool _canCreateRooms() {
    final user = controller.currentUser;
    return user != null && (user.role == 'candidate' || user.role == 'admin');
  }

  bool _showQuotaWarning() {
    return !controller.canSendMessage;
  }

  Widget _buildCreateRoomButton() {
    return FloatingActionButton(
      onPressed: () => _showCreateRoomDialog(),
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add),
      tooltip: AppLocalizations.of(context)!.createNewChatRoom,
    );
  }

  Widget? _buildQuotaWarningButtonExtended() {
    if (!controller.canSendMessage) {
      return FloatingActionButton.extended(
        onPressed: () => _showQuotaDialog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.warning),
        label: Text(AppLocalizations.of(context)!.watchAd),
      );
    }
    return null;
  }

  void _showCreateRoomDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String roomType = 'public';

    Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context)!.createNewChatRoom),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.roomTitle,
                  hintText: AppLocalizations.of(context)!.enterRoomName,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.descriptionOptional,
                  hintText: AppLocalizations.of(context)!.briefDescriptionOfRoom,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: roomType,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.roomType),
                items: [
                  DropdownMenuItem(value: 'public', child: Text(AppLocalizations.of(context)!.publicRoom)),
                  DropdownMenuItem(value: 'private', child: Text(AppLocalizations.of(context)!.privateRoom)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    roomType = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Get.back();

                final user = controller.currentUser;
                if (user != null) {
                  final chatRoom = ChatRoom(
                    roomId: 'custom_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
                    createdAt: DateTime.now(),
                    createdBy: user.uid,
                    type: roomType,
                    title: title,
                    description: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : null,
                  );

                  await controller.createChatRoom(chatRoom);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }

  void _showInitializeDataDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(AppLocalizations.of(context)!.initializeSampleData),
        content: Text(
          AppLocalizations.of(context)!.initializeSampleDataDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.initializeSampleData();
            },
            child: Text(AppLocalizations.of(context)!.initialize),
          ),
        ],
      ),
    );
  }
}