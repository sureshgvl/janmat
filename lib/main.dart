// ignore_for_file: dead_code

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io';

// Remove unused import that was causing compilation issues

import 'features/common/animated_splash_screen.dart';
import 'features/common/file_storage_manager.dart';
import 'core/app_bindings.dart';
import 'core/app_initializer.dart';
import 'core/app_routes.dart';
import 'core/app_route_names.dart';
import 'core/services/app_startup_service.dart';
import 'core/services/prefs_service.dart';
import 'services/background_initializer.dart';
import 'core/portrait_wrapper.dart';
import 'l10n/app_localizations.dart';
import 'l10n/features/candidate/candidate_localizations.dart';
import 'l10n/features/auth/auth_localizations.dart';
import 'l10n/features/onboarding/onboarding_localizations.dart';
import 'l10n/features/profile/profile_localizations.dart';
import 'l10n/features/notifications/notifications_localizations.dart';
import 'l10n/features/settings/settings_localizations.dart';
import 'l10n/features/chat/chat_localizations.dart';
import 'utils/app_logger.dart';
import 'utils/performance_monitor.dart';
import 'controllers/theme_controller.dart';
import 'core/services/fast_startup_coordinator.dart';
import 'controllers/background_color_controller.dart';
import 'features/language/controller/language_controller.dart';
import 'services/home_screen_stream_service.dart';
import 'features/user/services/user_status_manager.dart';
import 'features/highlight/services/highlight_session_service.dart';
import 'core/services/cache_service.dart';

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
    // Get auth state (OPTIMIZED TIMEOUT: Reduced for 2-second silent login performance)
    FirebaseAuth.instance.authStateChanges().first.timeout(
      const Duration(seconds: 2), // Reduced for lightning-fast 2-second silent login
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

  // 🚀 OPTIMIZATION: Smart routing logic for logged-in users
  String initialRoute;
  if (!isLoggedIn) {
    // Not logged in - start from language selection
    if (!isLanguageSelected) {
      initialRoute = AppRouteNames.languageSelection;
    } else {
      // Language selected but not logged in - go to login
      initialRoute = AppRouteNames.login;
    }
  } else {
    // 🔥 LOGGED-IN USER: Skip onboarding for returning users
    // HomeScreen will handle role/profile checks and navigation internally
    // If user was already past role selection, they won't see it again
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



/// Get the appropriate route for logged-in users with pre-navigation flow control
Future<String> _getUserFlowRoute(User? user) async {
  if (user == null) return AppRouteNames.login;

  try {
    // 🚀 Fetch user data BEFORE navigation to control flow
    AppLogger.core('🔍 Fetching user data for flow control...');

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () {
          AppLogger.core('⏰ User data fetch timeout - will try cached routing data');
          // Don't return invalid cast, just let timeout exception propagate to catch block
          throw Exception('User data fetch timeout');
        });

    if (userDoc.exists) {
      final userData = userDoc.data();
      final role = userData?['role'] ?? '';
      final roleSelected = userData?['roleSelected'] ?? false;
      final profileCompleted = userData?['profileCompleted'] ?? false;

      AppLogger.core('✅ User data: role="$role", roleSelected=$roleSelected, profileCompleted=$profileCompleted');

      // 🎯 CLEAN FLOW CONTROL: Navigate based on user completion status
      // Database is fresh - no legacy or corruption fixes needed
      if (!roleSelected) {
        AppLogger.core('🎯 → Role selection screen');
        return AppRouteNames.roleSelection;
      } else if (!profileCompleted) {
        AppLogger.core('🎯 → Profile completion screen');
        return AppRouteNames.profileCompletion;
      } else {
        AppLogger.core('🎯 → Home screen (setup complete)');
        return AppRouteNames.home;
      }
    } else {
      // 🆕 NEW USER: Always start with role selection
      AppLogger.core('🆕 New user → Role selection screen');
      return AppRouteNames.roleSelection;
    }
  } catch (e) {
    AppLogger.core('❌ User flow error: $e');
    // On error, try to use cached routing data as fallback
    final cachedRoute = _tryGetCachedRoute(user.uid);
    if (cachedRoute != null) {
      AppLogger.core('✨ Using cached route as fallback: $cachedRoute');
      return cachedRoute;
    }
    // Last resort: default to home for existing users to not disrupt experience
    AppLogger.core('💔 No cached route available, defaulting to home');
    return AppRouteNames.home;
  }
}

/// Try to get cached routing data when Firebase is unavailable
String? _tryGetCachedRoute(String userId) {
  try {
    final prefs = Get.find<SharedPreferences>();
    final routingKey = 'routing_data_$userId';
    final routingData = prefs.getString(routingKey);
    if (routingData != null) {
      final data = Map<String, dynamic>.from(jsonDecode(routingData));
      final hasCompletedProfile = data['hasCompletedProfile'] ?? false;
      final hasSelectedRole = data['hasSelectedRole'] ?? false;

      if (hasSelectedRole && hasCompletedProfile) {
        return AppRouteNames.home;
      } else if (hasSelectedRole && !hasCompletedProfile) {
        return AppRouteNames.profileCompletion;
      } else {
        return AppRouteNames.roleSelection;
      }
    }
  } catch (e) {
    AppLogger.core('⚠️ Failed to get cached route: $e');
  }
  return null;
}

/// Get cached user routing data synchronously (for fallback)
Map<String, dynamic>? _getCachedUserDataSync() {
  try {
    final prefs = Get.find<SharedPreferences>();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return null;

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

/// 🚨 CRITICAL FIX: Sync UserStatusManager to prevent HomeScreen navigation conflicts
/// This ensures UserStatusManager has the same data as Firebase after corrections
Future<void> _syncUserStatusManager(String userId, {
  String? role,
  bool? roleSelected,
  bool? profileCompleted,
}) async {
  try {
    AppLogger.core('🔄 Syncing UserStatusManager with corrected data...');

    // Update UserStatusManager (this updates SharedPreferences, cache, and Firebase consistently)
    final statusManager = Get.find<UserStatusManager>();

    if (role != null) {
      await statusManager.updateRole(userId, role);
    }

    if (roleSelected != null) {
      // We need to update roleSelected separately since updateRole() sets it to true
      // But we might need to set other combinations
      if (roleSelected && role == null) {
        // Only roleSelected is being updated, update in Firebase directly
        await FirebaseFirestore.instance.collection('users').doc(userId).update({'roleSelected': true});
      }
    }

    if (profileCompleted != null && profileCompleted) {
      await statusManager.updateProfileCompleted(userId, profileCompleted);
    }

    AppLogger.core('✅ UserStatusManager synced successfully');
  } catch (e) {
    AppLogger.core('⚠️ UserStatusManager sync failed: $e');
    // Don't throw - this shouldn't block the main flow
  }
}

void main() async {
  // Ensure Flutter binding is initialized for safety
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences service
  await PrefsService.init();

  // Initialize databaseFactory for SQLite before any other initialization
  if (kIsWeb) {
    // Web: Initialize Sqflite for web early
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop: Initialize FFI for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize workmanager for background tasks (mobile only)
  if (!kIsWeb) {
    // Initialize workmanager
    // (The WorkManager callback is handled in MobileSyncService)
  }

  // Initialize Hive for local storage (web uses IndexedDB)
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    // Mobile also uses Hive for media queue
    await Hive.initFlutter();
  }

  // Initialize CacheService after Hive
  await CacheService.initialize();

  // Clear web file data on startup to prevent storage quota issues
  if (kIsWeb) {
    try {
      // Import here to avoid circular dependencies
      final fileStorageManager = FileStorageManager();
      fileStorageManager.clearAllWebData();
      AppLogger.core('🧹 Cleared web file data on app startup');
    } catch (e) {
      AppLogger.core('⚠️ Failed to clear web file data on startup: $e');
    }
  }

  // 🚀 SMART PERSISTENCE: Uses Firebase defaults (works on web & mobile without crashes)
  // Note: Firebase automatically chooses optimal persistence per platform
  AppLogger.core('🚀 Using Firebase automatic persistence for reliable cross-platform silent login');

  // Web-specific configuration is handled by web/index.html
  // The HTML sets up centering and mobile viewport automatically

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

  // 🚀 FAST STARTUP: Use the new FastStartupCoordinator to show the splash screen immediately
  // while initializing in the background
  print('🔧 FORCED MONETIZATION LOG TEST - Web logging should work: ${DateTime.now()}');
  AppLogger.monetization('🧪 TESTING MONETIZATION LOGS ON WEB - This should appear with 💰 emoji');
  AppLogger.core('🚀 FAST STARTUP: Starting fast app initialization...');

  // Show the splash screen immediately with initialization running in background
  runApp(const FastSplashApp());

  // Start background initialization and navigate when ready
  try {
    final coordinator = FastStartupCoordinator();
    final startupData = await coordinator.initializeFast();

    AppLogger.core('✅ FAST STARTUP: Initialization complete, navigating to main app...');

    // Navigate to main app with startup data
    runApp(MyFastApp(startupData: startupData));
  } catch (e) {
    AppLogger.coreError('❌ FAST STARTUP FAILED: Falling back to traditional startup', error: e);
    // Fallback to traditional startup
    runApp(const MyApp());
  }
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
        //AppLogger.core('🏃 App became inactive');
        break;
      case AppLifecycleState.paused:
        AppLogger.core('😴 App paused (background) - ending highlight session');
        // End the current highlight session when app goes to background
        _sessionService.endSession();
        break;
      case AppLifecycleState.resumed:
        //AppLogger.core('🎉 App resumed (foreground)');
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
        // Use context-safe navigation to avoid GetX context issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Get.offAllNamed(newRoute);
          }
        });
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
        ChatLocalizations.delegate,
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
        // Wrap entire app with PortraitWrapper for web/desktop centering + SafeArea
        return PortraitWrapper(
          child: SafeArea(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// 🚀 FAST STARTUP: Simple splash screen app that shows immediately
class FastSplashApp extends StatelessWidget {
  const FastSplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AnimatedSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 🚀 FAST STARTUP: Main app with pre-initialized data
class MyFastApp extends StatefulWidget {
  final Map<String, dynamic> startupData;

  const MyFastApp({super.key, required this.startupData});

  @override
  State<MyFastApp> createState() => _MyFastAppState();
}

class _MyFastAppState extends State<MyFastApp> with WidgetsBindingObserver {
  late StreamSubscription<User?> _authSubscription;
  late StreamSubscription<ThemeData> _themeSubscription;
  late StreamSubscription<Locale> _localeSubscription;
  late String _currentRoute;
  final HighlightSessionService _sessionService = HighlightSessionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.core('📱 Fast App lifecycle observer initialized');

    // Get initial route from startup data
    _currentRoute = widget.startupData['initialRoute'] as String;


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
      final isLoggedIn = widget.startupData['isLoggedIn'] as bool;
      // For fast startup, these values aren't available, so check SharedPreferences directly
      final prefs = Get.find<SharedPreferences>();
      final isLanguageSelected = !(prefs.getBool('is_first_time') ?? true);
      final isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

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

      AppLogger.core('🔄 Fast App Auth change: ${user?.uid ?? 'null'} → Route: $newRoute');

      // Navigate to new route if different from current
      if (newRoute != _currentRoute) {
        setState(() {
          _currentRoute = newRoute;
        });
        // Use context-safe navigation to avoid GetX context issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Get.offAllNamed(newRoute);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _themeSubscription.cancel();
    _localeSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.core('🧹 Fast App lifecycle observer disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.core('🔄 Fast App state: $state');

    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        AppLogger.core('😴 Fast App paused (background) - ending highlight session');
        // End the current highlight session when app goes to background
        _sessionService.endSession();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        AppLogger.core('🔌 Fast App detached (killed) - ending highlight session');
        // End session when app is killed
        _sessionService.endSession();
        break;
      case AppLifecycleState.hidden:
        AppLogger.core('👁️ Fast App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ChatLocalizations.delegate,
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
        // Wrap entire app with PortraitWrapper for web/desktop centering + SafeArea
        return PortraitWrapper(
          child: SafeArea(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
