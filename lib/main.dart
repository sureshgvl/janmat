import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/language_selection_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/profile_completion_screen.dart';
import 'screens/candidate/candidate_profile_screen.dart';
import 'screens/candidate/candidate_setup_screen.dart';
import 'screens/candidate/change_party_symbol_screen.dart';
import 'models/candidate_model.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/device_management_screen.dart';
import 'screens/main_tab_navigation.dart';
import 'core/app_bindings.dart';
import 'services/language_service.dart';
import 'l10n/app_localizations.dart';
import 'utils/performance_monitor.dart';

void main() async {
  // Start performance monitoring
  startPerformanceTimer('app_startup');

  WidgetsFlutterBinding.ensureInitialized();

  // Track Firebase initialization
  startPerformanceTimer('firebase_init');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  stopPerformanceTimer('firebase_init');

  stopPerformanceTimer('app_startup');

  // Log performance report in debug mode
  logPerformanceReport();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getInitialAppData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final appData = snapshot.data ?? {'route': '/login', 'locale': null};
        final initialRoute = appData['route'] as String;
        final initialLocale = appData['locale'] as Locale?;

        return GetMaterialApp(
          title: 'JanMat',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          locale: initialLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialBinding: AppBindings(),
          initialRoute: initialRoute,
          getPages: [
            GetPage(name: '/language-selection', page: () => const LanguageSelectionScreen()),
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/role-selection', page: () => const RoleSelectionScreen()),
            GetPage(name: '/home', page: () => const MainTabNavigation()),
            GetPage(name: '/profile', page: () => const ProfileScreen()),
            GetPage(name: '/profile-completion', page: () => const ProfileCompletionScreen()),
            GetPage(name: '/candidate-setup', page: () => const CandidateSetupScreen()),
            GetPage(name: '/candidate-profile', page: () => const CandidateProfileScreen()),
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
            GetPage(name: '/settings', page: () => const SettingsScreen()),
            GetPage(name: '/device-management', page: () => const DeviceManagementScreen()),
          ],
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getInitialAppData() async {
    final languageService = LanguageService();

    // Check if it's first time user (fast local check)
    final isFirstTime = await languageService.isFirstTimeUser();
    if (isFirstTime) {
      // Set default language to English for first-time users
      await languageService.setDefaultLanguage('en');
      return {
        'route': '/language-selection',
        'locale': const Locale('en'),
      };
    }

    // Get stored language preference (fast local check)
    final storedLocale = await languageService.getStoredLocale();
    final locale = storedLocale ?? const Locale('en');

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return {
        'route': '/login',
        'locale': locale,
      };
    }

    // For authenticated users, go to home and let the app handle profile checks later
    // This reduces startup time significantly
    return {
      'route': '/home',
      'locale': locale,
    };

    // Note: Profile completion checks are now handled in the home screen
    // This prevents slow Firebase calls during app initialization
  }
}
