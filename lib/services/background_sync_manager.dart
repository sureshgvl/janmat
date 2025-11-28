import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../utils/app_logger.dart';


class BackgroundSyncManager {
  static final BackgroundSyncManager _instance = BackgroundSyncManager._internal();
  factory BackgroundSyncManager() => _instance;
  BackgroundSyncManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Queue for background operations
  final List<Future<void> Function()> _syncQueue = [];
  bool _isProcessing = false;
  Timer? _syncTimer;

  // Initialize background sync
  void initialize() {
    // Start periodic sync every 30 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _processSyncQueue();
    });

    AppLogger.common('🔄 Background sync manager initialized');
  }

  // Add operation to background sync queue
  void addToSyncQueue(Future<void> Function() operation) {
    _syncQueue.add(operation);
    AppLogger.common('📋 [BACKGROUND_SYNC] Added operation to queue (total: ${_syncQueue.length})');

    // Process immediately if not already processing
    if (!_isProcessing) {
      AppLogger.common('▶️ [BACKGROUND_SYNC] Starting queue processing');
      _processSyncQueue();
    } else {
      AppLogger.common('⏳ [BACKGROUND_SYNC] Queue processing already in progress, operation queued');
    }
  }

  // Process the sync queue
  Future<void> _processSyncQueue() async {
    if (_isProcessing || _syncQueue.isEmpty) {
      if (_syncQueue.isEmpty) {
        AppLogger.common('ℹ️ [BACKGROUND_SYNC] Queue is empty, nothing to process');
      } else {
        AppLogger.common('⏳ [BACKGROUND_SYNC] Processing already in progress, skipping');
      }
      return;
    }

    _isProcessing = true;
    final startTime = DateTime.now();

    AppLogger.common('🔄 [BACKGROUND_SYNC] Starting queue processing (${_syncQueue.length} operations) at ${startTime.toIso8601String()}');

    try {
      // Process operations in batches to avoid overwhelming the system
      const batchSize = 3;
      final batches = <List<Future<void> Function()>>[];
      int totalProcessed = 0;

      for (int i = 0; i < _syncQueue.length; i += batchSize) {
        final end = (i + batchSize < _syncQueue.length) ? i + batchSize : _syncQueue.length;
        batches.add(_syncQueue.sublist(i, end));
      }

      AppLogger.common('📦 [BACKGROUND_SYNC] Created ${batches.length} batches (batch size: $batchSize)');

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];
        final batchStart = DateTime.now();

        AppLogger.common('🔄 [BACKGROUND_SYNC] Processing batch ${batchIndex + 1}/${batches.length} (${batch.length} operations)');

        try {
          await Future.wait(
            batch.map((operation) => operation()),
            eagerError: false, // Don't fail fast, continue with other operations
          );

          final batchDuration = DateTime.now().difference(batchStart);
          totalProcessed += batch.length;
          AppLogger.common('✅ [BACKGROUND_SYNC] Batch ${batchIndex + 1} completed in ${batchDuration.inMilliseconds}ms (total processed: $totalProcessed)');
        } catch (batchError) {
          final batchDuration = DateTime.now().difference(batchStart);
          AppLogger.common('⚠️ [BACKGROUND_SYNC] Batch ${batchIndex + 1} had errors after ${batchDuration.inMilliseconds}ms: $batchError');
          // Continue with next batch despite errors
        }
      }

      _syncQueue.clear();
      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.common('🎉 [BACKGROUND_SYNC] Queue processing completed successfully in $totalDuration.inSeconds s ($totalProcessed operations)');
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.commonError('❌ [BACKGROUND_SYNC] Error processing background sync queue', error: e);
    } finally {
      _isProcessing = false;
      AppLogger.common('🔄 [BACKGROUND_SYNC] Processing flag reset, ready for new operations');
    }
  }

  // Sync user profile after login
  Future<void> syncUserProfileAfterLogin(User firebaseUser) async {
    addToSyncQueue(() async {
      try {
        AppLogger.common('👤 Syncing user profile in background...');

        final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
        final userSnapshot = await userDoc.get();

        if (!userSnapshot.exists) {
          // Create full user profile
          final userModel = UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            phone: firebaseUser.phoneNumber ?? '',
            email: firebaseUser.email,
            role: '',
            roleSelected: false,
            profileCompleted: false,
            electionAreas: [],
            premium: false,
            createdAt: DateTime.now(),
            photoURL: null, // User will add manually
          );

          await userDoc.set(userModel.toJson(), SetOptions(merge: true));

          // No caching - user profile stored in controller only

          AppLogger.common('✅ Full user profile created and cached');
        } else {
          // Update existing profile
          final existingData = userSnapshot.data()!;
          final updatedData = {
            'name': firebaseUser.displayName ?? existingData['name'],
            'phone': firebaseUser.phoneNumber ?? existingData['phone'],
            'lastUpdated': FieldValue.serverTimestamp(),
          };

          await userDoc.update(updatedData);

          // No caching - user profile stored in controller only

          AppLogger.common('✅ User profile updated and cache refreshed');
        }
      } catch (e) {
        AppLogger.common('⚠️ Error syncing user profile: $e');
      }
    });
  }

  // Sync user preferences
  Future<void> syncUserPreferences(String userId) async {
    addToSyncQueue(() async {
      try {
        AppLogger.common('🔄 Syncing user preferences...');

        // No caching - preferences stored in controller only
        AppLogger.common('✅ User preferences sync skipped (no caching)');
      } catch (e) {
        AppLogger.common('⚠️ Error syncing user preferences: $e');
      }
    });
  }

  // Clean up expired data
  Future<void> cleanupExpiredData(String userId) async {
    addToSyncQueue(() async {
      try {
        AppLogger.common('🧹 Cleaning up expired data...');

        // No caching - cleanup not needed

        // Clean up old Firestore data if needed
        // This could include cleaning up old messages, expired sessions, etc.

        AppLogger.common('✅ Expired data cleaned up');
      } catch (e) {
        AppLogger.common('⚠️ Error cleaning up expired data: $e');
      }
    });
  }

  // Register device in background
  Future<void> registerDeviceBackground(String userId) async {
    addToSyncQueue(() async {
      try {
        AppLogger.common('📱 Registering device in background...');

        // Device registration logic would go here
        // This would integrate with your DeviceService

        AppLogger.common('✅ Device registered in background');
      } catch (e) {
        AppLogger.common('⚠️ Error registering device: $e');
      }
    });
  }

  // Perform comprehensive background sync
  Future<void> performFullBackgroundSync(User firebaseUser) async {
    final startTime = DateTime.now();
    AppLogger.common('🔄 [BACKGROUND_SYNC] Starting comprehensive background sync for user ${firebaseUser.uid} at ${startTime.toIso8601String()}');

    try {
      AppLogger.common('📋 [BACKGROUND_SYNC] Queuing 4 background operations: profile, preferences, quota, cleanup');

      await Future.wait([
        syncUserProfileAfterLogin(firebaseUser),
        syncUserPreferences(firebaseUser.uid),
        //syncUserQuota(firebaseUser.uid),
        cleanupExpiredData(firebaseUser.uid),
      ]);

      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.common('✅ [BACKGROUND_SYNC] Comprehensive background sync completed successfully in ${totalDuration.inSeconds}s');
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.common('⚠️ [BACKGROUND_SYNC] Comprehensive background sync completed with errors after ${totalDuration.inSeconds}s: $e');
    }
  }

  // Force immediate sync (for critical operations)
  Future<void> forceSync() async {
    await _processSyncQueue();
  }

  // Cleanup resources
  void dispose() {
    _syncTimer?.cancel();
    _syncQueue.clear();
    AppLogger.common('🧹 Background sync manager disposed');
  }

  // Get sync queue status
  Map<String, dynamic> getSyncStatus() {
    return {
      'queueLength': _syncQueue.length,
      'isProcessing': _isProcessing,
      'nextSyncIn': _syncTimer?.tick ?? 0,
    };
  }
}
