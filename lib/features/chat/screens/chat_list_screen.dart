import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/chat/chat_translations.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../core/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../controllers/room_controller.dart';
import '../controllers/message_controller.dart';
import 'chat_room_card.dart';
import 'dialogs/chat_dialogs.dart';
import 'chat_helpers.dart';
import '../widgets/user_search_dialog.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatController controller;

  @override
  void initState() {
    super.initState();

    // Initialize controller with proper dependency order
    // This ensures RoomController and MessageController are created first
    Get.lazyPut<RoomController>(() => RoomController());
    Get.lazyPut<MessageController>(() => MessageController(), fenix: true);
    controller = Get.put<ChatController>(ChatController(), permanent: true);

    // Initialize chat lazily when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.initializeChatIfNeeded();
      // fetchChatRooms() is already called in initializeChatIfNeeded(), no need to call again
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ChatTranslations.chatRooms),
        actions: [
          // Private chat button
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Start Private Chat',
            color: Colors.green,
            onPressed: () => _showPrivateChatOptions(),
          ),

          // Add room button (only if can create rooms)
          GetBuilder<ChatController>(
            builder: (controller) {
              if (ChatHelpers.canCreateRooms(controller.currentUser?.role)) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'createNewChatRoom'.tr,
                  color: Colors.blue,
                  onPressed: () => ChatDialogs.showCreateRoomDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Watch ad button (only if quota low)
          GetBuilder<ChatController>(
            builder: (controller) {
              if (!controller.canSendMessage) {
                return IconButton(
                  icon: const Icon(Icons.warning),
                  tooltip: 'watchAd'.tr,
                  color: Colors.orange,
                  onPressed: () => ChatDialogs.showWatchAdDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.homeBackgroundColor,
      body: GetBuilder<ChatController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return Container(
              color: Colors.white, // Clean white background instead of blue gradient
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(), // Default color (blue) is fine on white
                    const SizedBox(height: 24),
                    Text(
                      'loadingChatRooms'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87, // Dark text on white background
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
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
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            );
          }

          if (controller.chatRoomDisplayInfos.isEmpty) {
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
                    'noChatRoomsAvailable'.tr,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'chatRoomsWillAppearHere'.tr.trArgs([controller.currentUser?.name ?? 'Unknown']),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await controller.refreshChatRooms();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('refreshRooms'.tr),
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
                if (controller.chatRoomDisplayInfos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${controller.chatRoomDisplayInfos.length} chat rooms • ${controller.currentUser?.role ?? 'Unknown'}',
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
                    itemCount: controller.chatRoomDisplayInfos.length,
                    itemBuilder: (context, index) {
                      final displayInfo =
                          controller.chatRoomDisplayInfos[index];
                      return ChatRoomCard(displayInfo: displayInfo);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),

    );
  }

  void _showPrivateChatOptions() {
    Get.dialog(const UserSearchDialog());
  }
}
