import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../firebase_options.dart';
import '../../../utils/app_logger.dart';
import '../../services/background_initializer.dart';
import '../../features/user/services/user_token_manager.dart';
import '../../features/user/services/user_status_manager.dart';


/// Service responsible for app initialization and startup configuration
/// Centralizes all Firebase, security, and logging setup for better organization
class AppStartupService {
  static const bool isProduction = kReleaseMode;

  /// Main initialization method called from main()
  Future<void> initialize() async {
    await _initializeFirebase();
    await _initializeTokenManagement();
    await _initializeUserStatusManager();
    await _configureLogging();
    await _setupBackgroundServices();
    await _setupLocalizations();
  }

  /// Initialize Firebase with proper error handling and security setup
  Future<void> _initializeFirebase() async {
    try {
      AppLogger.core('🔄 Initializing Firebase...');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await _setupFirebaseSecurity();
      AppLogger.core('✅ Firebase initialized successfully');
    } catch (e) {
      AppLogger.core('❌ Firebase initialization failed: $e');
      rethrow; // Critical failure, can't proceed without Firebase
    }
  }

  /// Configure Firebase security settings based on environment
  Future<void> _setupFirebaseSecurity() async {
    if (isProduction) {
      try {
        // Production: Use Play Integrity for security
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

        AppLogger.auth('✅ PRODUCTION: Firebase App Check enabled with Play Integrity');
        AppLogger.auth('🔒 SECURITY: App integrity verification active');
      } catch (e) {
        AppLogger.auth('⚠️ PRODUCTION: App Check activation failed: $e');
        AppLogger.auth('📋 NOTE: Continuing without App Check - ensure proper Firebase configuration');
      }

      await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: false);
      AppLogger.auth('✅ PRODUCTION: Firebase Auth app verification enabled');
    } else {
      // Development: Completely disable App Check to avoid Play Integrity issues
      // App Check is not required for Firebase Auth to work
      AppLogger.auth('🔧 DEVELOPMENT: Firebase App Check completely disabled');
      AppLogger.auth('🔒 SECURITY: Basic authentication security active');

      // Keep app verification enabled for development to test real OTP
      await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: false);
      AppLogger.auth('🔧 DEVELOPMENT: Firebase Auth app verification enabled for real OTP testing');
      AppLogger.auth('📋 NOTE: App Check tokens not required for phone authentication');
    }
  }



  /// Configure app logging with file output and filtering
  Future<void> _configureLogging() async {
    try {
      AppLogger.core('🔄 Setting up application logging...');

      // Load environment-based configuration only in debug mode
      if (!isProduction) {
        AppLogger.loadFromEnvironment();
      }

      // Initialize file logging
      await _setupFileLogging();

      // Configure log filters based on environment
      AppLogger.configure(
        chat: true,
        auth: true,
        network: true,
        cache: true,
        database: true,
        ui: isProduction ? false : true, // Only show UI logs in debug
        performance: true,
        common: true,
        monetization: true, // Explicitly enable monetization logs for all platforms
        candidate: true,
        polls: true,
        profile: true,
        settings: true,
        notifications: true,
        core: true,
        highlight: true,
        fcm: kIsWeb ? false : true, // Disable FCM logs on web since FCM is not supported
        video: true,
        razorpay: true,
        trial: true,
        userCache: true,
        localDatabase: true,
        manifesto: true,
        symbol: true,
        abTest: true,
        backgroundSync: true,
        connectionOptimizer: true,
        dataCompression: true,
        errorRecovery: true,
        memoryManager: true,
        multiLevelCache: true,
        progressiveLoader: true,
        realtimeOptimizer: true,
        districtSpotlight: true,
      );

      AppLogger.core('✅ Logging configured successfully');
    } catch (e) {
      AppLogger.core('⚠️ Logging setup failed, continuing without file logging: $e');
      // Don't rethrow - logging failure shouldn't stop app startup
    }
  }

  /// Setup file logging with rotation for production
  Future<void> _setupFileLogging() async {
    try {
      // Determine log file path based on environment
      late String logFilePath;

      if (kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        logFilePath = '${directory.path}/janmat_log.txt';
      } else if (!kReleaseMode) {
        // Debug: Try to log to project directory for easier access
        try {
          final projectDir = Directory.current.path;
          final logsDir = Directory('$projectDir/logs');
          if (!logsDir.existsSync()) {
            logsDir.createSync(recursive: true);
          }
          logFilePath = '${logsDir.path}/janmat_log.txt';
          AppLogger.common('📝 Debug logging to project directory: $logFilePath');
        } catch (e) {
          // Fallback to app directory
          final directory = await getApplicationDocumentsDirectory();
          final logsDir = Directory('${directory.path}/logs');
          await logsDir.create(recursive: true);
          logFilePath = '${logsDir.path}/janmat_log.txt';
          AppLogger.common('📝 Fallback debug logging: $logFilePath');
        }
      } else {
        // Production: App directory only
        final directory = await getApplicationDocumentsDirectory();
        final logsDir = Directory('${directory.path}/logs');
        await logsDir.create(recursive: true);
        logFilePath = '${logsDir.path}/janmat_log.txt';
      }

      // Setup file logging interception with rotation
      final void Function(String? message, {int? wrapWidth}) originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        originalDebugPrint(message, wrapWidth: wrapWidth);
        if (message != null) {
          try {
            final file = File(logFilePath);
            // Rotation: If file exceeds 1MB, rename and create new one
            if (file.existsSync() && file.lengthSync() > 1024 * 1024) { // 1MB
              final backupPath = '${logFilePath}_${DateTime.now().millisecondsSinceEpoch}.txt';
              file.renameSync(backupPath);
              AppLogger.common('📜 Log file rotated: $backupPath');
            }
            file.writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
          } catch (_) {
            // Silently ignore file write errors
          }
        }
      };

      await AppLogger.initFileLogging();
    } catch (e) {
      // Original logging setup as fallback
      AppLogger.common('⚠️ File logging setup failed: $e');
      rethrow; // Re-throw to handle in main()
    }
  }

  /// Setup background services that can run lazily
  Future<void> _setupBackgroundServices() async {
    // Run heavy initialization after startup
    Future.delayed(const Duration(seconds: 3), () {
      try {
        BackgroundInitializer().initializeAllServices();
        AppLogger.core('✅ Background services initialized');
      } catch (e) {
        AppLogger.core('⚠️ Background services initialization failed: $e');
      }
    });
  }

  /// Initialize FCM token management - Only for mobile platforms
  Future<void> _initializeTokenManagement() async {
    if (kIsWeb) {
      AppLogger.core('📱 WEB: Skipping FCM token management (not supported on web)');
      return;
    }

    try {
      AppLogger.core('🔄 Initializing FCM token management...');
      await UserTokenManager().initialize();
      AppLogger.core('✅ FCM token management initialized successfully');
    } catch (e) {
      AppLogger.core('❌ FCM token management initialization failed: $e');
      // Don't rethrow - FCM token issues shouldn't block app startup
    }
  }

  /// Initialize User Status Manager
  Future<void> _initializeUserStatusManager() async {
    try {
      AppLogger.core('🔄 Initializing User Status Manager...');
      await UserStatusManager().initialize();
      AppLogger.core('✅ User Status Manager initialized successfully');
    } catch (e) {
      AppLogger.core('❌ User Status Manager initialization failed: $e');
      // Don't rethrow - status manager issues shouldn't block app startup
    }
  }

  /// Can be extended later for localization pre-loading if needed
  /// Currently handled by Flutter's built-in localization system
  Future<void> _setupLocalizations() async {
    // Localization delegates are loaded automatically when MaterialApp initializes
    AppLogger.core('✅ Localization setup ready');
  }
}
