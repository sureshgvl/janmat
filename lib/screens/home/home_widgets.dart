import 'package:flutter/material.dart';
import 'home_navigation.dart';
import '../chat/chat_list_screen.dart';
import '../polls/polls_screen.dart';
import '../settings/settings_screen.dart';

class HomeWidgets {
  static Widget buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick action cards with animated navigation
  static Widget buildAnimatedQuickActionCard({
    required IconData icon,
    required String title,
    Widget? page,
    String? routeName,
    dynamic arguments,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (page != null) {
            HomeNavigation.toRightToLeft(page);
          } else if (routeName != null) {
            // Use widget navigation for problematic named routes
            switch (routeName) {
              case '/chat':
                HomeNavigation.toRightToLeft(const ChatListScreen());
                break;
              case '/polls':
                HomeNavigation.toRightToLeft(const PollsScreen());
                break;
              case '/settings':
                HomeNavigation.toRightToLeft(const SettingsScreen());
                break;
              default:
                HomeNavigation.toNamedRightToLeft(
                  routeName,
                  arguments: arguments,
                );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
