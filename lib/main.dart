// ignore_for_file: dead_code

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Initialize file logging for project directory
  await AppLogger.initFileLogging();

  // Determine log file path
  late String logFilePath;
  if (kIsWeb) {
    // Web: use app docs
    final directory = await getApplicationDocumentsDirectory();
    logFilePath = '${directory.path}/janmat_log.txt';
  } else if (kDebugMode) {
    // Debug mode: try project logs directory first for easier access
    try {
      final projectDir = Directory.current.path;
      final logsDir = Directory('$projectDir/logs');
      if (!logsDir.existsSync()) logsDir.createSync(recursive: true);
      logFilePath = '${logsDir.path}/janmat_log.txt';
      AppLogger.common('📝 Debug logging to project directory: $logFilePath');
    } catch (e) {
      // Fallback to app docs
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      await logsDir.create(recursive: true);
      logFilePath = '${logsDir.path}/janmat_log.txt';
      AppLogger.common('📝 Fallback logging to app docs: $logFilePath');
    }
  } else {
    // Production: app docs
    final directory = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${directory.path}/logs');
    await logsDir.create(recursive: true);
    logFilePath = '${logsDir.path}/janmat_log.txt';
  }

  // Override debugPrint to log to file
  final void Function(String? message, {int? wrapWidth}) originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    originalDebugPrint(message, wrapWidth: wrapWidth);
    if (message != null) {
      try {
        File(logFilePath).writeAsStringSync('$message\n', mode: FileMode.append);
      } catch (_) {
        // Ignore file write errors
      }
    }
  };

  PerformanceMonitor().stopTimer('app_startup');
  PerformanceMonitor().logSlowOperation('app_startup', 2000); // Log if startup > 2 seconds

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // REACTIVE AUTH STATE: Use StreamBuilder for Firebase auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final isLoggedIn = user != null;

        // Determine home widget based on auth state
        final String initialRoute = isLoggedIn ? '/home' : '/login';

        AppLogger.core('🔄 Auth state changed - User: ${user?.uid ?? 'null'} - Route: $initialRoute');

        return Obx(() {
          final themeController = Get.find<ThemeController>();
          return GetMaterialApp(
            title: 'JanMat',
            theme: themeController.currentTheme.value,
            // Let GetX manage locale internally without forcing rebuilds
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
