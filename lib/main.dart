import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/common/animated_splash_screen.dart';
import 'core/app_bindings.dart';
import 'core/app_initializer.dart';
import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'core/initial_app_data_service.dart';
import 'l10n/app_localizations.dart';
import 'l10n/features/candidate/candidate_localizations.dart';
import 'l10n/features/auth/auth_localizations.dart';
import 'l10n/features/profile/profile_localizations.dart';

void main() async {
  final initializer = AppInitializer();
  await initializer.initialize();

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

        return GetMaterialApp(
          title: 'JanMat',
          theme: AppTheme.lightTheme,
          locale: initialLocale,
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            CandidateLocalizations.delegate,
            AuthLocalizations.delegate,
            ProfileLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          initialBinding: AppBindings(),
          initialRoute: initialRoute,
          getPages: AppRoutes.getPages,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

