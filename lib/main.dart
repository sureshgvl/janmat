// ignore_for_file: dead_code

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/common/animated_splash_screen.dart';
import 'core/app_bindings.dart';
import 'core/app_initializer.dart';
import 'core/app_routes.dart';
import 'core/app_route_names.dart';
import 'core/services/app_startup_service.dart';
import 'services/background_initializer.dart';
import 'l10n/app_localizations.dart';
import 'l10n/features/candidate/candidate_localizations.dart';
import 'l10n/features/auth/auth_localizations.dart';
import 'l10n/features/onboarding/onboarding_localizations.dart';
import 'l10n/features/profile/profile_localizations.dart';
import 'l10n/features/notifications/notifications_localizations.dart';
import 'l10n/features/settings/settings_localizations.dart';
import 'utils/app_logger.dart';
import 'utils/performance_monitor.dart';
import 'controllers/theme_controller.dart';
import 'controllers/language_controller.dart';
import 'services/home_screen_stream_service.dart';
import 'services/highlight_session_service.dart';

/// Extension to handle Locale serialization/deserialization for JSON
extension LocaleJsonExtension on Locale {
  /// Convert Locale to a JSON serializable map
  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      if (countryCode != null) 'countryCode': countryCode,
      if (scriptCode != null) 'scriptCode': scriptCode,
    };
  }

/// Create Locale from JSON map
  static Locale fromJson(Map<String, dynamic> json) {
    return Locale.fromSubtags(
      languageCode: json['languageCode'] as String,
      countryCode: json['countryCode'] as String?,
      scriptCode: json['scriptCode'] as String?,
    );
  }
}

/// 🚀 SMART STARTUP: Get auth state and cached data simultaneously for instant home access
Future<Map<String, dynamic>> _getSmartStartupData() async {
  final stopwatch = Stopwatch()..start();

  final results = await Future.wait([
    // Get auth state
    FirebaseAuth.instance.authStateChanges().first.timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    ),
    // Get cached user data (if available)
    _getCachedUserData().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => null,
    ),
  ]);

  final user = results[0] as User?;
  final cachedData = results[1] as Map<String, dynamic>?;

  final isLoggedIn = user != null;
  final hasCachedData = cachedData != null && cachedData.isNotEmpty;

  AppLogger.core('⚡ Smart startup data ready in ${stopwatch.elapsedMilliseconds}ms: loggedIn=$isLoggedIn, cached=$hasCachedData');

        // � DISABLED: Complex pre-loading causing conflicts with HomeScreen stream
        // Let HomeScreen handle its own optimized loading without interference

  return {
    'isLoggedIn': isLoggedIn,
    'hasCachedData': hasCachedData,
    'user': user,
    'cachedData': cachedData,
  };
}

/// Get cached user routing data for instant access
Future<Map<String, dynamic>?> _getCachedUserData() async {
  try {
    final prefs = await Get.find<SharedPreferences>();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return null;

    // Try to get routing data from cache
    final routingKey = 'routing_data_$userId';
    final routingData = prefs.getString(routingKey);
    if (routingData != null) {
      return Map<String, dynamic>.from(jsonDecode(routingData));
    }
  } catch (e) {
    AppLogger.core('⚠️ Failed to get cached user data: $e');
  }
  return null;
}

/// Pre-load candidate home data in background for instant access
Future<void> _preloadCandidateHomeData(String userId) async {
  try {
    AppLogger.core('🔄 Pre-loading candidate home data for instant access...');
    // This will trigger background loading in HomeScreenStreamService
    // Implementation will be added there
  } catch (e) {
    AppLogger.core('⚠️ Pre-loading failed: $e');
  }
}

