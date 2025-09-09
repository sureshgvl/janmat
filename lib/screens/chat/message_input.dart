import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';

class MessageInput extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Attachment button
          GetBuilder<ChatController>(
            builder: (controller) => IconButton(
              icon: Icon(
                Icons.attach_file,
                color: controller.canSendMessage ? null : Colors.grey,
              ),
              onPressed: controller.canSendMessage ? onShowAttachmentOptions : null,
            ),
          ),

          // Voice recording button
          GetBuilder<ChatController>(
            builder: (controller) => IconButton(
              icon: Icon(
                Icons.mic,
                color: controller.canSendMessage ? null : Colors.grey,
              ),
              onPressed: controller.canSendMessage ? _toggleVoiceRecording : null,
            ),
          ),

          // Text input
          Expanded(
            child: GetBuilder<ChatController>(
              builder: (controller) => TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: controller.canSendMessage
                      ? 'Type a message...'
                      : controller.shouldShowWatchAdsButton
                          ? 'Watch ad to earn XP and send messages'
                          : 'Unable to send messages',
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

          // Send button or Watch Ads button
          const SizedBox(width: 8),
          GetBuilder<ChatController>(
            builder: (controller) {
              if (controller.canSendMessage) {
                // Show send button when user can send messages
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: onSendMessage,
                  ),
                );
              } else if (controller.shouldShowWatchAdsButton) {
                // Show watch ads button when user cannot send but is not premium
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                    onPressed: () => controller.watchRewardedAdForXP(),
                    tooltip: 'Watch ad to earn XP',
                  ),
                );
              } else {
                // Show disabled send button for premium users who somehow can't send
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: null,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _toggleVoiceRecording() {
    // TODO: Implement voice recording
    Get.snackbar('Coming Soon', 'Voice recording will be available soon!');
  }
}