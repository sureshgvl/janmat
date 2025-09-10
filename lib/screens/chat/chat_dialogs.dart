import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';

class ChatDialogs {
  static void showCreateRoomDialog(BuildContext context) {
    final controller = Get.find<ChatController>();
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

  static void showQuotaDialog(BuildContext context) {
    final controller = Get.find<ChatController>();

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
              _watchRewardedAdForXP(context);
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text(AppLocalizations.of(context)!.watchAdForXP),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
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

  static void showInitializeDataDialog(BuildContext context) {
    final controller = Get.find<ChatController>();

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

  static void _watchRewardedAdForXP(BuildContext context) async {
    final controller = Get.find<ChatController>();

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
}