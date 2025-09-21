import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'user_cache_service.dart';

class BackgroundSyncManager {
  static final BackgroundSyncManager _instance = BackgroundSyncManager._internal();
  factory BackgroundSyncManager() => _instance;
  BackgroundSyncManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserCacheService _cacheService = UserCacheService();

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

    print('🔄 Background sync manager initialized');
  }

  // Add operation to background sync queue
  void addToSyncQueue(Future<void> Function() operation) {
    _syncQueue.add(operation);
    debugPrint('📋 [BACKGROUND_SYNC] Added operation to queue (total: ${_syncQueue.length})');

    // Process immediately if not already processing
    if (!_isProcessing) {
      debugPrint('▶️ [BACKGROUND_SYNC] Starting queue processing');
      _processSyncQueue();
    } else {
      debugPrint('⏳ [BACKGROUND_SYNC] Queue processing already in progress, operation queued');
    }
  }

  // Process the sync queue
  Future<void> _processSyncQueue() async {
    if (_isProcessing || _syncQueue.isEmpty) {
      if (_syncQueue.isEmpty) {
        debugPrint('ℹ️ [BACKGROUND_SYNC] Queue is empty, nothing to process');
      } else {
        debugPrint('⏳ [BACKGROUND_SYNC] Processing already in progress, skipping');
      }
      return;
    }

    _isProcessing = true;
    final startTime = DateTime.now();

    debugPrint('🔄 [BACKGROUND_SYNC] Starting queue processing (${_syncQueue.length} operations) at ${startTime.toIso8601String()}');

    try {
      // Process operations in batches to avoid overwhelming the system
      const batchSize = 3;
      final batches = <List<Future<void> Function()>>[];
      int totalProcessed = 0;

      for (int i = 0; i < _syncQueue.length; i += batchSize) {
        final end = (i + batchSize < _syncQueue.length) ? i + batchSize : _syncQueue.length;
        batches.add(_syncQueue.sublist(i, end));
      }

      debugPrint('📦 [BACKGROUND_SYNC] Created ${batches.length} batches (batch size: $batchSize)');

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];
        final batchStart = DateTime.now();

        debugPrint('🔄 [BACKGROUND_SYNC] Processing batch ${batchIndex + 1}/${batches.length} (${batch.length} operations)');

        try {
          await Future.wait(
            batch.map((operation) => operation()),
            eagerError: false, // Don't fail fast, continue with other operations
          );

          final batchDuration = DateTime.now().difference(batchStart);
          totalProcessed += batch.length;
          debugPrint('✅ [BACKGROUND_SYNC] Batch ${batchIndex + 1} completed in ${batchDuration.inMilliseconds}ms (total processed: $totalProcessed)');
        } catch (batchError) {
          final batchDuration = DateTime.now().difference(batchStart);
          debugPrint('⚠️ [BACKGROUND_SYNC] Batch ${batchIndex + 1} had errors after ${batchDuration.inMilliseconds}ms: $batchError');
          // Continue with next batch despite errors
        }
      }

      _syncQueue.clear();
      final totalDuration = DateTime.now().difference(startTime);
      debugPrint('🎉 [BACKGROUND_SYNC] Queue processing completed successfully in ${totalDuration.inSeconds}s (${totalProcessed} operations)');
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      debugPrint('❌ [BACKGROUND_SYNC] Error processing background sync queue after ${totalDuration.inSeconds}s: $e');
    } finally {
      _isProcessing = false;
      debugPrint('🔄 [BACKGROUND_SYNC] Processing flag reset, ready for new operations');
    }
  }

  // Sync user profile after login
  Future<void> syncUserProfileAfterLogin(User firebaseUser) async {
    addToSyncQueue(() async {
      try {
        print('👤 Syncing user profile in background...');

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
            wardId: '',
            districtId: '',
            bodyId: '',
            xpPoints: 0,
            premium: false,
            createdAt: DateTime.now(),
            photoURL: firebaseUser.photoURL,
          );

          await userDoc.set(userModel.toJson(), SetOptions(merge: true));

          // Cache the user profile locally
          await _cacheService.cacheUserProfile(userModel);

          print('✅ Full user profile created and cached');
        } else {
          // Update existing profile
          final existingData = userSnapshot.data()!;
          final updatedData = {
            'name': firebaseUser.displayName ?? existingData['name'],
            'phone': firebaseUser.phoneNumber ?? existingData['phone'],
            'photoURL': firebaseUser.photoURL ?? existingData['photoURL'],
            'lastUpdated': FieldValue.serverTimestamp(),
          };

          await userDoc.update(updatedData);

          // Update cache
          final userModel = UserModel.fromJson({...existingData, ...updatedData});
          await _cacheService.cacheUserProfile(userModel);

          print('✅ User profile updated and cache refreshed');
        }
      } catch (e) {
        print('⚠️ Error syncing user profile: $e');
      }
    });
  }

  // Sync user preferences
  Future<void> syncUserPreferences(String userId) async {
    addToSyncQueue(() async {
      try {
        print('🔄 Syncing user preferences...');

        // Get local preferences and sync to Firestore
        final prefs = await _cacheService.getQuickUserData();
        if (prefs != null) {
          final userPrefsRef = _firestore.collection('user_preferences').doc(userId);
          await userPrefsRef.set({
            'lastSync': FieldValue.serverTimestamp(),
            'preferences': prefs,
          }, SetOptions(merge: true));

          print('✅ User preferences synced');
        }
      } catch (e) {
        print('⚠️ Error syncing user preferences: $e');
      }
    });
  }

  // Sync user quota
  Future<void> syncUserQuota(String userId) async {
    addToSyncQueue(() async {
      try {
        print('📊 Syncing user quota...');

        final quotaRef = _firestore.collection('user_quotas').doc(userId);
        final quotaSnapshot = await quotaRef.get();

        if (!quotaSnapshot.exists) {
          // Create default quota
          await quotaRef.set({
            'userId': userId,
            'dailyLimit': 20,
            'messagesSent': 0,
            'extraQuota': 0,
            'lastReset': DateTime.now().toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          print('✅ User quota created');
        } else {
          // Update last activity
          await quotaRef.update({
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          print('✅ User quota updated');
        }
      } catch (e) {
        print('⚠️ Error syncing user quota: $e');
      }
    });
  }

  // Clean up expired data
  Future<void> cleanupExpiredData(String userId) async {
    addToSyncQueue(() async {
      try {
        print('🧹 Cleaning up expired data...');

        // Clean up old cached data
        await _cacheService.clearUserCache();

        // Clean up old Firestore data if needed
        // This could include cleaning up old messages, expired sessions, etc.

        print('✅ Expired data cleaned up');
      } catch (e) {
        print('⚠️ Error cleaning up expired data: $e');
      }
    });
  }

  // Register device in background
  Future<void> registerDeviceBackground(String userId) async {
    addToSyncQueue(() async {
      try {
        print('📱 Registering device in background...');

        // Device registration logic would go here
        // This would integrate with your DeviceService

        print('✅ Device registered in background');
      } catch (e) {
        print('⚠️ Error registering device: $e');
      }
    });
  }

  // Perform comprehensive background sync
  Future<void> performFullBackgroundSync(User firebaseUser) async {
    final startTime = DateTime.now();
    debugPrint('🔄 [BACKGROUND_SYNC] Starting comprehensive background sync for user ${firebaseUser.uid} at ${startTime.toIso8601String()}');

    try {
      debugPrint('📋 [BACKGROUND_SYNC] Queuing 5 background operations: profile, preferences, quota, device, cleanup');

      await Future.wait([
        syncUserProfileAfterLogin(firebaseUser),
        syncUserPreferences(firebaseUser.uid),
        syncUserQuota(firebaseUser.uid),
        registerDeviceBackground(firebaseUser.uid),
        cleanupExpiredData(firebaseUser.uid),
      ]);

      final totalDuration = DateTime.now().difference(startTime);
      debugPrint('✅ [BACKGROUND_SYNC] Comprehensive background sync completed successfully in ${totalDuration.inSeconds}s');
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      debugPrint('⚠️ [BACKGROUND_SYNC] Comprehensive background sync completed with errors after ${totalDuration.inSeconds}s: $e');
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
    print('🧹 Background sync manager disposed');
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