import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';

class HomeActions {
  static void showDeleteAccountDialog(BuildContext context, UserModel? userModel, AppLocalizations localizations) {
    Navigator.pop(context); // Close drawer first

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.deleteAccount),
          content: Text(localizations.deleteAccountConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _deleteAccount(context, localizations);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(localizations.deleteAccount),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _deleteAccount(BuildContext context, AppLocalizations localizations) async {
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
        localizations.success,
        localizations.accountDeletedSuccessfully,
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
      debugPrint('Warning: Could not dismiss loading dialog: $dialogError');
      }

      // Only show error if it's not the expected "no current user" error
      if (!e.toString().contains('no-current-user') &&
          !e.toString().contains('failed-precondition') &&
          !e.toString().contains('permission-denied')) {
        Get.snackbar(
          localizations.error,
          localizations.failedToDeleteAccount(e.toString()),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        // For expected errors, still show success since account was deleted
        Get.snackbar(
          localizations.success,
          localizations.accountDeletedSuccessfully,
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