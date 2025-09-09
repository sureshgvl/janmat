import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeNavigation {
  // Slide from right to left (page in)
  static void toRightToLeft(Widget page, {dynamic arguments}) {
    Get.to(
      () => page,
      arguments: arguments,
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  // Slide from left to right (page out)
  static void toLeftToRight(Widget page, {dynamic arguments}) {
    Get.to(
      () => page,
      arguments: arguments,
      transition: Transition.leftToRight,
      duration: const Duration(milliseconds: 300),
    );
  }

  // Navigate to named route with right to left animation
  static void toNamedRightToLeft(String routeName, {dynamic arguments}) {
    Get.toNamed(
      routeName,
      arguments: arguments,
    );
  }

  // Navigate to named route with left to right animation
  static void toNamedLeftToRight(String routeName, {dynamic arguments}) {
    Get.toNamed(
      routeName,
      arguments: arguments,
    );
  }

  // Go back with left to right animation
  static void back() {
    Get.back();
  }

  // Custom slide transition for more control
  static Route<T> createCustomSlideRoute<T>({
    required Widget page,
    required Offset beginOffset,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const endOffset = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: beginOffset, end: endOffset)
            .chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  // Navigate with custom right to left slide
  static Future<T?> toWithCustomRightToLeft<T>(Widget page) {
    return Navigator.push<T>(
      Get.context!,
      createCustomSlideRoute(
        page: page,
        beginOffset: const Offset(1.0, 0.0), // From right
      ),
    );
  }

  // Navigate with custom left to right slide
  static Future<T?> toWithCustomLeftToRight<T>(Widget page) {
    return Navigator.push<T>(
      Get.context!,
      createCustomSlideRoute(
        page: page,
        beginOffset: const Offset(-1.0, 0.0), // From left
      ),
    );
  }
}