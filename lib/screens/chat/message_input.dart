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
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: onShowAttachmentOptions,
          ),

          // Voice recording button
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _toggleVoiceRecording,
          ),

          // Text input
          Expanded(
            child: GetBuilder<ChatController>(
              builder: (controller) => TextField(
                controller: textController,
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
                onPressed: controller.canSendMessage ? onSendMessage : null,
              ),
            ),
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