import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Custom logging utility for filtering and controlling app logs
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: kDebugMode ? Level.verbose : Level.warning,
  );

  // File logging
  static RandomAccessFile? _logFile;
  static bool _fileLoggingEnabled = true;
  static IOSink? _fileSink;

  // Initialize file logging
  static Future<void> initFileLogging() async {
    if (!_fileLoggingEnabled) return;

    try {
      // Try to write to project logs directory first, fallback to app documents
      String logPath;

      try {
        // For development: Try writing to project's logs directory
        final projectDir = Directory.current;
        final logsDir = Directory('${projectDir.path}/logs');

        // Create logs directory if it doesn't exist
        if (!await logsDir.exists()) {
          await logsDir.create(recursive: true);
        }

        logPath = '${logsDir.path}/janmat_logs.txt';
        AppLogger.common('📝 Using project directory logs: $logPath');
      } catch (e) {
        // Fallback to app documents directory (production/some development cases)
        final directory = await getApplicationDocumentsDirectory();
        logPath = '${directory.path}/janmat_logs.txt';
        AppLogger.common('📝 Fallback to app documents directory: $logPath');
      }

      // Create or truncate the file
      final logFile = File(logPath);
      _fileSink = logFile.openWrite(mode: FileMode.append);

      // Write header to file
      final header = '\n\n=== JANMAT LOGS SESSION STARTED ${DateTime.now()} ===\n';
      _fileSink?.write(header);
      _fileSink?.flush();

      AppLogger.common('📝 File logging initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize file logging: $e');
      _fileLoggingEnabled = false;
    }
  }

  // Close file logging
  static Future<void> closeFileLogging() async {
    if (!_fileLoggingEnabled || _fileSink == null) return;

    try {
      _fileSink?.write('\n=== JANMAT LOGS SESSION ENDED ${DateTime.now()} ===\n\n');
      await _fileSink?.flush();
      await _fileSink?.close();
      _fileSink = null;
      AppLogger.common('📝 File logging closed');
    } catch (e) {
      // Silent failure when closing
    }
  }

  // Write to log file
  static Future<void> _writeToLogFile(String message, {String? level}) async {
    if (!_fileLoggingEnabled || _fileSink == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final formattedMessage = '${level ?? 'INFO'} [$timestamp] $message\n';
      _fileSink?.write(formattedMessage);
      await _fileSink?.flush();
    } catch (e) {
      // Silent failure during file writing to avoid log loops
    }
  }

  // Log level control
  static bool _showChatLogs = true;
  static bool _showAuthLogs = true;
  static bool _showNetworkLogs = true;
  static bool _showCacheLogs = true;
  static bool _showDatabaseLogs = true;
  static bool _showUILogs = false; // UI logs can be noisy
  static bool _showPerformanceLogs = true;
  static bool _showCommonLogs = true;
  static bool _showMonetizationLogs = true;
  static bool _showCandidateLogs = true;
  static bool _showPollsLogs = true;
  static bool _showProfileLogs = true;
  static bool _showSettingsLogs = true;
  static bool _showNotificationsLogs = true;
  static bool _showCoreLogs = true;
  static bool _showHighlightLogs = true;
  static bool _showFCMLogs = true;
  static bool _showVideoLogs = true;
  static bool _showRazorpayLogs = true;
  static bool _showTrialLogs = true;
  static bool _showUserCacheLogs = true;
  static bool _showLocalDatabaseLogs = true;
  static bool _showManifestoLogs = true;
  static bool _showSymbolLogs = true;
  static bool _showABTestLogs = true;
  static bool _showBackgroundSyncLogs = true;
  static bool _showConnectionOptimizerLogs = true;
  static bool _showDataCompressionLogs = true;
  static bool _showErrorRecoveryLogs = true;
  static bool _showMemoryManagerLogs = true;
  static bool _showMultiLevelCacheLogs = true;
  static bool _showProgressiveLoaderLogs = true;
  static bool _showRealtimeOptimizerLogs = true;
  static bool _showDistrictSpotlightLogs = true;

  // Control which logs to show
  static void configure({
    bool chat = true,
    bool auth = true,
    bool network = true,
    bool cache = true,
    bool database = true,
    bool ui = false,
    bool performance = true,
    bool common = true,
    bool monetization = true,
    bool candidate = true,
    bool polls = true,
    bool profile = true,
    bool settings = true,
    bool notifications = true,
    bool core = true,
    bool highlight = true,
    bool fcm = true,
    bool video = true,
    bool razorpay = true,
    bool trial = true,
    bool userCache = true,
    bool localDatabase = true,
    bool manifesto = true,
    bool symbol = true,
    bool abTest = true,
    bool backgroundSync = true,
    bool connectionOptimizer = true,
    bool dataCompression = true,
    bool errorRecovery = true,
    bool memoryManager = true,
    bool multiLevelCache = true,
    bool progressiveLoader = true,
    bool realtimeOptimizer = true,
    bool districtSpotlight = true,
  }) {
    _showChatLogs = chat;
    _showAuthLogs = auth;
    _showNetworkLogs = network;
    _showCacheLogs = cache;
    _showDatabaseLogs = database;
    _showUILogs = ui;
    _showPerformanceLogs = performance;
    _showCommonLogs = common;
    _showMonetizationLogs = monetization;
    _showCandidateLogs = candidate;
    _showPollsLogs = polls;
    _showProfileLogs = profile;
    _showSettingsLogs = settings;
    _showNotificationsLogs = notifications;
    _showCoreLogs = core;
    _showHighlightLogs = highlight;
    _showFCMLogs = fcm;
    _showVideoLogs = video;
    _showRazorpayLogs = razorpay;
    _showTrialLogs = trial;
    _showUserCacheLogs = userCache;
    _showLocalDatabaseLogs = localDatabase;
    _showManifestoLogs = manifesto;
    _showSymbolLogs = symbol;
    _showABTestLogs = abTest;
    _showBackgroundSyncLogs = backgroundSync;
    _showConnectionOptimizerLogs = connectionOptimizer;
    _showDataCompressionLogs = dataCompression;
    _showErrorRecoveryLogs = errorRecovery;
    _showMemoryManagerLogs = memoryManager;
    _showMultiLevelCacheLogs = multiLevelCache;
    _showProgressiveLoaderLogs = progressiveLoader;
    _showRealtimeOptimizerLogs = realtimeOptimizer;
    _showDistrictSpotlightLogs = districtSpotlight;

    AppLogger.common('🔧 AppLogger configured:');
    AppLogger.common('   Chat: $_showChatLogs, Auth: $_showAuthLogs, Network: $_showNetworkLogs');
    AppLogger.common('   Cache: $_showCacheLogs, Database: $_showDatabaseLogs, UI: $_showUILogs');
    AppLogger.common('   Performance: $_showPerformanceLogs, Common: $_showCommonLogs');
    AppLogger.common('   Monetization: $_showMonetizationLogs, Candidate: $_showCandidateLogs');
    AppLogger.common('   Polls: $_showPollsLogs, Profile: $_showProfileLogs');
    AppLogger.common('   Settings: $_showSettingsLogs, Notifications: $_showNotificationsLogs');
    AppLogger.common('   Core: $_showCoreLogs, Highlight: $_showHighlightLogs, FCM: $_showFCMLogs');
    AppLogger.common('   Video: $_showVideoLogs, Razorpay: $_showRazorpayLogs, Trial: $_showTrialLogs');
    AppLogger.common('   UserCache: $_showUserCacheLogs, LocalDB: $_showLocalDatabaseLogs, Manifesto: $_showManifestoLogs');
    AppLogger.common('   Symbol: $_showSymbolLogs, ABTest: $_showABTestLogs, BackgroundSync: $_showBackgroundSyncLogs');
    AppLogger.common('   ConnectionOpt: $_showConnectionOptimizerLogs, DataComp: $_showDataCompressionLogs, ErrorRec: $_showErrorRecoveryLogs');
    AppLogger.common('   MemoryMgr: $_showMemoryManagerLogs, MultiCache: $_showMultiLevelCacheLogs, ProgLoader: $_showProgressiveLoaderLogs');
    AppLogger.common('   RealtimeOpt: $_showRealtimeOptimizerLogs, DistrictSpotlight: $_showDistrictSpotlightLogs');
  }

  // Chat-related logs
  static void chat(String message, {String? tag}) {
    if (_showChatLogs) {
      _logger.d('💬 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void chatError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showChatLogs) {
      _logger.e('💬❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  static void chatWarning(String message, {String? tag}) {
    if (_showChatLogs) {
      _logger.w('💬⚠️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  // Authentication logs
  static void auth(String message, {String? tag}) {
    if (_showAuthLogs) {
      _logger.d('🔐 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void authError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showAuthLogs) {
      _logger.e('🔐❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Network logs
  static void network(String message, {String? tag}) {
    if (_showNetworkLogs) {
      _logger.d('🌐 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void networkError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showNetworkLogs) {
      _logger.e('🌐❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Cache logs
  static void cache(String message, {String? tag}) {
    if (_showCacheLogs) {
      _logger.d('🏗️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void cacheError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showCacheLogs) {
      _logger.e('🏗️❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Database logs
  static void database(String message, {String? tag}) {
    if (_showDatabaseLogs) {
      _logger.d('💾 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void databaseError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showDatabaseLogs) {
      _logger.e('💾❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // UI logs
  static void ui(String message, {String? tag}) {
    if (_showUILogs) {
      _logger.d('🎨 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void uiError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showUILogs) {
      _logger.e('🎨❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Performance logs
  static void performance(String message, {String? tag}) {
    if (_showPerformanceLogs) {
      _logger.d('⚡ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void performanceWarning(String message, {String? tag}) {
    if (_showPerformanceLogs) {
      _logger.w('⚡⚠️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  // Common logs
  static void common(String message, {String? tag}) {
    if (_showCommonLogs) {
      final logMessage = '🔧 ${tag != null ? '[$tag] ' : ''}$message';
      _logger.d(logMessage);
      _writeToLogFile(logMessage, level: 'INFO');
    }
  }

  static void commonError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showCommonLogs) {
      _logger.e('🔧❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Monetization logs
  static void monetization(String message, {String? tag}) {
    if (_showMonetizationLogs) {
      _logger.d('💰 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void monetizationError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showMonetizationLogs) {
      _logger.e('💰❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Candidate logs
  static void candidate(String message, {String? tag}) {
    if (_showCandidateLogs) {
      _logger.d('👥 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void candidateError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showCandidateLogs) {
      _logger.e('👥❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Polls logs
  static void polls(String message, {String? tag}) {
    if (_showPollsLogs) {
      _logger.d('📊 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void pollsError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showPollsLogs) {
      _logger.e('📊❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Profile logs
  static void profile(String message, {String? tag}) {
    if (_showProfileLogs) {
      _logger.d('👤 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void profileError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showProfileLogs) {
      _logger.e('👤❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Settings logs
  static void settings(String message, {String? tag}) {
    if (_showSettingsLogs) {
      _logger.d('⚙️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void settingsError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showSettingsLogs) {
      _logger.e('⚙️❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Notifications logs
  static void notifications(String message, {String? tag}) {
    if (_showNotificationsLogs) {
      _logger.d('🔔 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void notificationsError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showNotificationsLogs) {
      _logger.e('🔔❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Core logs
  static void core(String message, {String? tag}) {
    if (_showCoreLogs) {
      _logger.d('🏗️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void coreError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showCoreLogs) {
      _logger.e('🏗️❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Highlight logs
  static void highlight(String message, {String? tag}) {
    if (_showHighlightLogs) {
      _logger.d('⭐ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void highlightError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showHighlightLogs) {
      _logger.e('⭐❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // FCM logs
  static void fcm(String message, {String? tag}) {
    if (_showFCMLogs) {
      _logger.d('📱 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void fcmError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showFCMLogs) {
      _logger.e('📱❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Video logs
  static void video(String message, {String? tag}) {
    if (_showVideoLogs) {
      _logger.d('🎥 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void videoError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showVideoLogs) {
      _logger.e('🎥❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Razorpay logs
  static void razorpay(String message, {String? tag}) {
    if (_showRazorpayLogs) {
      _logger.d('💳 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void razorpayError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showRazorpayLogs) {
      _logger.e('💳❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Trial logs
  static void trial(String message, {String? tag}) {
    if (_showTrialLogs) {
      _logger.d('⏰ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void trialError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showTrialLogs) {
      _logger.e('⏰❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // User cache logs
  static void userCache(String message, {String? tag}) {
    if (_showUserCacheLogs) {
      _logger.d('👤💾 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void userCacheError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showUserCacheLogs) {
      _logger.e('👤💾❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Local database logs
  static void localDatabase(String message, {String? tag}) {
    if (_showLocalDatabaseLogs) {
      _logger.d('💽 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void localDatabaseError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showLocalDatabaseLogs) {
      _logger.e('💽❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Manifesto logs
  static void manifesto(String message, {String? tag}) {
    if (_showManifestoLogs) {
      _logger.d('📜 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void manifestoError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showManifestoLogs) {
      _logger.e('📜❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Symbol logs
  static void symbol(String message, {String? tag}) {
    if (_showSymbolLogs) {
      _logger.d('🏛️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void symbolError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showSymbolLogs) {
      _logger.e('🏛️❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // A/B Test logs
  static void abTest(String message, {String? tag}) {
    if (_showABTestLogs) {
      _logger.d('🧪 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void abTestError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showABTestLogs) {
      _logger.e('🧪❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Background sync logs
  static void backgroundSync(String message, {String? tag}) {
    if (_showBackgroundSyncLogs) {
      _logger.d('🔄 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void backgroundSyncError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showBackgroundSyncLogs) {
      _logger.e('🔄❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Connection optimizer logs
  static void connectionOptimizer(String message, {String? tag}) {
    if (_showConnectionOptimizerLogs) {
      _logger.d('🌐⚡ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void connectionOptimizerError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showConnectionOptimizerLogs) {
      _logger.e('🌐⚡❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Data compression logs
  static void dataCompression(String message, {String? tag}) {
    if (_showDataCompressionLogs) {
      _logger.d('🗜️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void dataCompressionError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showDataCompressionLogs) {
      _logger.e('🗜️❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Error recovery logs
  static void errorRecovery(String message, {String? tag}) {
    if (_showErrorRecoveryLogs) {
      _logger.d('🔧🛠️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void errorRecoveryError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showErrorRecoveryLogs) {
      _logger.e('🔧🛠️❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Memory manager logs
  static void memoryManager(String message, {String? tag}) {
    if (_showMemoryManagerLogs) {
      _logger.d('🧠 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void memoryManagerError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showMemoryManagerLogs) {
      _logger.e('🧠❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Multi-level cache logs
  static void multiLevelCache(String message, {String? tag}) {
    if (_showMultiLevelCacheLogs) {
      _logger.d('🏗️ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void multiLevelCacheError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showMultiLevelCacheLogs) {
      _logger.e('🏗️❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Progressive loader logs
  static void progressiveLoader(String message, {String? tag}) {
    if (_showProgressiveLoaderLogs) {
      _logger.d('📄 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void progressiveLoaderError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showProgressiveLoaderLogs) {
      _logger.e('📄❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Realtime optimizer logs
  static void realtimeOptimizer(String message, {String? tag}) {
    if (_showRealtimeOptimizerLogs) {
      _logger.d('⚡📡 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void realtimeOptimizerError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showRealtimeOptimizerLogs) {
      _logger.e('⚡📡❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // District spotlight logs
  static void districtSpotlight(String message, {String? tag}) {
    if (_showDistrictSpotlightLogs) {
      _logger.d('🎯 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void districtSpotlightError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_showDistrictSpotlightLogs) {
      _logger.e('🎯❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
    }
  }

  // Generic logs (always shown in debug mode)
  static void info(String message, {String? tag}) {
    _logger.i('ℹ️ ${tag != null ? '[$tag] ' : ''}$message');
  }

  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _logger.e('❌ ${tag != null ? '[$tag] ' : ''}$message', error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {String? tag}) {
    _logger.w('⚠️ ${tag != null ? '[$tag] ' : ''}$message');
  }

  // Section timing for performance monitoring
  static Stopwatch startSectionTimer(String sectionName, {String? tag}) {
    common('▶️ STARTING: $sectionName', tag: tag ?? 'TIMER');
    return Stopwatch()..start();
  }

  static void endSectionTimer(String sectionName, Stopwatch timer, {String? tag, String? details}) {
    timer.stop();
    final timeMs = timer.elapsedMilliseconds;
    final emoji = timeMs > 1000 ? '🐌' : timeMs > 500 ? '⚠️' : '✅';
    final message = '$sectionName completed in ${timeMs}ms${details != null ? ' ($details)' : ''}';
    if (_showPerformanceLogs) {
      _logger.d('⚡ ${tag != null ? '[$tag] ' : ''}$emoji $message');
    }
  }

  // Debug logs (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _logger.d('🔍 ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  // Quick setup methods for testing
  static void enableAllLogs() {
    configure(
      chat: true,
      auth: true,
      network: true,
      cache: true,
      database: true,
      ui: true,
      performance: true,
      common: true,
      monetization: true,
      candidate: true,
      polls: true,
      profile: true,
      settings: true,
      notifications: true,
      core: true,
      highlight: true,
      fcm: true,
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
  }

  static void enableChatOnly() {
    configure(
      chat: true,
      auth: false,
      network: false,
      cache: false,
      database: false,
      ui: false,
      performance: false,
    );
  }

  static void enableCoreOnly() {
    configure(
      chat: true,
      auth: true,
      network: true,
      cache: true,
      database: true,
      ui: false,
      performance: true,
      common: true,
      monetization: false,
      candidate: false,
      polls: false,
      profile: false,
      settings: false,
      notifications: false,
      districtSpotlight: false,
    );
  }

  static void disableAllLogs() {
    configure(
      chat: false,
      auth: false,
      network: false,
      cache: false,
      database: false,
      ui: false,
      performance: false,
      common: false,
      monetization: false,
      candidate: false,
      polls: false,
      profile: false,
      settings: false,
      notifications: false,
    );
  }

  // Get current configuration
  static Map<String, bool> getConfiguration() {
    return {
      'chat': _showChatLogs,
      'auth': _showAuthLogs,
      'network': _showNetworkLogs,
      'cache': _showCacheLogs,
      'database': _showDatabaseLogs,
      'ui': _showUILogs,
      'performance': _showPerformanceLogs,
      'common': _showCommonLogs,
      'monetization': _showMonetizationLogs,
      'candidate': _showCandidateLogs,
      'polls': _showPollsLogs,
      'profile': _showProfileLogs,
      'settings': _showSettingsLogs,
      'notifications': _showNotificationsLogs,
      'core': _showCoreLogs,
      'highlight': _showHighlightLogs,
      'fcm': _showFCMLogs,
      'video': _showVideoLogs,
      'razorpay': _showRazorpayLogs,
      'trial': _showTrialLogs,
      'userCache': _showUserCacheLogs,
      'localDatabase': _showLocalDatabaseLogs,
      'manifesto': _showManifestoLogs,
      'symbol': _showSymbolLogs,
      'abTest': _showABTestLogs,
      'backgroundSync': _showBackgroundSyncLogs,
      'connectionOptimizer': _showConnectionOptimizerLogs,
      'dataCompression': _showDataCompressionLogs,
      'errorRecovery': _showErrorRecoveryLogs,
      'memoryManager': _showMemoryManagerLogs,
      'multiLevelCache': _showMultiLevelCacheLogs,
      'progressiveLoader': _showProgressiveLoaderLogs,
      'realtimeOptimizer': _showRealtimeOptimizerLogs,
      'districtSpotlight': _showDistrictSpotlightLogs,
    };
  }
}