void main() async {
  // Ensure Flutter binding is initialized for safety
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST before any other initialization
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Failed to load .env file, using defaults: $e');
    // Continue with defaults if .env loading fails
  }

  // PERFORMANCE TRACKING: Start app launch timer
  final appStartTime = DateTime.now();
  print('🚀 APP LAUNCH START: ${appStartTime.toIso8601String()}');

  // PERFORMANCE: Start performance monitoring immediately
  PerformanceMonitor().startTimer('app_startup');

  // Enable testing mode for better emulator performance during development
  // Set to false for production builds
  const bool isTesting = false; // Change to false for production

  if (isTesting) {
    AppInitializer.testingMode = true;
    BackgroundInitializer.testingMode = true;
  }

  // Initialize ThemeController early
  Get.put<ThemeController>(ThemeController());
  // Initialize LanguageController early for reactive locale
  Get.put<LanguageController>(LanguageController());
  // Initialize SharedPreferences for fast cached data access
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);
  AppLogger.core('✅ SharedPreferences initialized');

  // Initialize all services through the centralized startup service
  // This replaces all Firebase, logging, and service initialization
  try {
    final startupService = AppStartupService();
    await startupService.initialize();
    AppLogger.core('✅ App startup service initialized successfully');
  } catch (e) {
    AppLogger.core('❌ App startup failed: $e');
    // Continue with app initialization but note the error
    // In a real production app, you might want to show an error screen here
  }

  // Initialize app-specific services (keep separate from core startup)
  final initializer = AppInitializer();
  await initializer.initialize();

  PerformanceMonitor().stopTimer('app_startup');
  PerformanceMonitor().logSlowOperation('app_startup', 2000); // Log if startup > 2 seconds

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final HighlightSessionService _sessionService = HighlightSessionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.core('📱 App lifecycle observer initialized');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.core('🧹 App lifecycle observer disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.core('🔄 App state: $state');

    switch (state) {
      case AppLifecycleState.inactive:
        AppLogger.core('🏃 App became inactive');
        break;
      case AppLifecycleState.paused:
        AppLogger.core('😴 App paused (background) - ending highlight session');
        // End the current highlight session when app goes to background
        _sessionService.endSession();
        break;
      case AppLifecycleState.resumed:
        AppLogger.core('🎉 App resumed (foreground)');
        // Useful for analytics: user returned to the app
        // Session will be created automatically when needed
        break;
      case AppLifecycleState.detached:
        AppLogger.core('🔌 App detached (killed) - ending highlight session');
        // End session when app is killed
        _sessionService.endSession();
        break;
      case AppLifecycleState.hidden:
        AppLogger.core('👁️ App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MyAppContent();
  }
}

/// Build app with cached data for instant access
Widget _buildAppWithCachedData(String initialRoute, Map<String, dynamic> startupData) {
  final cachedData = startupData['cachedData'] as Map<String, dynamic>?;

  return Obx(() {
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();
    final currentLocale = languageController.currentLocale.value;

    // Smooth transition when language changes
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: GetMaterialApp(
        key: ValueKey('${currentLocale.languageCode}_cached'), // Unique key for cached route
        title: 'JanMat',
        theme: themeController.currentTheme.value,
        locale: currentLocale,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          CandidateLocalizations.delegate,
          AuthLocalizations.delegate,
          OnboardingLocalizations.delegate,
          ProfileLocalizations.delegate,
          NotificationsLocalizations.delegate,
          SettingsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supported in supportedLocales) {
            if (supported.languageCode == locale?.languageCode) {
              return supported;
            }
          }
          return const Locale('en'); // Fallback to English
        },
        initialBinding: AppBindings(), // Use standard bindings, let HomeScreen handle optimization
        initialRoute: initialRoute,
        getPages: AppRoutes.getPages,
        debugShowCheckedModeBanner: false,
      ),
    );
  });
}

/// Build initial binding with cached data pre-populated
Bindings _buildCachedInitialBinding(Map<String, dynamic>? cachedData) {
  return BindingsBuilder(() {
    // Use full AppBindings but pre-populate with cached data
    AppBindings().dependencies();

    // Pre-populate cached data into services for instant access
    if (cachedData != null) {
      try {
        final homeStreamService = Get.find<HomeScreenStreamService>();
        // Pre-populate HomeScreenStreamService with cached data
        homeStreamService.preloadWithCachedData(cachedData);
        AppLogger.core('✅ Pre-populated HomeScreenStreamService with cached data');
      } catch (e) {
        AppLogger.core('⚠️ Failed to pre-populate cached data: $e');
      }
    }
  });
}

class MyAppContent extends StatelessWidget {
  const MyAppContent({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 SMART STARTUP: Show home immediately if cached data available, else quick splash
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSmartStartupData(),
      builder: (context, snapshot) {
        // Show brief splash while checking auth/cache state
        if (snapshot.connectionState != ConnectionState.done) {
          AppLogger.core('⚡ FAST STARTUP: Checking auth and cache state...');
          return const MaterialApp(
            home: AnimatedSplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        final startupData = snapshot.data!;
        final isLoggedIn = startupData['isLoggedIn'] ?? false;
        final hasCachedData = startupData['hasCachedData'] ?? false;
        final user = startupData['user'] as User?;

        final String initialRoute = isLoggedIn ? AppRouteNames.home : AppRouteNames.login;
        AppLogger.core('🚀 FAST STARTUP COMPLETE: loggedIn=$isLoggedIn, cached=$hasCachedData → Route: $initialRoute');

        // 🔥 INSTANT HOME ACCESS: If logged in AND cached, pass cached data directly
        if (isLoggedIn && hasCachedData) {
          return _buildAppWithCachedData(initialRoute, startupData);
        }

        // REACTIVE AUTH STATE: Fallback to stream-based auth for non-cached users
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            final streamUser = authSnapshot.data;
            final isStreamLoggedIn = streamUser != null;

            final String streamRoute = isStreamLoggedIn ? AppRouteNames.home : AppRouteNames.login;
            AppLogger.core('🔄 Auth stream: ${streamUser?.uid ?? 'null'} → Route: $streamRoute');

            return Obx(() {
              final themeController = Get.find<ThemeController>();
              final languageController = Get.find<LanguageController>();
              final currentLocale = languageController.currentLocale.value;

              // Smooth transition when language changes
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: GetMaterialApp(
                  key: ValueKey(currentLocale.languageCode), // Unique key for animation
                  title: 'JanMat',
                  theme: themeController.currentTheme.value,
                  locale: currentLocale,  // Reactive locale binding
                  localizationsDelegates: [
                    ...AppLocalizations.localizationsDelegates,
                    CandidateLocalizations.delegate,
                    AuthLocalizations.delegate,
                    OnboardingLocalizations.delegate,
                    ProfileLocalizations.delegate,
                    NotificationsLocalizations.delegate,
                    SettingsLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  localeResolutionCallback: (locale, supportedLocales) {
                    for (var supported in supportedLocales) {
                      if (supported.languageCode == locale?.languageCode) {
                        return supported;
                      }
                    }
                    return const Locale('en'); // Fallback to English
                  },
                  initialBinding: AppBindings(),
                  initialRoute: initialRoute,
                  getPages: AppRoutes.getPages,
                  debugShowCheckedModeBanner: false,
                ),
              );
            });
          },
        );
      },
    );
  }
}
