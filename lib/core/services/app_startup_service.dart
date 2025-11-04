import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../firebase_options.dart';
import '../../../utils/app_logger.dart';
import '../../services/background_initializer.dart';
import '../../services/user_token_manager.dart';


/// Service responsible for app initialization and startup configuration
/// Centralizes all Firebase, security, and logging setup for better organization
class AppStartupService {
  static const bool isProduction = kReleaseMode;

  /// Main initialization method called from main()
  Future<void> initialize() async {
    await _initializeFirebase();
    await _initializeTokenManagement();
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
        // ✅ ENABLE: Play Integrity for production builds
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

        AppLogger.auth('✅ PRODUCTION: Firebase App Check enabled with Play Integrity');
        AppLogger.auth('🔒 SECURITY: App integrity verification active');
      } catch (e) {
        AppLogger.auth('⚠️ PRODUCTION: App Check activation failed: $e');
        AppLogger.auth('📋 NOTE: Continuing without App Check - ensure proper Firebase configuration');
        // Continue without App Check rather than failing the app
      }

      // ✅ RE-ENABLE: App verification for Auth now that fingerprints are configured
      await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: false);
      AppLogger.auth('✅ PRODUCTION: Firebase Auth app verification enabled with proper SHA fingerprints');
      AppLogger.auth('🔒 SECURITY: Full authentication security active');
    } else {
      // Development: Relax security for easier testing
      await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);

      AppLogger.auth('🔧 DEVELOPMENT: Firebase security relaxed for testing');
    }
  }



  /// Configure app logging with file output and filtering
  Future<void> _configureLogging() async {
    try {
      AppLogger.core('🔄 Setting up application logging...');

      // Load environment-based configuration first
      AppLogger.loadFromEnvironment();

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

  /// Initialize FCM token management
  Future<void> _initializeTokenManagement() async {
    try {
      AppLogger.core('🔄 Initializing FCM token management...');
      await UserTokenManager().initialize();
      AppLogger.core('✅ FCM token management initialized successfully');
    } catch (e) {
      AppLogger.core('❌ FCM token management initialization failed: $e');
      // Don't rethrow - FCM token issues shouldn't block app startup
    }
  }

  /// Can be extended later for localization pre-loading if needed
  /// Currently handled by Flutter's built-in localization system
  Future<void> _setupLocalizations() async {
    // Localization delegates are loaded automatically when MaterialApp initializes
    AppLogger.core('✅ Localization setup ready');
  }
}
