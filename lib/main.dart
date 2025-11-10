// ignore_for_file: dead_code

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'features/language/controller/language_controller.dart';
import 'services/home_screen_stream_service.dart';
import 'features/highlight/services/highlight_session_service.dart';

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

/// 🚀 FAST STARTUP: Simplified startup data loading for instant app launch
Future<Map<String, dynamic>> _getFastStartupData() async {
  final stopwatch = Stopwatch()..start();

  // 🚀 OPTIMIZATION: Parallel load critical data only
  final results = await Future.wait([
    // Get auth state (fast)
    FirebaseAuth.instance.authStateChanges().first.timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    ),
    // Get app setup state (fast)
    _getAppSetupState().timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => {'isLanguageSelected': false, 'isOnboardingCompleted': false},
    ),
    // Get cached user data if available
    _getCachedUserData().timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => null,
    ),
  ]);

  final user = results[0] as User?;
  final setupState = results[1] as Map<String, dynamic>;
  final cachedData = results[2] as Map<String, dynamic>?;

  final isLoggedIn = user != null;
  final hasCachedData = cachedData != null;
  final isLanguageSelected = setupState['isLanguageSelected'] ?? false;
  final isOnboardingCompleted = setupState['isOnboardingCompleted'] ?? false;

  // 🚀 OPTIMIZATION: Simplified routing logic - let HomeScreen handle complex routing
  String initialRoute;
  if (!isLanguageSelected) {
    initialRoute = AppRouteNames.languageSelection;
  } else if (!isOnboardingCompleted) {
    initialRoute = AppRouteNames.onboarding;
  } else if (!isLoggedIn) {
    initialRoute = AppRouteNames.login;
  } else {
    // 🚀 INSTANT HOME: Always route to home for logged-in users
    // HomeScreen will handle role/profile checks and navigation internally
    initialRoute = AppRouteNames.home;
  }

  AppLogger.core('⚡ Fast startup data ready in ${stopwatch.elapsedMilliseconds}ms: loggedIn=$isLoggedIn, cached=$hasCachedData, language=$isLanguageSelected, onboarding=$isOnboardingCompleted → Route: $initialRoute');

  return {
    'isLoggedIn': isLoggedIn,
    'user': user,
    'isLanguageSelected': isLanguageSelected,
    'isOnboardingCompleted': isOnboardingCompleted,
    'hasCachedData': hasCachedData,
    'cachedData': cachedData,
    'initialRoute': initialRoute,
  };
}

