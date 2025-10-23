// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'features/common/animated_splash_screen.dart';
import 'core/app_bindings.dart';
import 'core/app_initializer.dart';
import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'core/initial_app_data_service.dart';
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

void main() async {
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

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check
  // IMPORTANT: For production builds, ensure App Check is ENABLED for security
  // TODO: BEFORE PRODUCTION RELEASE - Enable App Check with proper configuration
  // TODO: Set up debug tokens in Firebase Console for development testing
  // TODO: Configure SHA-256 fingerprints in Google Play Console
  const bool isProduction = bool.fromEnvironment('dart.vm.product');
  if (isProduction) {
    // PRODUCTION: Enable App Check for security
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    AppLogger.auth('✅ Firebase App Check enabled for production security');
  } else {
    // DEVELOPMENT: Disable App Check to avoid integrity check failures during testing
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
    AppLogger.auth('⚠️ Firebase App Check disabled for development mode');
    AppLogger.auth('🚨 REMINDER: Re-enable App Check before production release!');
    AppLogger.auth('📋 TODO: Configure debug tokens in Firebase Console');
    AppLogger.auth('📋 TODO: Set up SHA-256 fingerprints in Google Play Console');
  }

  // PRODUCTION CHECKLIST - Uncomment and complete before release:
  /*
  PRODUCTION CHECKLIST:
  □ 1. Change isProduction logic to detect release builds
  □ 2. Enable App Check with AndroidProvider.playIntegrity
  □ 3. Set up debug tokens in Firebase Console > App Check
  □ 4. Configure SHA-256 fingerprints in Google Play Console
  □ 5. Test login with debug tokens on development devices
  □ 6. Verify App Check is working in production (check Firebase Console)
  □ 7. Monitor for any login failures after release
  */

  final initializer = AppInitializer();
  await initializer.initialize();

  // Configure app logger for filtered logging
  // Change this configuration to control which logs are shown
  AppLogger.configure(
    chat: true,       // Reduced logging for performance
    auth: true,        // Keep auth logs for debugging
    network: true,    // Reduced network logging
    cache: true,       // Keep cache logs for optimization tracking
    database: true,   // Reduced database logging
    ui: true,         // Hide UI interaction logs (can be noisy)
    performance: true, // Show performance monitoring logs
    districtSpotlight: true, // Reduced spotlight logging
  );

  PerformanceMonitor().stopTimer('app_startup');
  PerformanceMonitor().logSlowOperation('app_startup', 2000); // Log if startup > 2 seconds

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: InitialAppDataService().getInitialAppData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: AnimatedSplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        final appData = snapshot.data ?? {'route': '/login', 'locale': null};
        final initialRoute = appData['route'] as String;
        final initialLocale = appData['locale'] as Locale?;

        return Obx(() {
          final themeController = Get.find<ThemeController>();
          return GetMaterialApp(
            title: 'JanMat',
            theme: themeController.currentTheme.value,
            locale: initialLocale,
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
            initialBinding: AppBindings(),
            initialRoute: initialRoute,
            getPages: AppRoutes.getPages,
            debugShowCheckedModeBanner: false,
          );
        });
      },
    );
  }
}

