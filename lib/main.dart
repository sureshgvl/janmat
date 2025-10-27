// ignore_for_file: dead_code

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'features/common/animated_splash_screen.dart';
import 'core/app_bindings.dart';
import 'core/app_initializer.dart';
import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'core/app_route_names.dart';
import 'core/initial_app_data_service.dart';
import 'core/services/app_startup_service.dart';
import 'services/background_initializer.dart';
import 'services/language_service.dart';
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
        AppLogger.core('😴 App paused (background)');
        // Useful for analytics: user left the app
        break;
      case AppLifecycleState.resumed:
        AppLogger.core('🎉 App resumed (foreground)');
        // Useful for analytics: user returned to the app
        // Could potentially refresh data here
        break;
      case AppLifecycleState.detached:
        AppLogger.core('🔌 App detached (killed)');
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

class MyAppContent extends StatelessWidget {
  const MyAppContent({super.key});

  @override
  Widget build(BuildContext context) {
    // SMARTER SPLASH TIMING: Minimum 2 seconds, or when Firebase auth is ready
    // This ensures users see the splash animation but doesn't unnecessarily delay the app
    return FutureBuilder<void>(
      future: Future.wait([
        Future.delayed(const Duration(seconds: 2)), // Minimum 2 seconds
        FirebaseAuth.instance.authStateChanges().first, // Wait for auth state
      ]),
      builder: (context, splashSnapshot) {
        if (splashSnapshot.connectionState != ConnectionState.done) {
          // 🔥 ALWAYS SHOW ANIMATED SPLASH FIRST FOR FULL ANIMATION
          AppLogger.core('❄️ SHOWING ANIMATED SPLASH SCREEN (min 2 seconds)...');
          return const MaterialApp(
            home: AnimatedSplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        AppLogger.core('❄️ SPLASH SCREEN COMPLETE - STARTING AUTH FLOW...');

        // REACTIVE AUTH STATE: Handle Firebase auth state after splash
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            final isLoggedIn = user != null;

            final String initialRoute = isLoggedIn ? AppRouteNames.home : AppRouteNames.login;
            AppLogger.core('🔄 Auth state: ${user?.uid ?? 'null'} → Route: $initialRoute');

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