/// Get cached user routing data for instant access
Future<Map<String, dynamic>?> _getCachedUserData() async {
  try {
    final prefs = Get.find<SharedPreferences>();
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

/// Get app setup state (language selection and onboarding completion)
Future<Map<String, dynamic>> _getAppSetupState() async {
  try {
    final prefs = Get.find<SharedPreferences>();

    // Check if language is selected (not first time user)
    final isFirstTime = prefs.getBool('is_first_time') ?? true;
    final isLanguageSelected = !isFirstTime;

    // Check if onboarding is completed
    final isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    AppLogger.core('📱 App setup state: language=$isLanguageSelected, onboarding=$isOnboardingCompleted');

    return {
      'isLanguageSelected': isLanguageSelected,
      'isOnboardingCompleted': isOnboardingCompleted,
    };
  } catch (e) {
    AppLogger.core('⚠️ Failed to get app setup state: $e');
    // Default to not completed if there's an error
    return {
      'isLanguageSelected': false,
      'isOnboardingCompleted': false,
    };
  }
}



/// Get the appropriate route for logged-in users based on role selection and profile completion
Future<String> _getUserFlowRoute(User? user) async {
  if (user == null) return AppRouteNames.login;

  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data();
      final role = userData?['role'] ?? '';
      final roleSelected = userData?['roleSelected'] ?? false;
      final profileCompleted = userData?['profileCompleted'] ?? false;

      AppLogger.core('👤 User flow check: role="$role", roleSelected=$roleSelected, profileCompleted=$profileCompleted');

      if (!roleSelected) {
        return AppRouteNames.roleSelection;
      } else if (!profileCompleted) {
        return AppRouteNames.profileCompletion;
      } else {
        return AppRouteNames.home;
      }
    } else {
      // New user, start with role selection
      AppLogger.core('🆕 New user detected, starting with role selection');
      return AppRouteNames.roleSelection;
    }
  } catch (e) {
    AppLogger.core('⚠️ Error checking user flow state: $e');
    // On error, default to role selection to be safe
    return AppRouteNames.roleSelection;
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



class MyAppContent extends StatefulWidget {
  const MyAppContent({super.key});

  @override
  State<MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<MyAppContent> {
  late StreamSubscription<User?> _authSubscription;
  late StreamSubscription<ThemeData> _themeSubscription;
  late StreamSubscription<Locale> _localeSubscription;
  String _currentRoute = AppRouteNames.home; // Default route
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Get initial startup data
    final startupData = await _getFastStartupData();
    final isLoggedIn = startupData['isLoggedIn'] ?? false;
    final hasCachedData = startupData['hasCachedData'] ?? false;
    final isLanguageSelected = startupData['isLanguageSelected'] ?? false;
    final isOnboardingCompleted = startupData['isOnboardingCompleted'] ?? false;
    final initialRoute = startupData['initialRoute'] as String;

    AppLogger.core('🚀 FAST STARTUP COMPLETE: loggedIn=$isLoggedIn, cached=$hasCachedData, language=$isLanguageSelected, onboarding=$isOnboardingCompleted → Route: $initialRoute');

    // Set initial route
    setState(() {
      _currentRoute = initialRoute;
      _isInitialized = true;
    });

    // Pre-populate cached data if available
    if (isLoggedIn && hasCachedData) {
      final cachedData = startupData['cachedData'] as Map<String, dynamic>?;
      if (cachedData != null) {
        try {
          final homeStreamService = Get.find<HomeScreenStreamService>();
          homeStreamService.preloadWithCachedData(cachedData);
          AppLogger.core('✅ Pre-populated HomeScreenStreamService with cached data');
        } catch (e) {
          AppLogger.core('⚠️ Failed to pre-populate cached data: $e');
        }
      }
    }

    // Listen to theme changes and update GetX theme
    final themeController = Get.find<ThemeController>();
    _themeSubscription = themeController.currentTheme.listen((theme) {
      Get.changeTheme(theme);
    });

    // Listen to locale changes and update GetX locale
    final languageController = Get.find<LanguageController>();
    _localeSubscription = languageController.currentLocale.listen((locale) {
      Get.updateLocale(locale);
    });

    // Listen to auth changes and navigate accordingly
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;

      final isStreamLoggedIn = user != null;
      String newRoute;

      if (!isLanguageSelected) {
        newRoute = AppRouteNames.languageSelection;
      } else if (!isOnboardingCompleted) {
        newRoute = AppRouteNames.onboarding;
      } else if (!isStreamLoggedIn) {
        newRoute = AppRouteNames.login;
      } else {
        // For logged-in users, check user state and navigate appropriately
        newRoute = await _getUserFlowRoute(user);
      }

      AppLogger.core('🔄 Auth change: ${user?.uid ?? 'null'} → Route: $newRoute');

      // Navigate to new route if different from current
      if (newRoute != _currentRoute) {
        setState(() {
          _currentRoute = newRoute;
        });
        // Use GetX navigation to change route
        Get.offAllNamed(newRoute);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _themeSubscription.cancel();
    _localeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while initializing
    if (!_isInitialized) {
      return const MaterialApp(
        home: AnimatedSplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    // Single GetMaterialApp for the entire app - use initial values, changes handled via Get.changeTheme/updateLocale
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return GetMaterialApp(
      title: 'JanMat',
      theme: themeController.currentTheme.value,
      locale: languageController.currentLocale.value,
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
      initialRoute: _currentRoute,
      getPages: AppRoutes.getPages,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap entire app with SafeArea for global safe area handling
        return SafeArea(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
