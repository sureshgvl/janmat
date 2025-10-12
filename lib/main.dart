// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'controllers/theme_controller.dart';

void main() async {
  // Enable testing mode for better emulator performance during development
  // Set to false for production builds
  const bool isTesting = false; // Change to false for production

  if (isTesting) {
    AppInitializer.testingMode = true;
    BackgroundInitializer.testingMode = true;
  }

  // Initialize ThemeController early
  Get.put<ThemeController>(ThemeController());

  final initializer = AppInitializer();
  await initializer.initialize();

  // Configure app logger for filtered logging
  // Change this configuration to control which logs are shown
  AppLogger.configure(
    chat: true,        // Show chat-related logs
    auth: true,        // Show authentication logs
    network: true,     // Show network request logs
    cache: true,       // Show cache operation logs
    database: true,    // Show database operation logs
    ui: false,         // Hide UI interaction logs (can be noisy)
    performance: true, // Show performance monitoring logs
    districtSpotlight: true, // Show district spotlight caching logs
  );

  // Quick setup options (uncomment one):
  // AppLogger.enableAllLogs();      // Show all logs
  // AppLogger.enableChatOnly();     // Show only chat logs
  // AppLogger.enableCoreOnly();     // Show core functionality logs
  // AppLogger.disableAllLogs();     // Disable all app logs

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

