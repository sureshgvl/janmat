import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';
import '../../controllers/chat_controller.dart';
import 'chat_room_card.dart';
import 'chat_dialogs.dart';
import 'chat_helpers.dart';

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
    // Initialize chat lazily when screen loads, then fetch rooms
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.initializeChatIfNeeded();
      controller.fetchChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatRooms),
        actions: [
          // Manual ward room creation button (only for candidates)
          GetBuilder<ChatController>(
            builder: (controller) {
              final user = controller.currentUser;
              if (user != null && user.role == 'candidate') {
                return IconButton(
                  icon: const Icon(Icons.home_work),
                  tooltip: 'Create Ward Room',
                  onPressed: () async {
                    await controller.manuallyCreateWardRoom();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Quota indicator and refresh button
          Row(
            children: [
              // Refresh button with consistent styling
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  tooltip: AppLocalizations.of(context)!.refreshChatRooms,
                  onPressed: () async {
                    await controller.refreshChatRooms();
                    Get.snackbar(
                      AppLocalizations.of(context)!.refreshed,
                      AppLocalizations.of(context)!.chatRoomsUpdated,
                      backgroundColor: Colors.green.shade100,
                      colorText: Colors.green.shade800,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
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
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.blueAccent],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      'Loading chat rooms...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
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
                    child: Text(AppLocalizations.of(context)!.retry),
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
                if (controller.chatRoomDisplayInfos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
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
                      final displayInfo = controller.chatRoomDisplayInfos[index];
                      return ChatRoomCard(displayInfo: displayInfo);
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
          if (ChatHelpers.canCreateRooms(controller.currentUser?.role)) _buildCreateRoomButton(),
          const SizedBox(height: 16),
          _buildQuotaWarningButtonExtended(),
        ].whereType<Widget>().toList(),
      ),
    );
  }

  Widget _buildCreateRoomButton() {
    return FloatingActionButton(
      onPressed: () => ChatDialogs.showCreateRoomDialog(context),
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add),
      tooltip: AppLocalizations.of(context)!.createNewChatRoom,
    );
  }

  Widget? _buildQuotaWarningButtonExtended() {
    if (!controller.canSendMessage) {
      return FloatingActionButton.extended(
        onPressed: () => ChatDialogs.showWatchAdDialog(context),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.warning),
        label: Text(AppLocalizations.of(context)!.watchAd),
      );
    }
    return null;
  }
}