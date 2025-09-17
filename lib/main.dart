import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/language_selection_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/profile_completion_screen.dart';
import 'screens/candidate/candidate_profile_screen.dart';
import 'screens/candidate/change_party_symbol_screen.dart';
import 'widgets/common/animated_splash_screen.dart';
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
import 'repositories/auth_repository.dart';

// Import optimization systems
import 'utils/error_recovery_manager.dart';
import 'utils/advanced_analytics.dart';
import 'utils/memory_manager.dart';
import 'utils/multi_level_cache.dart';
import 'utils/ab_testing_framework.dart';
import 'utils/data_compression.dart';

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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence with optimized settings
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        // Enable local cache for better offline performance
        host: null, // Use default host
        sslEnabled: true,
      );

      // Configure offline cache persistence for better performance
      // Note: Persistence is now enabled via Settings above
      debugPrint('ℹ️ Firestore persistence configured via Settings');

      debugPrint('✅ Firestore offline persistence enabled with optimizations');
    } catch (e) {
      debugPrint('⚠️ Failed to enable Firestore offline persistence: $e');
    }

    // Initialize Firebase App Check with error handling
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
      debugPrint('✅ Firebase App Check activated successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase App Check activation failed: $e');
      debugPrint(
        'ℹ️ Continuing without App Check - this is normal if not configured in Firebase console',
      );

      // In debug mode, we can safely continue without App Check
      if (kDebugMode) {
        debugPrint('🔧 Running in debug mode without App Check');
      } else {
        // In release mode, App Check should be properly configured
        debugPrint(
          '⚠️ WARNING: App Check failed in release mode - authentication may be affected',
        );
      }
    }

    // Configure Firebase for development (suppresses App Check warnings)
    if (kDebugMode) {
      // In debug mode, we can safely ignore App Check warnings
      // as they don't affect functionality, just show warnings
      debugPrint('🔧 Firebase configured for development mode');
      debugPrint(
        'ℹ️ App Check warnings are normal in development and can be ignored',
      );
    }

    debugPrint(
      '✅ Firebase initialized synchronously for controller compatibility',
    );

    // Initialize Firebase optimization systems
    startPerformanceTimer('optimizations_init');
    try {
      // Initialize error recovery system
      final errorRecovery = ErrorRecoveryManager();
      debugPrint('✅ Error recovery system initialized');

      // Initialize analytics system
      final analytics = AdvancedAnalyticsManager();
      debugPrint('✅ Advanced analytics system initialized');

      // Initialize memory management system
      final memoryManager = MemoryManager();
      debugPrint('✅ Memory management system initialized');

      // Initialize multi-level caching system
      final cache = MultiLevelCache();
      debugPrint('✅ Multi-level cache system initialized');

      // Initialize A/B testing framework
      final abTesting = ABTestingFramework();
      debugPrint('✅ A/B testing framework initialized');

      // Initialize data compression system
      final dataCompression = DataCompressionManager();
      debugPrint('✅ Data compression system initialized');

      // Start user session tracking if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        analytics.startUserSession(
          currentUser.uid,
          'unknown',
        ); // Role will be updated when loaded
        debugPrint('✅ User session tracking started for: ${currentUser.uid}');
      }

      // Warm up cache with essential data
      await cache.warmup([
        'app_config',
        'user_settings',
        'districts_list',
        'cities_list',
      ]);
      debugPrint('✅ Cache warmup completed');
    } catch (e) {
      debugPrint('⚠️ Optimization system initialization failed: $e');
      // Continue with app startup even if optimizations fail
    }
    stopPerformanceTimer('optimizations_init');

    // Analyze and cleanup storage on app startup
    try {
      final authRepository = AuthRepository();
      await authRepository.analyzeAndCleanupStorage();
    } catch (e) {
      debugPrint('ℹ️ Storage analysis failed: $e');
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
  stopPerformanceTimer('firebase_init');

  // Check for app updates
  await checkForUpdate();

  stopPerformanceTimer('app_startup');

  // Log performance report in debug mode
  logPerformanceReport();

  runApp(const MyApp());
}

Future<void> checkForUpdate() async {
  try {
    final updateInfo = await InAppUpdate.checkForUpdate();
    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      await InAppUpdate.performImmediateUpdate();
    }
  } catch (e) {
    debugPrint('Update check failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getInitialAppData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: AnimatedSplashScreen());
        }

        final appData = snapshot.data ?? {'route': '/login', 'locale': null};
        final initialRoute = appData['route'] as String;
        final initialLocale = appData['locale'] as Locale?;

        return GetMaterialApp(
          title: 'JanMat',
          theme: ThemeData(
            primaryColor: const Color(0xFFFF9933), // Deep saffron
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF9933), // Deep saffron
              secondary: Color(0xFF138808), // Forest green
              surface: Colors.white, // Light neutral gray
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Color(0xFF1F2937), // Dark charcoal
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFFF9933,
                ), // Consistent saffron buttons
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF9933),
                side: const BorderSide(color: Color(0xFFFF9933)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF9933),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF9933),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          locale: initialLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialBinding: AppBindings(),
          initialRoute: initialRoute,
          getPages: [
            GetPage(
              name: '/language-selection',
              page: () => const LanguageSelectionScreen(),
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
      return {'route': '/language-selection', 'locale': const Locale('en')};
    }

    // Get stored language preference (fast local check)
    final storedLocale = await languageService.getStoredLocale();
    final locale = storedLocale ?? const Locale('en');

    // Fast check for Firebase Auth user (doesn't require network)
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return {'route': '/login', 'locale': locale};
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
        final districtId = userData['districtId'] as String? ?? '';
        final bodyId = userData['bodyId'] as String? ?? '';
        final wardId = userData['wardId'] as String? ?? '';

        debugPrint(
          '🔍 User state check - Role: "$role", District: "$districtId", Body: "$bodyId", Ward: "$wardId"',
        );

        // Step 1: Check if role is selected
        if (role.isEmpty) {
          debugPrint('🎯 Redirecting to role selection - role is empty');
          return {'route': '/role-selection', 'locale': locale};
        }

        // Step 2: Check if profile is completed
        final profileCompleted = userData['profileCompleted'] ?? false;
        debugPrint('🔍 Profile completion status: $profileCompleted');

        if (!profileCompleted) {
          // Profile not completed, go to profile completion
          debugPrint(
            '🎯 Redirecting to profile completion - profile not completed',
          );
          return {
            'route': '/profile-completion',
            'locale': locale,
            'userData': userData, // Pass user data to avoid duplicate fetch
          };
        }

        // Step 3: Profile is completed, go to home for all users
        debugPrint('✅ Profile completed, redirecting to home');

        // All checks passed - user can go to home
        debugPrint('✅ All user checks passed - redirecting to home');
        return {'route': '/home', 'locale': locale};
      } else {
        debugPrint('⚠️ User document not found - redirecting to login');
        return {'route': '/login', 'locale': locale};
      }
    } catch (e) {
      debugPrint('⚠️ Error checking user state: $e');
      // On error, redirect to login to be safe
      return {'route': '/login', 'locale': locale};
    }
  }
}
