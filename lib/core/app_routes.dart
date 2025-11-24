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
import '../features/candidate/screens/media_add_post_screen.dart';
import '../features/candidate/models/candidate_model.dart';
import '../features/candidate/models/media_model.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/monetization/screens/monetization_screen.dart';
import '../features/monetization/screens/payment_history_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/device_management_screen.dart';
import '../features/notifications/screens/notification_center_screen.dart';
import '../features/notifications/screens/notification_preferences_screen.dart';
import '../screens/main_tab_navigation.dart';
import 'app_route_names.dart';

class AppRoutes {
  static List<GetPage> getPages = [
    GetPage(
      name: AppRouteNames.languageSelection,
      page: () => const LanguageSelectionScreen(),
    ),
    GetPage(
      name: AppRouteNames.onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(name: AppRouteNames.login, page: () => const LoginScreen()),
    GetPage(
      name: AppRouteNames.roleSelection,
      page: () => const RoleSelectionScreen(),
    ),
    GetPage(name: AppRouteNames.home, page: () => const MainTabNavigation()),
    GetPage(name: AppRouteNames.profile, page: () => const ProfileScreen()),
    GetPage(
      name: AppRouteNames.profileCompletion,
      page: () => const ProfileCompletionScreen(),
    ),
    GetPage(
      name: AppRouteNames.candidateProfile,
      page: () => const CandidateProfileScreen(),
    ),
    GetPage(
      name: AppRouteNames.publicCandidateProfile,
      page: () => const CandidateProfileScreen(isGuestAccess: true),
    ),
    GetPage(
      name: AppRouteNames.changePartySymbol,
      page: () {
        final candidate = Get.arguments as Candidate?;
        final currentUser = FirebaseAuth.instance.currentUser;
        return ChangePartySymbolScreen(
          currentCandidate: candidate,
        );
      },
    ),
    GetPage(name: AppRouteNames.chat, page: () => const ChatListScreen()),
    GetPage(
      name: AppRouteNames.monetization,
      page: () => const MonetizationScreen(),
    ),
    GetPage(
      name: AppRouteNames.paymentHistory,
      page: () => const PaymentHistoryScreen(),
    ),
    GetPage(name: AppRouteNames.settings, page: () => const SettingsScreen()),
    GetPage(
      name: AppRouteNames.deviceManagement,
      page: () => const DeviceManagementScreen(),
    ),
    GetPage(
      name: AppRouteNames.notifications,
      page: () => const NotificationCenterScreen(),
    ),
    GetPage(
      name: AppRouteNames.notificationPreferences,
      page: () => const NotificationPreferencesScreen(),
    ),

    // Candidate Media routes
    GetPage(
      name: AppRouteNames.candidateMediaAdd,
      page: () {
        final candidate = Get.arguments as Candidate?;
        return MediaAddPostScreen(candidate: candidate);
      },
    ),
    GetPage(
      name: AppRouteNames.candidateMediaEdit,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final existingItem = args?['item'] as MediaItem?;
        final candidate = args?['candidate'] as Candidate?;
        return MediaAddPostScreen(existingItem: existingItem, candidate: candidate);
      },
    ),
  ];
}
