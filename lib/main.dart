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
import 'screens/chat/chat_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/device_management_screen.dart';
import 'screens/main_tab_navigation.dart';
import 'core/app_bindings.dart';
import 'services/language_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

    // Check if it's first time user
    final isFirstTime = await languageService.isFirstTimeUser();
    if (isFirstTime) {
      // Set default language to English for first-time users
      await languageService.setDefaultLanguage('en');
      return {
        'route': '/language-selection',
        'locale': const Locale('en'),
      };
    }

    // Get stored language preference
    final storedLocale = await languageService.getStoredLocale();
    final locale = storedLocale ?? const Locale('en');

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return {
        'route': '/login',
        'locale': locale,
      };
    }

    try {
      // Verify user still exists by checking if we can get their ID token
      // This will fail if the user has been deleted
      await currentUser.getIdToken(true);

      // Check if user profile is complete
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final profileCompleted = userData?['profileCompleted'] ?? false;
        final roleSelected = userData?['roleSelected'] ?? false;

        if (!roleSelected) {
          return {
            'route': '/role-selection',
            'locale': locale,
          };
        }

        if (!profileCompleted) {
          return {
            'route': '/profile-completion',
            'locale': locale,
          };
        }
      } else {
        // User document doesn't exist, force logout and go to login
        await FirebaseAuth.instance.signOut();
        return {
          'route': '/login',
          'locale': locale,
        };
      }

      return {
        'route': '/home',
        'locale': locale,
      };
    } catch (e) {
      // If there's an error (user deleted, token expired, etc.), force logout
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        // Ignore sign out errors
      }
      return {
        'route': '/login',
        'locale': locale,
      };
    }
  }
}
