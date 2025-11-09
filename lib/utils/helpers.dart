import 'package:flutter/material.dart';
import 'theme_constants.dart';
import 'snackbar_utils.dart';

enum SnackBarType { success, error, warning }

class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (isError) {
      SnackbarUtils.showScaffoldError(context, message);
    } else {
      SnackbarUtils.showScaffoldSuccess(context, message);
    }
  }

  // Enhanced snack bar with proper colors
  static void showCustomSnackBar(
    BuildContext context,
    String message,
    SnackBarType type,
  ) {
    switch (type) {
      case SnackBarType.success:
        SnackbarUtils.showScaffoldSuccess(context, message);
        break;
      case SnackBarType.error:
        SnackbarUtils.showScaffoldError(context, message);
        break;
      case SnackBarType.warning:
        SnackbarUtils.showScaffoldWarning(context, message);
        break;
    }
  }

  // Convenience methods for common snack bar types
  static void showSuccessSnackBar(BuildContext context, String message) {
    showCustomSnackBar(context, message, SnackBarType.success);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showCustomSnackBar(context, message, SnackBarType.error);
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    showCustomSnackBar(context, message, SnackBarType.warning);
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static String getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }
}
