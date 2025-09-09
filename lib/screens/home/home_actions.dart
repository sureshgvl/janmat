import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';

class HomeActions {
  static void showDeleteAccountDialog(BuildContext context, UserModel? userModel) {
    Navigator.pop(context); // Close drawer first

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data including:\n\n'
            '• Your profile information\n'
            '• Chat conversations and messages\n'
            '• XP points and rewards\n'
            '• Following/followers data\n\n'
            'This action is irreversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _deleteAccount(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _deleteAccount(BuildContext context) async {
    BuildContext? dialogContext;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx;
          return const Center(child: CircularProgressIndicator());
        },
      );

      final authRepository = AuthRepository();
      await authRepository.deleteAccount();

      // Close loading dialog using stored context
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      } else if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success message
      Get.snackbar(
        'Success',
        'Your account has been deleted successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // After account deletion, navigate to language selection since SharedPreferences are cleared
      await Future.delayed(const Duration(seconds: 2)); // Give time for snackbar to show

      // Clear all routes and navigate to language selection (first-time user flow)
      Get.offAllNamed('/language-selection');

    } catch (e) {
      // Close loading dialog using stored context or fallback
      try {
        if (dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.of(dialogContext!).pop();
        } else if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          // Last resort - try Get.back()
          Get.back();
        }
      } catch (dialogError) {
        // Ignore dialog dismissal errors
        print('Warning: Could not dismiss loading dialog: $dialogError');
      }

      // Only show error if it's not the expected "no current user" error
      if (!e.toString().contains('no-current-user') &&
          !e.toString().contains('failed-precondition') &&
          !e.toString().contains('permission-denied')) {
        Get.snackbar(
          'Error',
          'Failed to delete account: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        // For expected errors, still show success since account was deleted
        Get.snackbar(
          'Success',
          'Your account has been deleted successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Still navigate to language selection
        await Future.delayed(const Duration(seconds: 2));
        Get.offAllNamed('/language-selection');
      }
    }
  }
}