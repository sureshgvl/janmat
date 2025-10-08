import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/language_selection_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/profile_completion_screen.dart';
import '../features/candidate/screens/candidate_profile_screen.dart';
import '../features/candidate/screens/change_party_symbol_screen.dart';
import '../features/candidate/models/candidate_model.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/monetization/screens/monetization_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/device_management_screen.dart';
import '../features/notifications/screens/notification_center_screen.dart';
import '../features/notifications/screens/notification_preferences_screen.dart';
import '../screens/main_tab_navigation.dart';

class AppRoutes {
  static List<GetPage> getPages = [
    GetPage(
      name: '/language-selection',
      page: () => const LanguageSelectionScreen(),
    ),
    GetPage(
      name: '/onboarding',
      page: () => const OnboardingScreen(),
    ),
    GetPage(name: '/login', page: () => const LoginScreen()),
    GetPage(
      name: '/role-selection',
      page: () => const RoleSelectionScreen(),
    ),
    GetPage(name: '/home', page: () => const MainTabNavigation()),
    GetPage(name: '/profile', page: () => const ProfileScreen()),
    GetPage(
      name: '/profile-completion',
      page: () => const ProfileCompletionScreen(),
    ),
    GetPage(
      name: '/candidate-profile',
      page: () => const CandidateProfileScreen(),
    ),
    GetPage(
      name: '/change-party-symbol',
      page: () {
        final candidate = Get.arguments as Candidate?;
        final currentUser = FirebaseAuth.instance.currentUser;
        return ChangePartySymbolScreen(
          currentCandidate: candidate,
          currentUser: currentUser,
        );
      },
    ),
    GetPage(name: '/chat', page: () => const ChatListScreen()),
    GetPage(
      name: '/monetization',
      page: () => const MonetizationScreen(),
    ),
    GetPage(name: '/settings', page: () => const SettingsScreen()),
    GetPage(
      name: '/device-management',
      page: () => const DeviceManagementScreen(),
    ),
    GetPage(
      name: '/notifications',
      page: () => const NotificationCenterScreen(),
    ),
    GetPage(
      name: '/notification-preferences',
      page: () => const NotificationPreferencesScreen(),
    ),
  ];
}

