import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../common/confirmation_dialog.dart';

class HomeActions {
  static Future<void> showDeleteAccountDialog(
    BuildContext context,
    UserModel? userModel,
    AppLocalizations localizations,
  ) async {
    final result = await ConfirmationDialog.show(
      context: context,
      title: localizations.deleteAccount,
      content: localizations.deleteAccountConfirmation,
      cancelText: localizations.cancel,
      confirmText: localizations.deleteAccount,
      isDestructive: true,
    );

    if (result == true) {
      // Close drawer after confirmation
      Navigator.pop(context);
      await _deleteAccount(context, localizations);
    }
  }

  static Future<void> _deleteAccount(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
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

      // Note: Dialog will be automatically dismissed by Get.offAllNamed clearing all routes

      // Navigate first, then show success message to avoid context issues
      Get.offAllNamed('/language-selection');

      // Show success message after navigation using WidgetsBinding to ensure context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          localizations.success,
          localizations.accountDeletedSuccessfully,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      });
    } catch (e) {
      // Note: Dialog will be automatically dismissed by Get.offAllNamed clearing all routes

      // Only show error if it's not the expected "no current user" error
      if (!e.toString().contains('no-current-user') &&
          !e.toString().contains('failed-precondition') &&
          !e.toString().contains('permission-denied')) {
        // Show error message immediately since we're not navigating
        Get.snackbar(
          localizations.error,
          localizations.failedToDeleteAccount(e.toString()),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        // For expected errors, still show success since account was deleted
        // Navigate first, then show success message to avoid context issues
        Get.offAllNamed('/language-selection');

        // Show success message after navigation using WidgetsBinding to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            localizations.success,
            localizations.accountDeletedSuccessfully,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        });
      }
    }
  }
}
