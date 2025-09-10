import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../l10n/app_localizations.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import 'chat_room_screen.dart';
import 'chat_helpers.dart';

class ChatRoomCard extends StatelessWidget {
  final ChatRoomDisplayInfo displayInfo;

  const ChatRoomCard({
    super.key,
    required this.displayInfo,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final chatRoom = displayInfo.room;

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
                  color: ChatHelpers.getRoomColor(chatRoom),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  ChatHelpers.getRoomIcon(chatRoom),
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
                    // Title row with unread count
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ChatHelpers.getRoomDisplayTitle(chatRoom),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: displayInfo.hasUnreadMessages ? FontWeight.w700 : FontWeight.w600,
                              color: displayInfo.hasUnreadMessages ? Colors.black : const Color(0xFF1f2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread count badge (WhatsApp style)
                        if (displayInfo.hasUnreadMessages)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.all(Radius.circular(9)),
                            ),
                            child: Text(
                              displayInfo.unreadCount > 99 ? '99+' : displayInfo.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Subtitle with last message preview
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayInfo.lastMessagePreview ?? ChatHelpers.getRoomDisplaySubtitle(chatRoom),
                            style: TextStyle(
                              fontSize: 14,
                              color: displayInfo.hasUnreadMessages ? Colors.black87 : const Color(0xFF6b7280),
                              fontWeight: displayInfo.hasUnreadMessages ? FontWeight.w500 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Last activity time (WhatsApp style)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        displayInfo.lastMessageTime != null
                            ? timeago.format(displayInfo.lastMessageTime!)
                            : timeago.format(chatRoom.createdAt),
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
}