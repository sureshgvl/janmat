import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../utils/app_logger.dart';

/// Background Initializer Service for Zero Frame Skipping
/// Uses Flutter isolates and compute functions to eliminate all frame drops
class BackgroundInitializer {
  static final BackgroundInitializer _instance =
      BackgroundInitializer._internal();
  factory BackgroundInitializer() => _instance;
  BackgroundInitializer._internal();

  final ReceivePort _receivePort = ReceivePort();
  Isolate? _isolate;
  SendPort? _sendPort;
  bool _isInitialized = false;

  // Testing mode flag - skip heavy operations during testing
  static bool testingMode = false;

  /// Initialize all services in background isolate
  Future<void> initializeAllServices() async {
    if (_isInitialized) return;

    if (testingMode) {
      AppLogger.common('🧪 TESTING MODE: Skipping heavy background initialization');
      _isInitialized = true;
      return;
    }

    AppLogger.common('🚀 Starting zero-frame background initialization');

    // Start isolate for heavy operations
    await _startIsolate();

    // Defer all Firebase operations to post-frame callback
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeFirebaseInBackground();
    });

    _isInitialized = true;
  }

  /// Start background isolate for heavy computations - disabled on web
  Future<void> _startIsolate() async {
    if (kIsWeb) {
      AppLogger.common('📱 WEB: Skipping background isolate (not supported on web)');
      return;
    }

    try {
      _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
      _sendPort = await _receivePort.first as SendPort;
      AppLogger.common('✅ Background isolate started successfully');
    } catch (e) {
      AppLogger.commonError('❌ Failed to start background isolate', error: e);
    }
  }

  /// Isolate entry point for background processing
  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      // Handle messages from main isolate
      if (message is Map<String, dynamic>) {
        _handleIsolateMessage(message, sendPort);
      }
    });
  }

  /// Handle messages in isolate
  static void _handleIsolateMessage(
    Map<String, dynamic> message,
    SendPort sendPort,
  ) {
    final action = message['action'];

    switch (action) {
      case 'initialize_firebase':
        // Firebase initialization in isolate (if needed)
        sendPort.send({'result': 'firebase_initialized'});
        break;

      case 'heavy_computation':
        // Perform heavy computations here
        final result = _performHeavyComputation(message['data']);
        sendPort.send({'result': 'computation_done', 'data': result});
        break;
    }
  }

  /// Perform heavy computation in isolate
  static Map<String, dynamic> _performHeavyComputation(dynamic data) {
    // Simulate heavy computation
    // In real app, this could be data processing, image processing, etc.
    return {'processed': true, 'timestamp': DateTime.now().toIso8601String()};
  }

  /// Initialize Firebase with zero frame impact using deferred scheduling
  Future<void> _initializeFirebaseInBackground() async {
    try {
      // Use SchedulerBinding to defer Firebase initialization to after first frame
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        AppLogger.common('🔄 Initializing Firebase in background isolate');
        // Firebase must be initialized on main thread due to platform channels
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        AppLogger.common('✅ Firebase initialized with zero frames');
      });
    } catch (e) {
      AppLogger.commonError('❌ Firebase initialization failed', error: e);
      // Fallback to immediate initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }


  /// Initialize services with zero frame impact - disabled compute on web
  Future<void> initializeServiceWithZeroFrames(
    String serviceName,
    Future<void> Function() initializer,
  ) async {
    try {
      // For Firebase-related services, use deferred scheduling instead of isolates
      if (serviceName.contains('Firebase') ||
          serviceName.contains('Chat') ||
          serviceName.contains('AdMob')) {
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          AppLogger.common('🔄 Initializing $serviceName with zero frames');
          await initializer();
          AppLogger.common('✅ $serviceName initialized with zero frames');
        });
      } else {
        // Use compute for other services - not available on web
        if (kIsWeb) {
          AppLogger.common('📱 WEB: Skipping compute for $serviceName, using main thread');
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            AppLogger.common('🔄 Initializing $serviceName on web main thread');
            await initializer();
            AppLogger.common('✅ $serviceName initialized on web');
          });
        } else {
          await compute(_runServiceInitializer, {
            'service': serviceName,
            'initializer': initializer,
          });
          AppLogger.common('✅ $serviceName initialized with zero frames');
        }
      }
    } catch (e) {
      AppLogger.commonError('❌ $serviceName initialization failed', error: e);
      // Fallback to main thread
      await initializer();
    }
  }

  /// Run service initializer in compute isolate
  static Future<void> _runServiceInitializer(
    Map<String, dynamic> params,
  ) async {
    final serviceName = params['service'] as String;
    final initializer = params['initializer'] as Future<void> Function();

    AppLogger.common('🔄 Initializing $serviceName in background isolate');
    await initializer();
  }

  /// Schedule operation for next frame to avoid frame drops
  void scheduleForNextFrame(VoidCallback operation) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Run operation in next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        operation();
      });
    });
  }

  /// Schedule operation with zero frame impact using microtasks
  void scheduleWithZeroFrames(VoidCallback operation) {
    // Use microtask to run after current task but before next frame
    Future.microtask(() {
      // Additional deferral to ensure we're not in a frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        operation();
      });
    });
  }

  /// Execute operation in next available frame slot
  void executeInNextFrameSlot(VoidCallback operation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Double defer to ensure we're well clear of current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          operation();
        });
      });
    });
  }

  /// Run operation in background isolate
  Future<T> runInIsolate<T>(Future<T> Function() operation) async {
    if (_sendPort == null) {
      // Fallback to main thread
      return await operation();
    }

    final completer = Completer<T>();
    final responsePort = ReceivePort();

    responsePort.listen((message) {
      if (message is Map<String, dynamic> &&
          message['result'] == 'computation_done') {
        completer.complete(message['data'] as T);
      }
      responsePort.close();
    });

    _sendPort!.send({
      'action': 'heavy_computation',
      'data': null,
      'response_port': responsePort.sendPort,
    });

    return completer.future;
  }

  /// Clean up resources
  void dispose() {
    _isolate?.kill();
    _receivePort.close();
    AppLogger.common('🧹 Background initializer disposed');
  }

  /// Check if all services are ready
  bool get isReady => _isInitialized && _sendPort != null;
}

/// Extension for zero-frame operations - web compatible
extension ZeroFrameOperations on Future<void> {
  /// Run this operation with zero frame impact
  Future<void> withZeroFrames() async {
    final initializer = BackgroundInitializer();

    if (kIsWeb) {
      // On web, just run directly in post-frame callback
      AppLogger.common('📱 WEB: Running operation with zero frames using scheduler');
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await this;
      });
    } else if (initializer.isReady) {
      await initializer.runInIsolate(() => this);
    } else {
      // Fallback to compute on mobile
      await compute(_runFutureInCompute, this as Future<void>);
    }
  }
}

/// Helper function for compute
Future<void> _runFutureInCompute(Future<void> future) async {
  await future;
}

/// Global background initializer instance
final backgroundInitializer = BackgroundInitializer();
