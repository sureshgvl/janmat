import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
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
import 'screens/monetization/monetization_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/device_management_screen.dart';
import 'screens/main_tab_navigation.dart';
import 'core/app_bindings.dart';
import 'services/language_service.dart';
import 'services/background_initializer.dart';
import 'l10n/app_localizations.dart';
import 'utils/performance_monitor.dart';

void main() async {
  // Start performance monitoring
  startPerformanceTimer('app_startup');

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background services for zero frame skipping
  final backgroundInit = BackgroundInitializer();
  await backgroundInit.initializeAllServices();

  // CRITICAL: Initialize Firebase BEFORE creating any controllers
  startPerformanceTimer('firebase_init');
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Configure Firebase for development (suppresses App Check warnings)
    if (kDebugMode) {
      // In debug mode, we can safely ignore App Check warnings
      // as they don't affect functionality, just show warnings
      debugPrint('🔧 Firebase configured for development mode');
      debugPrint('ℹ️ App Check warnings are normal in development and can be ignored');
    }

    debugPrint('✅ Firebase initialized synchronously for controller compatibility');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
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
          return MaterialApp(
            theme: ThemeData(primarySwatch: Colors.blue),
            home: Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue, Colors.blueAccent],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 24),
                      Text(
                        'JanMat',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
            GetPage(name: '/monetization', page: () => const MonetizationScreen()),
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

    // Fast check for Firebase Auth user (doesn't require network)
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return {
        'route': '/login',
        'locale': locale,
      };
    }

    // For authenticated users, check their completion status
    // This needs to be fast to avoid blocking the UI
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final role = userData['role'] as String? ?? '';
        final cityId = userData['cityId'] as String? ?? '';
        final wardId = userData['wardId'] as String? ?? '';

        debugPrint('🔍 User state check - Role: "$role", City: "$cityId", Ward: "$wardId"');

        // Step 1: Check if role is selected
        if (role.isEmpty) {
          debugPrint('🎯 Redirecting to role selection - role is empty');
          return {
            'route': '/role-selection',
            'locale': locale,
          };
        }

        // Step 2: Check if profile is completed (city and ward)
        if (cityId.isEmpty || wardId.isEmpty) {
          debugPrint('🎯 Redirecting to profile completion - city/ward missing');
          return {
            'route': '/profile-completion',
            'locale': locale,
          };
        }

        // Step 3: If user is candidate, check candidate setup
        if (role == 'candidate') {
          try {
            // Check candidate data to see if party is selected
            final candidateDoc = await FirebaseFirestore.instance
                .collection('cities')
                .doc(cityId)
                .collection('wards')
                .doc(wardId)
                .collection('candidates')
                .where('userId', isEqualTo: currentUser.uid)
                .limit(1)
                .get();

            if (candidateDoc.docs.isNotEmpty) {
              final candidateData = candidateDoc.docs.first.data();
              final party = candidateData['party'] as String? ?? '';

              if (party.isEmpty) {
                debugPrint('🎯 Redirecting to candidate setup - party not selected');
                return {
                  'route': '/candidate-setup',
                  'locale': locale,
                };
              }
            } else {
              debugPrint('🎯 Redirecting to candidate setup - candidate data not found');
              return {
                'route': '/candidate-setup',
                'locale': locale,
              };
            }
          } catch (e) {
            debugPrint('⚠️ Error checking candidate data: $e');
            // If there's an error, redirect to candidate setup to be safe
            return {
              'route': '/candidate-setup',
              'locale': locale,
            };
          }
        }

        // All checks passed - user can go to home
        debugPrint('✅ All user checks passed - redirecting to home');
        return {
          'route': '/home',
          'locale': locale,
        };
      } else {
        debugPrint('⚠️ User document not found - redirecting to login');
        return {
          'route': '/login',
          'locale': locale,
        };
      }
    } catch (e) {
      debugPrint('⚠️ Error checking user state: $e');
      // On error, redirect to login to be safe
      return {
        'route': '/login',
        'locale': locale,
      };
    }
  }
}
