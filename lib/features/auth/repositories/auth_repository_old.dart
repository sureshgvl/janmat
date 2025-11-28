import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../features/user/models/user_model.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../candidate/controllers/candidate_controller.dart';
import '../../../services/background_sync_manager.dart';
import '../../../services/fcm_service.dart';
import '../../../utils/performance_monitor.dart';
import '../../../utils/app_logger.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final BackgroundSyncManager _syncManager = BackgroundSyncManager();
  final FCMService _fcmService = FCMService();

  // Phone Authentication with improved reCAPTCHA handling and timeout
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
  ) async {
    AppLogger.auth(
      'Initiating phone verification for: +91$phoneNumber',
      tag: 'PHONE_VERIFY',
    );

    try {
      await _firebaseAuth
          .verifyPhoneNumber(
            phoneNumber: '+91$phoneNumber',
            verificationCompleted: (PhoneAuthCredential credential) async {
              AppLogger.auth(
                'Phone verification completed automatically',
                tag: 'PHONE_VERIFY',
              );
              // Auto-verification successful, sign in immediately
              try {
                await _firebaseAuth.signInWithCredential(credential);
                AppLogger.auth(
                  'Auto-signed in with phone credential',
                  tag: 'PHONE_VERIFY',
                );
              } catch (e) {
                AppLogger.authError(
                  'Auto-sign in failed',
                  tag: 'PHONE_VERIFY',
                  error: e,
                );
                rethrow;
              }
            },
            verificationFailed: (FirebaseAuthException e) {
              AppLogger.authError(
                'Phone verification failed: ${e.message}',
                tag: 'PHONE_VERIFY',
                error: e,
              );
              throw e;
            },
            codeSent: (String verificationId, int? resendToken) {
              AppLogger.auth(
                'OTP sent successfully, verification ID: $verificationId',
                tag: 'PHONE_VERIFY',
              );
              onCodeSent(verificationId);
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              AppLogger.auth(
                'Auto-retrieval timeout, manual OTP entry required',
                tag: 'PHONE_VERIFY',
              );
              // This is called when auto-retrieval times out
              // The verificationId is still valid for manual OTP entry
              onCodeSent(verificationId);
            },
            // Force reCAPTCHA to be more responsive
            timeout: const Duration(
              seconds: 30,
            ), // Reduced timeout for better UX
            // Enable forceResendingToken for better UX
            forceResendingToken: null,
          )
          .timeout(
            const Duration(
              seconds: 60,
            ), // Overall timeout for the entire operation
            onTimeout: () {
              AppLogger.auth(
                'Phone verification timed out after 60 seconds',
                tag: 'PHONE_VERIFY',
              );
              throw Exception(
                'Phone verification timed out. Please check your internet connection and try again.',
              );
            },
          );

      AppLogger.auth('Phone verification setup completed', tag: 'PHONE_VERIFY');
    } catch (e) {
      AppLogger.authError(
        'Phone verification setup failed',
        tag: 'PHONE_VERIFY',
        error: e,
      );
      rethrow;
    }
  }

  Future<UserCredential> signInWithOTP(
    String verificationId,
    String smsCode,
  ) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // Check network connectivity before attempting Google Sign-In
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = !connectivityResult.contains(
        ConnectivityResult.none,
      );
      AppLogger.network(
        'Network connectivity check: ${hasConnection ? 'Connected' : 'No connection'}',
        tag: 'CONNECTIVITY',
      );
      return hasConnection;
    } catch (e) {
      AppLogger.network(
        'Could not check connectivity: $e',
        tag: 'CONNECTIVITY',
      );
      return true; // Assume connected if check fails
    }
  }

  // Google Sign-In - Optimized for Release Build Performance
  Future<UserCredential?> signInWithGoogle({
    bool forceAccountPicker = false,
  }) async {
    final startTime = DateTime.now();
    startPerformanceTimer('google_signin_release_optimized');

    AppLogger.auth(
      '🚀 Starting RELEASE-OPTIMIZED Google Sign-In at ${startTime.toIso8601String()}',
    );

    try {
      // RELEASE OPTIMIZATION: Skip connectivity check for faster startup
      // App Check and Firebase will handle network issues
      AppLogger.auth(
        '⚡ [RELEASE_OPTIMIZED] Skipping connectivity check for speed',
      );

      GoogleSignInAccount? googleUser;

      // RELEASE OPTIMIZATION: Skip silent sign-in for first-time users
      // Go directly to account picker for faster UX
      if (!forceAccountPicker) {
        // Try silent sign-in with shorter timeout (2s instead of 5s)
        AppLogger.auth(
          '🔍 [RELEASE_OPTIMIZED] Quick silent sign-in attempt...',
        );
        try {
          googleUser = await _googleSignIn.signInSilently().timeout(
            const Duration(seconds: 2), // Reduced from 5s for faster UX
            onTimeout: () {
              AppLogger.auth(
                '⏰ [RELEASE_OPTIMIZED] Silent sign-in timeout after 2s',
              );
              return null;
            },
          );
          if (googleUser != null) {
            AppLogger.auth(
              '✅ [RELEASE_OPTIMIZED] Silent sign-in successful: ${googleUser.displayName}',
            );
          }
        } catch (e) {
          AppLogger.auth(
            'ℹ️ [RELEASE_OPTIMIZED] Silent sign-in failed, proceeding to picker',
          );
        }
      }

      // If silent failed or forced picker requested, show account picker
      if (googleUser == null) {
        AppLogger.auth(
          '📱 [RELEASE_OPTIMIZED] Showing Google account picker...',
        );

        final signInStart = DateTime.now();
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30), // Reduced from 45s for faster UX
          onTimeout: () {
            final timeoutDuration = DateTime.now().difference(signInStart);
            AppLogger.auth(
              '⏰ [RELEASE_OPTIMIZED] Account picker timeout after ${timeoutDuration.inSeconds}s',
            );
            throw Exception('Google Sign-In timed out. Please try again.');
          },
        );

        final signInDuration = DateTime.now().difference(signInStart);
        AppLogger.auth(
          '✅ [RELEASE_OPTIMIZED] Account picker completed in ${signInDuration.inSeconds}s',
        );
      }

      if (googleUser == null) {
        final totalDuration = DateTime.now().difference(startTime);
        stopPerformanceTimer('google_signin_release_optimized');
        AppLogger.auth(
          '[RELEASE_OPTIMIZED] User cancelled Google Sign-In after ${totalDuration.inSeconds}s',
        );
        return null;
      }

      AppLogger.auth(
        '✅ [RELEASE_OPTIMIZED] Google account selected: ${googleUser.displayName}',
      );

      // RELEASE OPTIMIZATION: Store account info asynchronously (don't await)
      _storeLastGoogleAccount(googleUser); // Fire-and-forget

      // RELEASE OPTIMIZATION: Get tokens and prepare data in parallel with reduced logging
      final parallelStart = DateTime.now();

      final tokenFuture = googleUser.authentication;
      final userDataPrepFuture = _prepareUserDataLocally(googleUser);

      final parallelResults = await Future.wait([
        tokenFuture,
        userDataPrepFuture,
      ]);
      final parallelDuration = DateTime.now().difference(parallelStart);

      AppLogger.auth(
        '✅ [RELEASE_OPTIMIZED] Parallel operations completed in ${parallelDuration.inMilliseconds}ms',
      );

      final GoogleSignInAuthentication googleAuth =
          parallelResults[0] as GoogleSignInAuthentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Failed to retrieve authentication tokens from Google';
      }

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      // RELEASE OPTIMIZATION: Firebase auth with shorter timeout (30s instead of 45s)
      final firebaseStart = DateTime.now();

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 30), // Reduced from 45s for faster UX
            onTimeout: () {
              AppLogger.auth(
                '⏰ [RELEASE_OPTIMIZED] Firebase auth timeout after 30s',
              );
              throw Exception(
                'Authentication is taking longer than expected. Please try again.',
              );
            },
          );

      final firebaseDuration = DateTime.now().difference(firebaseStart);
      AppLogger.auth(
        '✅ [RELEASE_OPTIMIZED] Firebase auth successful in ${firebaseDuration.inMilliseconds}ms',
      );

      // RELEASE OPTIMIZATION: Create minimal user record asynchronously for faster navigation
      _createOrUpdateUserMinimal(userCredential.user!); // Fire-and-forget

      // RELEASE OPTIMIZATION: Move all background operations to true background
      // Don't block navigation for any setup operations
      Future.delayed(const Duration(milliseconds: 500), () {
        _performBackgroundSetup(userCredential.user!);
        _updateUserFCMToken(userCredential.user!);
      });

      final totalDuration = DateTime.now().difference(startTime);
      stopPerformanceTimer('google_signin_release_optimized');

      AppLogger.auth(
        '🎉 [RELEASE_OPTIMIZED] Google Sign-In completed in ${totalDuration.inSeconds}s',
      );
      AppLogger.auth(
        '📊 [RELEASE_OPTIMIZED] Breakdown: Parallel=${parallelDuration.inMilliseconds}ms, Firebase=${firebaseDuration.inMilliseconds}ms',
      );

      return userCredential;
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      stopPerformanceTimer('google_signin_optimized');

      AppLogger.auth(
        '[GOOGLE_SIGNIN] Google Sign-In failed after ${totalDuration.inSeconds}s',
      );

      AppLogger.auth('[GOOGLE_SIGNIN] Error details: ${e.toString()}');
      AppLogger.auth('[GOOGLE_SIGNIN] Error type: ${e.runtimeType}');
      // Handle the special case where auth succeeded but timed out
      if (e.toString() == 'AUTH_SUCCESS_BUT_TIMEOUT') {
        AppLogger.auth(
          '✅ [GOOGLE_SIGNIN] Handling successful authentication that timed out',
        );

        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          AppLogger.auth(
            '✅ [GOOGLE_SIGNIN] Proceeding with authenticated user: ${currentUser.displayName} (UID: ${currentUser.uid})',
          );

          // Minimal user data for successful auth
          AppLogger.auth(
            '👤 [GOOGLE_SIGNIN] Creating minimal user record for timeout recovery...',
          );
          final recoveryStart = DateTime.now();
          await _createOrUpdateUserMinimal(currentUser);
          final recoveryDuration = DateTime.now().difference(recoveryStart);
          AppLogger.auth(
            '✅ [GOOGLE_SIGNIN] Recovery user record created in ${recoveryDuration.inMilliseconds}ms',
          );

          // Background setup
          _performBackgroundSetup(currentUser);
          AppLogger.auth(
            '✅ [GOOGLE_SIGNIN] Background setup initiated for timeout recovery',
          );

          AppLogger.auth(
            '🎉 [GOOGLE_SIGNIN] Google Sign-In completed successfully despite timeout',
          );
          return null; // Return null to indicate success but no UserCredential
        } else {
          AppLogger.auth(
            '[GOOGLE_SIGNIN] Timeout recovery failed - no current user found',
          );
        }
      }

      // Categorize and provide more specific error messages
      String errorCategory = 'unknown';
      String userMessage = 'Sign-in failed';

      if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorCategory = 'network';
        userMessage =
            'Network error during sign-in. Please check your internet connection and try again.';
        AppLogger.auth('🌐 [GOOGLE_SIGNIN] Network-related error detected');
      } else if (e.toString().contains('cancelled') ||
          e.toString().contains('CANCELLED')) {
        errorCategory = 'user_cancelled';
        userMessage = 'Sign-in was cancelled.';
        AppLogger.auth('🚫 [GOOGLE_SIGNIN] User cancelled the sign-in process');
      } else if (e.toString().contains('sign_in_failed') ||
          e.toString().contains('SIGN_IN_FAILED')) {
        errorCategory = 'auth_failed';
        userMessage = 'Authentication failed. Please try again.';
        AppLogger.auth('🔐 [GOOGLE_SIGNIN] Authentication failure detected');
      } else if (e.toString().contains('account') ||
          e.toString().contains('ACCOUNT')) {
        errorCategory = 'account_issue';
        userMessage =
            'Account selection failed. Please try selecting a different account.';
        AppLogger.auth('👤 [GOOGLE_SIGNIN] Account-related error detected');
      } else if (e.toString().contains('Firebase authentication timed out')) {
        errorCategory = 'firebase_timeout';
        userMessage =
            'Sign-in is taking longer than expected. Please wait a moment and try again.';
        AppLogger.auth(
          '⏰ [GOOGLE_SIGNIN] Firebase authentication timeout detected',
        );
      } else {
        errorCategory = 'unknown';
        userMessage = 'Sign-in failed: ${e.toString()}';
        AppLogger.auth('❓ [GOOGLE_SIGNIN] Unknown error category');
      }

      AppLogger.auth('📊 [GOOGLE_SIGNIN] Error summary:');
      AppLogger.auth('   - Category: $errorCategory');
      AppLogger.auth('   - Duration: ${totalDuration.inSeconds}s');
      AppLogger.auth('   - User message: $userMessage');

      throw userMessage;
    }
  }

  // Create or update user in Firestore - Optimized for performance
  Future<void> createOrUpdateUser(
    User firebaseUser, {
    String? name,
    String? role,
  }) async {
    startPerformanceTimer('user_data_setup');

    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        AppLogger.auth('👤 Creating new user record...');
        // Create new user with optimized data structure
        final userModel = UserModel(
          uid: firebaseUser.uid,
          name: name ?? firebaseUser.displayName ?? 'User',
          phone: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email,
          role: role ?? '', // Default to empty string for first-time users
          roleSelected: false,
          profileCompleted: false,
          electionAreas: [], // Will be set during profile completion
          premium: false,
          createdAt: DateTime.now(),
          photoURL: firebaseUser.photoURL,
        );

        // Use set with merge to ensure atomic operation
        await userDoc.set(userModel.toJson(), SetOptions(merge: true));

        // Create default quota for new user (optimized)
        // await _createDefaultUserQuotaOptimized(firebaseUser.uid);

        AppLogger.auth('✅ New user created successfully');
      } else {
        AppLogger.auth('🔄 Updating existing user record...');
        // Update existing user with minimal data transfer
        final updatedData = {
          'phone': firebaseUser.phoneNumber,
          'email': firebaseUser.email,
          'photoURL': firebaseUser.photoURL,
          'lastLogin': FieldValue.serverTimestamp(), // Track login time
        };

        // Only update non-null values to minimize data transfer
        final filteredData = Map<String, dynamic>.fromEntries(
          updatedData.entries.where((entry) => entry.value != null),
        );

        if (filteredData.isNotEmpty) {
          await userDoc.update(filteredData);
          AppLogger.auth('✅ User data updated successfully');
        } else {
          AppLogger.auth('ℹ️ No user data changes needed');
        }
      }

      stopPerformanceTimer('user_data_setup');
    } catch (e) {
      stopPerformanceTimer('user_data_setup');
      AppLogger.auth('Error in createOrUpdateUser: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign out - Enhanced to properly clear Google Sign-In cache and temporary data
  Future<void> signOut() async {
    try {
      AppLogger.auth('🚪 Starting enhanced sign-out process...');

      // Step 1: Sign out from Firebase Auth
      await _firebaseAuth.signOut();
      AppLogger.auth('✅ Firebase Auth sign-out completed');

      // Step 2: Sign out from Google (not disconnect - this preserves account selection)
      // Using signOut() instead of disconnect() to avoid token retrieval issues
      await _googleSignIn.signOut();
      AppLogger.auth('✅ Google account signed out');

      // Note: We keep the stored Google account info for smart login UX convenience
      // This allows users to quickly sign back in with the same account
      AppLogger.auth(
        'ℹ️ Stored Google account info preserved for quick re-login',
      );

      // Step 3: Clear app setup flags to force language selection and onboarding on next login
      await clearAppSetupFlags();
      AppLogger.auth(
        '✅ App setup flags cleared (language selection and onboarding will be shown again)',
      );

      // Step 4: Clear session-specific cache and temporary files (but keep user preferences)
      await _clearLogoutCache();
      AppLogger.auth('✅ Session cache cleared');

      // Step 5: Clear all GetX controllers to reset app state
      await _clearAllControllers();
      AppLogger.auth('✅ App controllers reset');

      AppLogger.auth('🚪 Enhanced sign-out completed successfully');
    } catch (e) {
      AppLogger.auth('⚠️ Error during enhanced sign-out: $e');
      // Fallback to basic sign-out if enhanced fails
      try {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        // Clear app setup flags even in fallback
        await clearAppSetupFlags();
        await _clearLogoutCache();
        await _clearAllControllers();
        AppLogger.auth('⚠️ Fallback sign-out completed');
      } catch (fallbackError) {
        AppLogger.auth('Fallback sign-out also failed: $fallbackError');
        // At minimum, try to clear controllers
        try {
          await _clearAllControllers();
        } catch (controllerError) {
          AppLogger.auth('Controller cleanup also failed: $controllerError');
        }
      }
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get current storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      final info = <String, dynamic>{
        'cache': <String, dynamic>{
          'files': 0,
          'size': 0,
          'path': cacheDir.path,
        },
        'appDocuments': <String, dynamic>{
          'files': 0,
          'size': 0,
          'path': appDir.path,
        },
        'appSupport': <String, dynamic>{
          'files': 0,
          'size': 0,
          'path': appSupportDir.path,
        },
        'total': <String, dynamic>{'files': 0, 'size': 0},
      };

      // Analyze cache directory
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        info['cache']!['files'] = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              info['cache']!['size'] =
                  (info['cache']!['size'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Analyze app documents directory
      if (await appDir.exists()) {
        final files = appDir.listSync(recursive: true);
        info['appDocuments']!['files'] = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              info['appDocuments']!['size'] =
                  (info['appDocuments']!['size'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Analyze app support directory
      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        info['appSupport']!['files'] = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              info['appSupport']!['size'] =
                  (info['appSupport']!['size'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Calculate totals
      info['total']!['files'] =
          (info['cache']!['files'] as int) +
          (info['appDocuments']!['files'] as int) +
          (info['appSupport']!['files'] as int);

      info['total']!['size'] =
          (info['cache']!['size'] as int) +
          (info['appDocuments']!['size'] as int) +
          (info['appSupport']!['size'] as int);

      return info;
    } catch (e) {
      AppLogger.auth('Could not get storage info: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'cache': <String, dynamic>{'files': 0, 'size': 0},
        'appDocuments': <String, dynamic>{'files': 0, 'size': 0},
        'appSupport': <String, dynamic>{'files': 0, 'size': 0},
        'total': <String, dynamic>{'files': 0, 'size': 0},
      };
    }
  }

  // Manually trigger storage cleanup (for user-initiated cleanup)
  Future<Map<String, dynamic>> manualStorageCleanup() async {
    try {
      AppLogger.auth('🧹 Manual storage cleanup initiated...');

      final result = <String, dynamic>{
        'initialSize': 0,
        'finalSize': 0,
        'cleanedSize': 0,
        'deletedFiles': 0,
        'deletedDirs': 0,
      };

      // Get initial size
      final cacheDir = await getTemporaryDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['initialSize'] =
                  (result['initialSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['initialSize'] =
                  (result['initialSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Perform cleanup
      await _clearLogoutCache();

      // Clear Firebase cache
      try {
        await _firestore.clearPersistence();
        AppLogger.auth('✅ Firebase cache cleared during manual cleanup');
      } catch (e) {
        AppLogger.auth('Warning: Could not clear Firebase cache: $e');
      }

      // Get final size
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['finalSize'] =
                  (result['finalSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['finalSize'] =
                  (result['finalSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      result['cleanedSize'] =
          (result['initialSize'] as int) - (result['finalSize'] as int);

      AppLogger.auth('✅ Manual cleanup completed:');
      AppLogger.auth(
        '   Initial size: ${(result['initialSize'] as int) / 1024 / 1024} MB',
      );
      AppLogger.auth(
        '   Final size: ${(result['finalSize'] as int) / 1024 / 1024} MB',
      );
      AppLogger.auth(
        '   Cleaned: ${(result['cleanedSize'] as int) / 1024 / 1024} MB',
      );

      return result;
    } catch (e) {
      AppLogger.auth('Manual storage cleanup failed: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'initialSize': 0,
        'finalSize': 0,
        'cleanedSize': 0,
        'deletedFiles': 0,
        'deletedDirs': 0,
      };
    }
  }

  // Analyze and clean up storage on app startup
  Future<void> analyzeAndCleanupStorage() async {
    try {
      AppLogger.auth('🔍 Analyzing app storage on startup...');

      // Log current storage state
      await _logStorageState('APP_STARTUP');

      // Check if this is first launch or if storage is excessive
      final cacheDir = await getTemporaryDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      int totalSize = 0;

      // Calculate cache size
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              totalSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Calculate app support size
      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              totalSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // If storage is excessive (>50MB), clean it up
      if (totalSize > 50 * 1024 * 1024) {
        AppLogger.auth(
          '⚠️ Excessive storage detected (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB), cleaning up...',
        );
        await _cleanupExcessiveStorage();
      } else {
        AppLogger.auth(
          '✅ Storage usage normal (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
      }
    } catch (e) {
      AppLogger.auth('ℹ️ Could not analyze storage: $e');
    }
  }

  // Clean up excessive storage
  Future<void> _cleanupExcessiveStorage() async {
    try {
      AppLogger.auth('🧹 Cleaning up excessive storage...');

      final cacheDir = await getTemporaryDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      int cleanedSize = 0;
      int deletedFiles = 0;

      // Clean old cache files (older than 7 days)
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

        for (final file in files) {
          if (file is File) {
            try {
              final stat = await file.stat();
              if (stat.modified.isBefore(sevenDaysAgo)) {
                final size = await file.length();
                await file.delete();
                cleanedSize += size;
                deletedFiles++;
                AppLogger.auth(
                  '🗑️ Deleted old cache file: ${file.path} (${(size / 1024).round()} KB)',
                );
              }
            } catch (e) {
              AppLogger.auth(
                'Warning: Could not delete cache file ${file.path}: $e',
              );
            }
          }
        }
      }

      // Clean Firebase cache if it's too large
      final firebaseCacheDir = Directory('${appSupportDir.path}/firebase');
      if (await firebaseCacheDir.exists()) {
        final firebaseFiles = firebaseCacheDir.listSync(recursive: true);
        int firebaseSize = 0;

        for (final file in firebaseFiles) {
          if (file is File) {
            try {
              firebaseSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }

        // If Firebase cache is >20MB, clear it
        if (firebaseSize > 20 * 1024 * 1024) {
          AppLogger.auth(
            '🔥 Firebase cache too large (${(firebaseSize / 1024 / 1024).toStringAsFixed(2)} MB), clearing...',
          );
          try {
            await _firestore.clearPersistence();
            cleanedSize += firebaseSize;
            AppLogger.auth('✅ Firebase cache cleared');
          } catch (e) {
            AppLogger.auth('Warning: Could not clear Firebase cache: $e');
          }
        }
      }

      if (cleanedSize > 0) {
        AppLogger.auth(
          '✅ Cleaned up ${(cleanedSize / 1024 / 1024).toStringAsFixed(2)} MB, deleted $deletedFiles files',
        );
      } else {
        AppLogger.auth('ℹ️ No excessive storage found to clean');
      }
    } catch (e) {
      AppLogger.auth('Warning: Could not cleanup excessive storage: $e');
    }
  }

  // Delete account and all associated data with proper batch size management
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      // If no user is currently signed in, still clear cache and controllers
      await _clearAppCache();
      await _clearAllControllers();
      return; // Consider this a successful "deletion" since user is already gone
    }

    final userId = user.uid;
    AppLogger.auth('🗑️ Starting account deletion for user: $userId');

    try {
      // Get user document to check if they're a candidate
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final isCandidate = userData?['role'] == 'candidate';

      // Delete data in chunks to avoid Firestore batch size limits (500 writes max)
      await _deleteUserDataInChunks(userId, isCandidate);

      // Clean up media files from Firebase Storage (after Firestore deletions)
      await _deleteUserMediaFiles(userId);

      // Delete from Firebase Auth BEFORE clearing cache
      AppLogger.auth('🔐 Deleting Firebase Auth account...');
      await user.delete();
      AppLogger.auth('✅ Firebase Auth account deleted');

      // Force sign out from Google (if applicable)
      await _googleSignIn.signOut();

      // Clear all local app data and cache AFTER auth deletion
      await _clearAppCache();

      // Clear all GetX controllers
      await _clearAllControllers();

      AppLogger.auth('✅ Account deletion completed successfully');
    } catch (e) {
      AppLogger.auth('Account deletion failed: $e');

      // If Firestore deletion fails, still try to delete from Auth
      try {
        await user.delete();
        await _googleSignIn.signOut();
        await _clearAppCache();
        await _clearAllControllers();
        AppLogger.auth('⚠️ Partial deletion completed - some data may remain');
      } catch (authError) {
        // If auth deletion also fails, still clear cache and controllers
        try {
          await _clearAppCache();
          await _clearAllControllers();
        } catch (cacheError) {
          // At minimum, try to clear controllers
          await _clearAllControllers();
        }
        // Don't throw auth error if user was already deleted
        if (!authError.toString().contains('no-current-user')) {
          throw 'Failed to delete account: $authError';
        }
      }
      // Don't throw Firestore errors if they are just permission/indexing issues
      if (!e.toString().contains('failed-precondition') &&
          !e.toString().contains('permission-denied')) {
        throw 'Failed to delete user data: $e';
      }
    }
  }

  // Delete user data in chunks to avoid Firestore batch size limits
  Future<void> _deleteUserDataInChunks(String userId, bool isCandidate) async {
    final batches = <WriteBatch>[];
    int currentBatchIndex = 0;

    // Helper function to get or create batch
    WriteBatch getCurrentBatch() {
      if (currentBatchIndex >= batches.length) {
        batches.add(_firestore.batch());
      }
      return batches[currentBatchIndex];
    }

    // Helper function to commit current batch if it's getting full
    Future<void> commitIfNeeded() async {
      // We can't check exact size, so we'll commit periodically
      // This is a simplified approach - in production, you'd track operations count
      if (batches.length > currentBatchIndex + 1) {
        await batches[currentBatchIndex].commit();
        currentBatchIndex++;
        AppLogger.auth('📦 Committed batch $currentBatchIndex');
      }
    }

    try {
      // 1. Delete user document and subcollections
      AppLogger.auth('📄 Deleting user document and subcollections...');
      await _deleteUserDocumentChunked(userId, getCurrentBatch, commitIfNeeded);

      // 2. Delete conversations and messages (this can be large)
      AppLogger.auth('💬 Deleting conversations and messages...');
      await _deleteConversationsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 3. Delete rewards
      AppLogger.auth('🏆 Deleting rewards...');
      await _deleteRewardsChunked(userId, getCurrentBatch, commitIfNeeded);

      // 4. Delete XP transactions
      // AppLogger.auth('⭐ Deleting XP transactions...');
      // await _deleteXpTransactionsChunked(
      //   userId,
      //   getCurrentBatch,
      //   commitIfNeeded,
      // );

      // 5. If user is a candidate, delete candidate data
      if (isCandidate) {
        AppLogger.auth('👥 Deleting candidate data...');
        await _deleteCandidateDataChunked(
          userId,
          getCurrentBatch,
          commitIfNeeded,
        );
      }

      // 6. Delete chat rooms created by the user
      AppLogger.auth('🏠 Deleting user chat rooms...');
      await _deleteUserChatRoomsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 7. Delete user quota data
      AppLogger.auth('📊 Deleting user quota...');
      // await _deleteUserQuota(userId, getCurrentBatch());

      // 8. Delete reported messages by the user
      AppLogger.auth('🚨 Deleting reported messages...');
      await _deleteUserReportedMessagesChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 9. Delete user subscriptions
      AppLogger.auth('💳 Deleting user subscriptions...');
      await _deleteUserSubscriptionsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 10. Delete user devices
      AppLogger.auth('📱 Deleting user devices...');
      await _deleteUserDevicesChunked(userId, getCurrentBatch, commitIfNeeded);

      // Commit all remaining batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        await batches[i].commit();
        AppLogger.auth('📦 Committed final batch ${i + 1}');
      }

      AppLogger.auth('✅ All user data deleted successfully');
    } catch (e) {
      AppLogger.auth('Error during chunked deletion: $e');
      // Try to commit any pending batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        try {
          await batches[i].commit();
        } catch (batchError) {
          AppLogger.auth('Failed to commit batch ${i + 1}: $batchError');
        }
      }
      rethrow;
    }
  }

  // Clear all app cache and local storage
  Future<void> _clearAppCache() async {
    try {
      AppLogger.auth('🧹 Starting comprehensive cache cleanup...');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      AppLogger.auth('✅ SharedPreferences cleared');

      // Clear Firebase local cache (handle errors gracefully)
      try {
        await _firestore.clearPersistence();
        AppLogger.auth('✅ Firebase local cache cleared');
      } catch (cacheError) {
        // Handle specific cache clearing errors gracefully
        final errorMessage = cacheError.toString();
        if (errorMessage.contains('failed-precondition') ||
            errorMessage.contains('not in a state') ||
            errorMessage.contains('Operation was rejected')) {
          AppLogger.auth(
            'ℹ️ Firebase cache clearing skipped (normal after account deletion)',
          );
        } else {
          AppLogger.auth(
            'Warning: Firebase cache clearing failed: $cacheError',
          );
        }
      }

      // Clear any cached data in Firebase Auth
      await _firebaseAuth.signOut();
      AppLogger.auth('✅ Firebase Auth cache cleared');

      // Clear image cache (if using cached_network_image or similar)
      await _clearImageCache();

      // Clear HTTP cache
      await _clearHttpCache();

      // Clear temporary files
      await _clearTempFiles();

      // Clear file upload service temp files
      await _clearFileUploadTempFiles();

      // Clear all app directories and cache
      await _clearAllAppDirectories();

      AppLogger.auth('✅ Comprehensive cache cleanup completed');
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some cache: $e');
      // Don't throw here as cache clearing failure shouldn't stop account deletion
    }
  }

  // Clear all GetX controllers (except LoginController which is needed for login screen)
  Future<void> _clearAllControllers() async {
    try {
      // Delete all registered controllers except LoginController (needed for login screen)
      // Don't clear LoginController as it's required when navigating back to login
      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }
      if (Get.isRegistered<CandidateController>()) {
        Get.delete<CandidateController>(force: true);
      }

      AppLogger.auth(
        '✅ Controllers cleared (LoginController preserved for login screen)',
      );
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some controllers: $e');
    }
  }

  // Clear cache for logout (lighter version that preserves user preferences)
  Future<void> _clearLogoutCache() async {
    try {
      AppLogger.auth('🧹 Starting logout cache cleanup...');

      // Log initial storage state
      await _logStorageState('BEFORE logout');

      // Clear Firebase local cache (but keep user data)
      try {
        await _firestore.clearPersistence();
        AppLogger.auth('✅ Firebase local cache cleared');
      } catch (cacheError) {
        // Handle specific cache clearing errors gracefully
        final errorMessage = cacheError.toString();
        if (errorMessage.contains('failed-precondition') ||
            errorMessage.contains('not in a state') ||
            errorMessage.contains('Operation was rejected')) {
          AppLogger.auth(
            'ℹ️ Firebase cache clearing skipped (normal after sign-out)',
          );
        } else {
          AppLogger.auth(
            'Warning: Firebase cache clearing failed: $cacheError',
          );
        }
      }

      // Clear image cache (session-specific images)
      await _clearImageCache();

      // Clear temporary files (now properly implemented)
      await _clearTempFiles();

      // Clear file upload service temp files (this actually works)
      await _clearFileUploadTempFiles();

      // Clear cache directory (but preserve user preferences in SharedPreferences)
      try {
        final cacheDir = await getTemporaryDirectory();
        AppLogger.auth('📁 Checking cache directory: ${cacheDir.path}');
        if (await cacheDir.exists()) {
          final files = cacheDir.listSync(recursive: true);
          AppLogger.auth('📊 Found ${files.length} items in cache directory');

          int deletedFiles = 0;
          int deletedDirs = 0;

          for (final file in files) {
            if (file is File) {
              try {
                final size = await file.length();
                await file.delete();
                deletedFiles++;
                AppLogger.auth(
                  '🗑️ Deleted cache file: ${file.path} ($size bytes)',
                );
              } catch (e) {
                AppLogger.auth(
                  'Warning: Failed to delete cache file ${file.path}: $e',
                );
              }
            } else if (file is Directory) {
              try {
                await file.delete(recursive: true);
                deletedDirs++;
                AppLogger.auth('🗑️ Deleted cache directory: ${file.path}');
              } catch (e) {
                AppLogger.auth(
                  'Warning: Failed to delete cache directory ${file.path}: $e',
                );
              }
            }
          }
          AppLogger.auth(
            '✅ Cache directory cleared - deleted $deletedFiles files and $deletedDirs directories',
          );
        } else {
          AppLogger.auth('ℹ️ Cache directory does not exist');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear cache directory: $e');
      }

      // Clear application documents temp directories
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final tempDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];

        for (final dirName in tempDirs) {
          try {
            final tempDir = Directory('${appDir.path}/$dirName');
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
              AppLogger.auth('✅ Cleared temp directory: $dirName');
            }
          } catch (e) {
            AppLogger.auth('Warning: Failed to clear $dirName: $e');
          }
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear app temp directories: $e');
      }

      AppLogger.auth('✅ Logout cache cleanup completed');

      // Log final storage state
      await _logStorageState('AFTER logout');

      // Log storage cleanup summary
      try {
        final cacheDir = await getTemporaryDirectory();
        final appDir = await getApplicationDocumentsDirectory();

        // Check remaining items
        int cacheItems = 0;
        int appTempItems = 0;

        if (await cacheDir.exists()) {
          cacheItems = cacheDir.listSync(recursive: true).length;
        }

        final tempDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];
        for (final dirName in tempDirs) {
          final tempDir = Directory('${appDir.path}/$dirName');
          if (await tempDir.exists()) {
            appTempItems += tempDir.listSync(recursive: true).length;
          }
        }

        AppLogger.auth('📊 Storage cleanup summary:');
        AppLogger.auth('   Cache directory: $cacheItems items remaining');
        AppLogger.auth('   App temp dirs: $appTempItems items remaining');
        AppLogger.auth('   ✅ Session data cleared successfully');
      } catch (e) {
        AppLogger.auth('ℹ️ Could not generate cleanup summary: $e');
      }
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some logout cache: $e');
    }
  }

  // Log storage state for debugging
  Future<void> _logStorageState(String context) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      int cacheFiles = 0;
      int cacheSize = 0;
      int appTempFiles = 0;
      int appSupportFiles = 0;
      int appSupportSize = 0;

      // Count cache directory files
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        cacheFiles = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              cacheSize += await file.length();
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }

      // Count app temp directory files
      final tempDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];
      for (final dirName in tempDirs) {
        final tempDir = Directory('${appDir.path}/$dirName');
        if (await tempDir.exists()) {
          appTempFiles += tempDir.listSync(recursive: true).length;
        }
      }

      // Count app support directory files (Firebase, etc.)
      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        appSupportFiles = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              appSupportSize += await file.length();
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }

      final totalSize = cacheSize + appSupportSize;

      AppLogger.auth('📊 Storage state $context:');
      AppLogger.auth(
        '   Cache directory: $cacheFiles files (${(cacheSize / 1024).round()} KB)',
      );
      AppLogger.auth('   App temp files: $appTempFiles items');
      AppLogger.auth(
        '   App support: $appSupportFiles files (${(appSupportSize / 1024).round()} KB)',
      );
      AppLogger.auth(
        '   📈 Total estimated: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Detailed breakdown if size is significant
      if (totalSize > 10 * 1024 * 1024) {
        // > 10MB
        await _analyzeLargeStorage(cacheDir, appDir, appSupportDir);
      }
    } catch (e) {
      AppLogger.auth('ℹ️ Could not log storage state: $e');
    }
  }

  // Analyze what's taking up large amounts of storage
  Future<void> _analyzeLargeStorage(
    Directory cacheDir,
    Directory appDir,
    Directory appSupportDir,
  ) async {
    try {
      AppLogger.auth('🔍 Analyzing large storage usage...');

      // Check cache directory breakdown
      if (await cacheDir.exists()) {
        final cacheContents = cacheDir.listSync(recursive: false);
        for (final item in cacheContents) {
          if (item is Directory) {
            final files = item.listSync(recursive: true);
            int dirSize = 0;
            for (final file in files) {
              if (file is File) {
                try {
                  dirSize += await file.length();
                } catch (e) {
                  // Skip
                }
              }
            }
            if (dirSize > 1024 * 1024) {
              // > 1MB
              AppLogger.auth(
                '   📁 Large cache dir: ${item.path} (${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB, ${files.length} files)',
              );
            }
          } else if (item is File) {
            try {
              final size = await item.length();
              if (size > 1024 * 1024) {
                // > 1MB
                AppLogger.auth(
                  '   📄 Large cache file: ${item.path} (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
                );
              }
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Check app support directory (Firebase, etc.)
      if (await appSupportDir.exists()) {
        final supportContents = appSupportDir.listSync(recursive: false);
        for (final item in supportContents) {
          if (item is Directory) {
            final files = item.listSync(recursive: true);
            int dirSize = 0;
            for (final file in files) {
              if (file is File) {
                try {
                  dirSize += await file.length();
                } catch (e) {
                  // Skip
                }
              }
            }
            if (dirSize > 1024 * 1024) {
              // > 1MB
              AppLogger.auth(
                '   📁 Large support dir: ${item.path} (${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB, ${files.length} files)',
              );
            }
          } else if (item is File) {
            try {
              final size = await item.length();
              if (size > 1024 * 1024) {
                // > 1MB
                AppLogger.auth(
                  '   📄 Large support file: ${item.path} (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
                );
              }
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Check for Firebase cache specifically
      final firebaseCacheDir = Directory('${appSupportDir.path}/firebase');
      if (await firebaseCacheDir.exists()) {
        final firebaseFiles = firebaseCacheDir.listSync(recursive: true);
        int firebaseSize = 0;
        for (final file in firebaseFiles) {
          if (file is File) {
            try {
              firebaseSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
        AppLogger.auth(
          '   🔥 Firebase cache: ${firebaseFiles.length} files (${(firebaseSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
      }
    } catch (e) {
      AppLogger.auth('ℹ️ Could not analyze large storage: $e');
    }
  }

  // Clear image cache
  Future<void> _clearImageCache() async {
    try {
      // Clear Flutter's image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      AppLogger.auth('✅ Flutter image cache cleared');

      // Note: If using cached_network_image package, you would also clear its cache:
      // await DefaultCacheManager().emptyCache();
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear image cache: $e');
    }
  }

  // Clear HTTP cache
  Future<void> _clearHttpCache() async {
    try {
      // Note: Flutter doesn't have a built-in HTTP cache, but if you're using
      // packages like dio with cache interceptors, you would clear them here
      AppLogger.auth(
        'ℹ️ HTTP cache clearing not implemented (no HTTP caching detected)',
      );
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear HTTP cache: $e');
    }
  }

  // Clear temporary files
  Future<void> _clearTempFiles() async {
    try {
      // Clear system temp directory
      final systemTempDir = Directory.systemTemp;
      if (await systemTempDir.exists()) {
        final tempFiles = systemTempDir.listSync(recursive: false);
        int deletedCount = 0;

        for (final file in tempFiles) {
          try {
            if (file is File) {
              // Only delete files older than 1 hour to be safe
              final stat = await file.stat();
              final age = DateTime.now().difference(stat.modified);
              if (age.inHours > 1) {
                await file.delete();
                deletedCount++;
              }
            } else if (file is Directory) {
              // Only delete empty directories or those older than 1 hour
              final stat = await file.stat();
              final age = DateTime.now().difference(stat.modified);
              if (age.inHours > 1) {
                try {
                  await file.delete(recursive: true);
                  deletedCount++;
                } catch (e) {
                  // Directory not empty, skip
                }
              }
            }
          } catch (e) {
            AppLogger.auth(
              'Warning: Failed to delete temp item ${file.path}: $e',
            );
          }
        }

        if (deletedCount > 0) {
          AppLogger.auth('✅ Cleared $deletedCount temp files/directories');
        } else {
          AppLogger.auth('ℹ️ No old temp files to clear');
        }
      }
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear temp files: $e');
    }
  }

  // Clear file upload service temporary files
  Future<void> _clearFileUploadTempFiles() async {
    try {
      // Import the service dynamically to avoid circular dependencies
      // This is a simplified approach - in production, you'd inject the service

      // Clear temp photos directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        final tempDir = Directory('${directory.path}/temp_photos');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          AppLogger.auth('✅ File upload temp photos cleared');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear temp photos: $e');
      }

      // Clear media temp directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        final mediaTempDir = Directory('${directory.path}/media_temp');
        if (await mediaTempDir.exists()) {
          await mediaTempDir.delete(recursive: true);
          AppLogger.auth('✅ File upload media temp files cleared');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear media temp files: $e');
      }
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear file upload temp files: $e');
    }
  }

  // Clear all app directories and cache
  Future<void> _clearAllAppDirectories() async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      AppLogger.auth('📁 Clearing app directory: ${appDir.path}');

      // Clear all subdirectories except those we want to keep
      final subDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];
      for (final subDirName in subDirs) {
        try {
          final subDir = Directory('${appDir.path}/$subDirName');
          if (await subDir.exists()) {
            await subDir.delete(recursive: true);
            AppLogger.auth('✅ Cleared directory: $subDirName');
          }
        } catch (e) {
          AppLogger.auth('Warning: Failed to clear $subDirName: $e');
        }
      }

      // Clear cache directory
      try {
        final cacheDir = await getTemporaryDirectory();
        if (await cacheDir.exists()) {
          // Clear all files in cache directory
          final files = cacheDir.listSync(recursive: true);
          for (final file in files) {
            if (file is File) {
              try {
                await file.delete();
              } catch (e) {
                AppLogger.auth(
                  'Warning: Failed to delete cache file ${file.path}: $e',
                );
              }
            }
          }
          AppLogger.auth('✅ Cache directory cleared');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear cache directory: $e');
      }

      // Note: External storage cache clearing removed to avoid import complexity
      // In production, you might want to add this back with proper platform-specific imports
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear app directories: $e');
    }
  }

  // Chunked deletion methods to handle large datasets
  Future<void> _deleteUserDocumentChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Delete following subcollection
    final followingSnapshot = await userRef.collection('following').get();
    for (final doc in followingSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }

    // Delete main user document
    getBatch().delete(userRef);
  }

  Future<void> _deleteConversationsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .get();

    for (final conversationDoc in conversationsSnapshot.docs) {
      // Delete messages subcollection (this can be very large)
      final messagesSnapshot = await conversationDoc.reference
          .collection('messages')
          .get();
      for (final messageDoc in messagesSnapshot.docs) {
        getBatch().delete(messageDoc.reference);
        await commitIfNeeded();
      }

      // Delete conversation document
      getBatch().delete(conversationDoc.reference);
      await commitIfNeeded();
    }
  }

  Future<void> _deleteRewardsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    final rewardsSnapshot = await _firestore
        .collection('rewards')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in rewardsSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }
  }

  // Future<void> _deleteXpTransactionsChunked(
  //   String userId,
  //   WriteBatch Function() getBatch,
  //   Future<void> Function() commitIfNeeded,
  // ) async {
  //   final xpTransactionsSnapshot = await _firestore
  //       .collection('xp_transactions')
  //       .where('userId', isEqualTo: userId)
  //       .get();

  //   for (final doc in xpTransactionsSnapshot.docs) {
  //     getBatch().delete(doc.reference);
  //     await commitIfNeeded();
  //   }
  // }

  Future<void> _deleteCandidateDataChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      // Find candidate document in hierarchical structure
      // First, search through all districts and wards to find the candidate
      final districtsSnapshot = await _firestore.collection('districts').get();

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference
            .collection('bodies')
            .get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference
              .collection('wards')
              .get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidateSnapshot = await wardDoc.reference
                .collection('candidates')
                .where('userId', isEqualTo: userId)
                .limit(1)
                .get();

            if (candidateSnapshot.docs.isNotEmpty) {
              final candidateDoc = candidateSnapshot.docs.first;

              // Delete followers subcollection
              final followersSnapshot = await candidateDoc.reference
                  .collection('followers')
                  .get();
              for (final followerDoc in followersSnapshot.docs) {
                getBatch().delete(followerDoc.reference);
                await commitIfNeeded();
              }

              // Delete candidate document from hierarchical structure
              getBatch().delete(candidateDoc.reference);
              await commitIfNeeded();

              AppLogger.auth(
                '✅ Deleted candidate data from: /districts/${districtDoc.id}/bodies/${bodyDoc.id}/wards/${wardDoc.id}/candidates/${candidateDoc.id}',
              );
              return; // Found and deleted, no need to continue searching
            }
          }
        }
      }

      AppLogger.auth('⚠️ No candidate data found for user: $userId');
    } catch (e) {
      AppLogger.auth('Error deleting candidate data: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserChatRoomsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      // Find all chat rooms created by the user
      final chatRoomsSnapshot = await _firestore
          .collection('chats')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (final roomDoc in chatRoomsSnapshot.docs) {
        final roomId = roomDoc.id;

        // Delete all messages in the room (can be very large)
        final messagesSnapshot = await roomDoc.reference
            .collection('messages')
            .get();
        for (final messageDoc in messagesSnapshot.docs) {
          getBatch().delete(messageDoc.reference);
          await commitIfNeeded();
        }

        // Delete all polls in the room
        final pollsSnapshot = await roomDoc.reference.collection('polls').get();
        for (final pollDoc in pollsSnapshot.docs) {
          getBatch().delete(pollDoc.reference);
          await commitIfNeeded();
        }

        // Delete the chat room itself
        getBatch().delete(roomDoc.reference);
        await commitIfNeeded();

        AppLogger.auth(
          '✅ Deleted chat room: $roomId with ${messagesSnapshot.docs.length} messages and ${pollsSnapshot.docs.length} polls',
        );
      }

      AppLogger.auth(
        '✅ Deleted ${chatRoomsSnapshot.docs.length} chat rooms created by user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user chat rooms: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserReportedMessagesChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      // Find all reported messages by the user
      final reportsSnapshot = await _firestore
          .collection('reported_messages')
          .where('reporterId', isEqualTo: userId)
          .get();

      for (final reportDoc in reportsSnapshot.docs) {
        getBatch().delete(reportDoc.reference);
        await commitIfNeeded();
      }

      AppLogger.auth(
        '✅ Deleted ${reportsSnapshot.docs.length} reported messages by user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user reported messages: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserSubscriptionsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      // Find all subscriptions for the user
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      for (final subscriptionDoc in subscriptionsSnapshot.docs) {
        getBatch().delete(subscriptionDoc.reference);
        await commitIfNeeded();
      }

      AppLogger.auth(
        '✅ Deleted ${subscriptionsSnapshot.docs.length} subscriptions for user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user subscriptions: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserDevicesChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // Delete devices subcollection
      final devicesSnapshot = await userRef.collection('devices').get();
      for (final deviceDoc in devicesSnapshot.docs) {
        getBatch().delete(deviceDoc.reference);
        await commitIfNeeded();
      }

      AppLogger.auth(
        '✅ Deleted ${devicesSnapshot.docs.length} devices for user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user devices: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserMediaFiles(String userId) async {
    try {
      // Note: Firebase Storage deletion is more complex and might require
      // listing all files in the user's media folder and deleting them individually
      // For now, we'll log this as a reminder that media files should be cleaned up
      AppLogger.auth(
        '📝 Reminder: Media files in Firebase Storage for user $userId should be manually cleaned up',
      );
      AppLogger.auth('   Location: chat_media/ and other user-uploaded files');

      // In a production app, you would:
      // 1. List all files in user's media folders
      // 2. Delete each file individually
      // 3. This can be expensive, so consider doing it asynchronously
    } catch (e) {
      AppLogger.auth('Error deleting user media files: $e');
      // Don't throw here as media cleanup is not critical
    }
  }

  // Optimized authentication methods for faster login

  // Check if an error is retryable
  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unreachable');
  }

  // Simplified Firebase authentication - removed retry logic for faster feedback
  // Firebase auth should be fast with valid Google tokens

  // Prepare user data locally (fast operation)
  Future<Map<String, dynamic>> _prepareUserDataLocally(
    GoogleSignInAccount googleUser,
  ) async {
    AppLogger.auth('📋 Preparing user data locally...');

    final userData = {
      'name': googleUser.displayName ?? 'User',
      'email': googleUser.email,
      'photoURL': googleUser.photoUrl,
      'preparedAt': DateTime.now().toIso8601String(),
    };


    AppLogger.auth('✅ User data prepared and cached locally');
    return userData;
  }

  // Create minimal user record (fast operation)
  Future<void> _createOrUpdateUserMinimal(User firebaseUser) async {
    startPerformanceTimer('minimal_user_creation');

    try {
      AppLogger.auth('👤 Creating minimal user record...');

      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);

      // Only store essential login data immediately
      final minimalData = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'lastLogin': FieldValue.serverTimestamp(),
        'loginCount': FieldValue.increment(1),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use set with merge for atomic operation
      await userDoc.set(minimalData, SetOptions(merge: true));

      AppLogger.auth('✅ Minimal user record created');
    } catch (e) {
      AppLogger.auth('Error creating minimal user record: $e');
      rethrow;
    } finally {
      stopPerformanceTimer('minimal_user_creation');
    }
  }

  // Perform background setup operations (non-blocking)
  void _performBackgroundSetup(User user) {
    AppLogger.auth('🔄 Starting background setup...');

    // Use the background sync manager for comprehensive sync
    _syncManager.performFullBackgroundSync(user);
  }

  // Update user's FCM token for push notifications
  Future<void> _updateUserFCMToken(User user) async {
    try {
      AppLogger.auth('📱 Updating FCM token for user: ${user.uid}');

      // Get current FCM token
      final fcmToken = await _fcmService.getCurrentToken();

      if (fcmToken != null) {
        // Update token in user's document
        await _fcmService.updateUserFCMToken(user.uid, fcmToken);
        AppLogger.auth('✅ FCM token updated for user: ${user.uid}');
      } else {
        AppLogger.auth('⚠️ No FCM token available for user: ${user.uid}');
      }
    } catch (e) {
      AppLogger.auth('Error updating FCM token: $e');
      // Don't throw - FCM token update failure shouldn't break authentication
    }
  }

  // Store last used Google account info for smart login UX - Enhanced Version
  Future<void> _storeLastGoogleAccount(GoogleSignInAccount account) async {
    try {
      // Validate account data before storing
      if (account.email == null || account.email.isEmpty) {
        AppLogger.auth(
          '⚠️ Cannot store Google account: email is null or empty',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final accountData = {
        'email': account.email,
        'displayName': account.displayName ?? 'User',
        'photoUrl': account.photoUrl,
        'id': account.id,
        'lastLogin': DateTime.now().toIso8601String(),
        'serverAuthCode': account.serverAuthCode, // For enhanced security
        'version': '2.0', // Version for future migrations
      };

      // Properly encode as JSON string with error handling
      final accountJson = jsonEncode(accountData);
      await prefs.setString('last_google_account', accountJson);

      // Also store backup copy for recovery
      await prefs.setString('last_google_account_backup', accountJson);

      AppLogger.auth(
        '✅ Enhanced account storage: ${account.email} (v2.0 with backup)',
      );
    } catch (e) {
      AppLogger.auth('⚠️ Error storing last Google account: $e');
      // Try to store minimal data as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final minimalData = {
          'email': account.email ?? 'unknown',
          'displayName': account.displayName ?? 'User',
          'lastLogin': DateTime.now().toIso8601String(),
          'version': '1.0', // Fallback version
        };
        await prefs.setString('last_google_account', jsonEncode(minimalData));
        AppLogger.auth('✅ Fallback account storage successful');
      } catch (fallbackError) {
        AppLogger.auth(
          '⚠️ Fallback account storage also failed: $fallbackError',
        );
      }
    }
  }

  // Get last used Google account info - Enhanced with recovery and validation
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accountData = prefs.getString('last_google_account');

      // If primary data is missing, try backup
      if (accountData == null) {
        AppLogger.auth('ℹ️ Primary account data not found, checking backup...');
        accountData = prefs.getString('last_google_account_backup');

        if (accountData == null) {
          AppLogger.auth(
            'ℹ️ No stored Google account found (primary or backup)',
          );
          return null;
        } else {
          AppLogger.auth('📋 Found backup Google account data, restoring...');
          // Restore from backup to primary
          await prefs.setString('last_google_account', accountData);
        }
      }

      AppLogger.auth('📋 Found stored Google account data');

      // Parse the stored JSON string
      final accountMap = jsonDecode(accountData) as Map<String, dynamic>;

      // Validate the account data structure
      if (!_isValidAccountData(accountMap)) {
        AppLogger.auth('⚠️ Invalid account data structure, clearing...');
        await prefs.remove('last_google_account');
        return null;
      }

      // Check if account data is too old (older than 30 days)
      final lastLoginStr = accountMap['lastLogin'] as String?;
      if (lastLoginStr != null) {
        try {
          final lastLogin = DateTime.parse(lastLoginStr);
          final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;

          if (daysSinceLogin > 30) {
            AppLogger.auth(
              '⚠️ Account data is ${daysSinceLogin} days old, clearing for security',
            );
            await prefs.remove('last_google_account');
            await prefs.remove('last_google_account_backup');
            return null;
          }
        } catch (e) {
          AppLogger.auth('⚠️ Could not parse last login date: $e');
          // Continue with the data but log the issue
        }
      }

      AppLogger.auth(
        '✅ Successfully parsed and validated stored account: ${accountMap['displayName']} (${accountMap['email']})',
      );

      return accountMap;
    } catch (e) {
      AppLogger.auth('⚠️ Error retrieving last Google account: $e');
      // Clear corrupted data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_google_account');
        await prefs.remove('last_google_account_backup');
        AppLogger.auth(
          '🧹 Cleared corrupted account data (primary and backup)',
        );
      } catch (clearError) {
        AppLogger.auth('⚠️ Error clearing corrupted data: $clearError');
      }
      return null;
    }
  }

  // Validate account data structure
  bool _isValidAccountData(Map<String, dynamic> accountData) {
    // Check for required fields
    final requiredFields = ['email', 'displayName'];
    for (final field in requiredFields) {
      if (!accountData.containsKey(field) || accountData[field] == null) {
        AppLogger.auth('⚠️ Missing required field: $field');
        return false;
      }
    }

    // Validate email format
    final email = accountData['email'] as String;
    if (!email.contains('@') || !email.contains('.')) {
      AppLogger.auth('⚠️ Invalid email format: $email');
      return false;
    }

    return true;
  }

  // Clear stored Google account info (on logout) - Enhanced to clear both primary and backup
  Future<void> clearLastGoogleAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_google_account');
      await prefs.remove('last_google_account_backup');
      AppLogger.auth('✅ Cleared last Google account info (primary and backup)');
    } catch (e) {
      AppLogger.auth('⚠️ Error clearing last Google account: $e');
    }
  }

  // Clear all app setup flags (for complete reset)
  Future<void> clearAppSetupFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_first_time');
      await prefs.remove('onboarding_completed');
      AppLogger.auth(
        '✅ Cleared app setup flags (language selection and onboarding)',
      );
    } catch (e) {
      AppLogger.auth('⚠️ Error clearing app setup flags: $e');
    }
  }
}
