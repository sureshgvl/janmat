import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/language_selection_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/profile_completion_screen.dart';
import 'features/candidate/screens/candidate_profile_screen.dart';
import 'features/candidate/screens/change_party_symbol_screen.dart';
import 'features/common/animated_splash_screen.dart';
import 'features/candidate/models/candidate_model.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/monetization/screens/monetization_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/device_management_screen.dart';
import 'screens/main_tab_navigation.dart';
import 'core/app_bindings.dart';
import 'services/language_service.dart';
import 'services/background_initializer.dart';
import 'services/background_sync_manager.dart';
import 'services/fcm_service.dart';
import 'l10n/app_localizations.dart';
import 'l10n/features/candidate/candidate_localizations.dart';
import 'l10n/features/chat/chat_localizations.dart';
import 'l10n/features/auth/auth_localizations.dart';
import 'l10n/features/profile/profile_localizations.dart';
import 'utils/performance_monitor.dart';
import 'features/auth/repositories/auth_repository.dart';

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

  // Initialize background services asynchronously for better performance
  final backgroundInit = BackgroundInitializer();
  // Run in parallel with other initializations
  final backgroundInitFuture = backgroundInit.initializeAllServices();

  // CRITICAL: Initialize Firebase BEFORE creating any controllers
  startPerformanceTimer('firebase_init');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firestore with optimized settings (non-blocking)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      host: null,
      sslEnabled: true,
    );
    debugPrint('✅ Firestore configured with optimizations');

    debugPrint('✅ Firebase initialized');

    // Initialize FCM for push notifications
    try {
      final fcmService = FCMService();
      await fcmService.initialize();
      debugPrint('✅ FCM service initialized');
    } catch (e) {
      debugPrint('⚠️ FCM initialization failed: $e');
    }
   } catch (e) {
     debugPrint('❌ Firebase initialization failed: $e');
   }
   stopPerformanceTimer('firebase_init');

  // Initialize essential services in parallel
  startPerformanceTimer('services_init');
  try {
    final futures = <Future>[];

    // Initialize optimization systems in parallel
    futures.add(Future(() async {
      final errorRecovery = ErrorRecoveryManager();
      debugPrint('✅ Error recovery system initialized');
    }));

    futures.add(Future(() async {
      final analytics = AdvancedAnalyticsManager();
      debugPrint('✅ Advanced analytics system initialized');
    }));

    futures.add(Future(() async {
      final memoryManager = MemoryManager();
      debugPrint('✅ Memory management system initialized');
    }));

    futures.add(Future(() async {
      final cache = MultiLevelCache();
      debugPrint('✅ Multi-level cache system initialized');
    }));

    futures.add(Future(() async {
      final abTesting = ABTestingFramework();
      debugPrint('✅ A/B testing framework initialized');
    }));

    futures.add(Future(() async {
      final dataCompression = DataCompressionManager();
      debugPrint('✅ Data compression system initialized');
    }));

    // Wait for background init to complete
    await backgroundInitFuture;

    // Initialize background sync manager (non-blocking)
    Future(() async {
      try {
        final syncManager = BackgroundSyncManager();
        syncManager.initialize();
        debugPrint('✅ Background sync manager initialized');
      } catch (e) {
        debugPrint('⚠️ Background sync manager initialization failed: $e');
      }
    });

    // Wait for essential services to complete
    await Future.wait(futures);

    // Start user session tracking if user is logged in (non-blocking)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Future(() async {
        final analytics = AdvancedAnalyticsManager();
        analytics.startUserSession(currentUser.uid, 'unknown');
        debugPrint('✅ User session tracking started for: ${currentUser.uid}');
      });
    }

  } catch (e) {
    debugPrint('⚠️ Services initialization failed: $e');
  }
  stopPerformanceTimer('services_init');

  // Check for app updates (run in background, don't block startup)
  Future(() async {
    try {
      await checkForUpdate();
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  });

  stopPerformanceTimer('app_startup');

  // Log performance report in debug mode (non-blocking)
  Future(() => logPerformanceReport());

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
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            CandidateLocalizations.delegate,
            ChatLocalizations.delegate,
            AuthLocalizations.delegate,
            ProfileLocalizations.delegate,
          ],
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

  // Wait for Firebase Auth to properly initialize
  Future<User?> _waitForFirebaseAuthInitialization() async {
    // First check if we already have a current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('🔐 Firebase Auth already has current user: ${currentUser.uid}');
      return currentUser;
    }

    // Wait for auth state changes with a timeout
    try {
      final user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ Firebase Auth initialization timeout');
          return null;
        },
      );
      debugPrint('🔐 Firebase Auth state determined: ${user?.uid ?? 'null'}');
      return user;
    } catch (e) {
      debugPrint('⚠️ Error waiting for Firebase Auth: $e');
      return null;
    }
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

    // Debug: Print current locale being used
    debugPrint('🌐 Initial app locale: ${locale.languageCode}');

    // Wait for Firebase Auth to properly initialize and determine auth state
    debugPrint('🔐 Waiting for Firebase Auth initialization...');
    final User? currentUser = await _waitForFirebaseAuthInitialization();

    if (currentUser == null) {
      debugPrint('🔐 No authenticated user found, showing login screen');
      return {'route': '/login', 'locale': locale};
    }

    debugPrint('🔐 User authenticated: ${currentUser.uid}, checking profile status...');

    // For authenticated users, check their completion status
    // OPTIMIZATION: Use cached user data if available, otherwise fetch quickly
    try {
      // Try to get from cache first (much faster)
      final cache = MultiLevelCache();
      final cachedUserData = await cache.get<Map<String, dynamic>>('user_${currentUser.uid}');

      Map<String, dynamic>? userData;
      if (cachedUserData != null) {
        userData = cachedUserData;
        debugPrint('⚡ Using cached user data for initial route determination');
      } else {
        // Fallback to Firestore query with timeout to prevent blocking
        final userDocFuture = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        // Add timeout to prevent blocking UI for too long (longer in debug mode)
        final timeoutDuration = kDebugMode ? const Duration(seconds: 15) : const Duration(seconds: 5);
        final userDoc = await userDocFuture.timeout(
          timeoutDuration,
          onTimeout: () {
            debugPrint('⏰ User data fetch timed out, using defaults');
            throw TimeoutException('User data fetch timed out');
          },
        );

        if (userDoc != null && userDoc.exists) {
          userData = userDoc.data()!;

          // Cache only essential routing data to avoid serialization issues
          try {
            final routingData = {
              'role': userData['role'],
              'profileCompleted': userData['profileCompleted'],
              'districtId': userData['districtId'],
            };
            await cache.set('user_${currentUser.uid}', routingData, ttl: Duration(hours: 1));
            debugPrint('✅ Routing data cached successfully');
          } catch (e) {
            debugPrint('⚠️ Failed to cache routing data: $e');
            // Continue without caching - not critical
          }
        }
      }

      if (userData != null) {
        debugPrint('🔍 Raw user data: $userData');

        final role = userData['role'] as String? ?? '';
        final districtId = userData['districtId'] as String? ?? '';

        // Extract location data from electionAreas (new structure)
        String bodyId = '';
        String wardId = '';
        if (userData['electionAreas'] != null && (userData['electionAreas'] as List).isNotEmpty) {
          final electionAreas = userData['electionAreas'] as List;
          final regularArea = electionAreas.firstWhere(
            (area) => area['type'] == 'regular',
            orElse: () => electionAreas.first,
          );

          if (regularArea != null) {
            bodyId = regularArea['bodyId'] ?? '';
            wardId = regularArea['wardId'] ?? '';
          }
        }

        debugPrint('🔍 User state check - Role: "$role", District: "$districtId", Body: "$bodyId", Ward: "$wardId"');

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
          debugPrint('🎯 Redirecting to profile completion - profile not completed');
          return {
            'route': '/profile-completion',
            'locale': locale,
            'userData': userData, // Pass user data to avoid duplicate fetch
          };
        }

        // Step 3: Profile is completed, go to home for all users
        debugPrint('✅ Profile completed, redirecting to home');
        return {'route': '/home', 'locale': locale};
      } else {
        debugPrint('⚠️ User document not found - redirecting to login');
        return {'route': '/login', 'locale': locale};
      }
    } catch (e) {
      debugPrint('⚠️ Error checking user state: $e');
      // On error, if user is authenticated, assume profile completed and go to home
      // This provides a permanent solution for hot reload issues
      if (currentUser != null) {
        debugPrint('🔄 User authenticated but data fetch failed, defaulting to home');
        return {'route': '/home', 'locale': locale};
      } else {
        return {'route': '/login', 'locale': locale};
      }
    }
  }
}
