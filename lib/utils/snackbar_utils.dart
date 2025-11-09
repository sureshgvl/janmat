import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_constants.dart';

/// Enum for different snackbar types
enum SnackbarType {
  success,
  error,
  warning,
  info,
}

/// Utility class for showing snackbars consistently across the app
class SnackbarUtils {
  /// Private constructor to prevent instantiation
  SnackbarUtils._();

  /// Show a success snackbar
  static void showSuccess(String message, {String? title, Duration? duration}) {
    _showGetSnackbar(
      title: title ?? 'Success',
      message: message,
      backgroundColor: AppColors.snackBarSuccess,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: duration,
    );
  }

  /// Show an error snackbar
  static void showError(String message, {String? title, Duration? duration}) {
    _showGetSnackbar(
      title: title ?? 'Error',
      message: message,
      backgroundColor: AppColors.snackBarError,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: duration,
    );
  }

  /// Show a warning snackbar
  static void showWarning(String message, {String? title, Duration? duration}) {
    _showGetSnackbar(
      title: title ?? 'Warning',
      message: message,
      backgroundColor: AppColors.snackBarWarning,
      icon: const Icon(Icons.warning, color: Colors.black),
      duration: duration,
    );
  }

  /// Show an info snackbar
  static void showInfo(String message, {String? title, Duration? duration}) {
    _showGetSnackbar(
      title: title ?? 'Info',
      message: message,
      backgroundColor: AppColors.info,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: duration,
    );
  }

  /// Show a custom snackbar with GetX
  static void showCustom({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
    Duration? duration,
    SnackPosition? snackPosition,
  }) {
    _showGetSnackbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: duration,
      snackPosition: snackPosition,
    );
  }

  /// Show a snackbar using ScaffoldMessenger (for contexts where GetX is not available)
  static void showScaffoldSnackbar(
    BuildContext context,
    String message, {
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = AppColors.snackBarSuccess;
        textColor = AppColors.snackBarTextLight;
        break;
      case SnackbarType.error:
        backgroundColor = AppColors.snackBarError;
        textColor = AppColors.snackBarTextLight;
        break;
      case SnackbarType.warning:
        backgroundColor = AppColors.snackBarWarning;
        textColor = AppColors.snackBarTextDark;
        break;
      case SnackbarType.info:
        backgroundColor = AppColors.info;
        textColor = AppColors.snackBarTextLight;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  /// Show a success snackbar using ScaffoldMessenger
  static void showScaffoldSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showScaffoldSnackbar(
      context,
      message,
      type: SnackbarType.success,
      duration: duration,
      action: action,
    );
  }

  /// Show an error snackbar using ScaffoldMessenger
  static void showScaffoldError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showScaffoldSnackbar(
      context,
      message,
      type: SnackbarType.error,
      duration: duration,
      action: action,
    );
  }

  /// Show a warning snackbar using ScaffoldMessenger
  static void showScaffoldWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showScaffoldSnackbar(
      context,
      message,
      type: SnackbarType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Show an info snackbar using ScaffoldMessenger
  static void showScaffoldInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showScaffoldSnackbar(
      context,
      message,
      type: SnackbarType.info,
      duration: duration,
      action: action,
    );
  }

  /// Private method to show GetX snackbar with consistent styling
  static void _showGetSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
    Duration? duration,
    SnackPosition? snackPosition,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor ?? AppColors.info,
      colorText: textColor ?? Colors.white,
      icon: icon,
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: snackPosition ?? SnackPosition.TOP,
      borderRadius: 8,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
    );
  }
}
