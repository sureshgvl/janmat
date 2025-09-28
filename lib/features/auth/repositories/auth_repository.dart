import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../models/user_model.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../candidate/controllers/candidate_controller.dart';
import '../../../services/admob_service.dart';
import '../../../services/user_cache_service.dart';
import '../../../services/background_sync_manager.dart';
import '../../../utils/performance_monitor.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    forceCodeForRefreshToken: true,
    scopes: ['email', 'profile'],
  );
  final UserCacheService _cacheService = UserCacheService();
  final BackgroundSyncManager _syncManager = BackgroundSyncManager();


  // Phone Authentication with improved reCAPTCHA handling and timeout
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
  ) async {
    debugPrint('📞 Initiating phone verification for: +91$phoneNumber');

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Phone verification completed automatically');
          // Auto-verification successful, sign in immediately
          try {
            await _firebaseAuth.signInWithCredential(credential);
            debugPrint('✅ Auto-signed in with phone credential');
          } catch (e) {
            debugPrint('❌ Auto-sign in failed: $e');
            rethrow;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.message}');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📱 OTP sent successfully, verification ID: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Auto-retrieval timeout, manual OTP entry required');
          // This is called when auto-retrieval times out
          // The verificationId is still valid for manual OTP entry
          onCodeSent(verificationId);
        },
        // Force reCAPTCHA to be more responsive
        timeout: const Duration(seconds: 30), // Reduced timeout for better UX
        // Enable forceResendingToken for better UX
        forceResendingToken: null,
      ).timeout(
        const Duration(seconds: 60), // Overall timeout for the entire operation
        onTimeout: () {
          debugPrint('⏰ Phone verification timed out after 60 seconds');
          throw Exception('Phone verification timed out. Please check your internet connection and try again.');
        },
      );

      debugPrint('📞 Phone verification setup completed');
    } catch (e) {
      debugPrint('❌ Phone verification setup failed: $e');
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
      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);
      debugPrint('🌐 Network connectivity check: ${hasConnection ? 'Connected' : 'No connection'}');
      return hasConnection;
    } catch (e) {
      debugPrint('⚠️ Could not check connectivity: $e');
      return true; // Assume connected if check fails
    }
  }

  // Google Sign-In - Optimized with parallel processing and smart account switching
  Future<UserCredential?> signInWithGoogle({bool forceAccountPicker = false}) async {
    final startTime = DateTime.now();
    startPerformanceTimer('google_signin_optimized');

    debugPrint('🚀 [GOOGLE_SIGNIN] Starting optimized Google Sign-In with parallel processing at ${startTime.toIso8601String()}');

    try {
      // Step 0: Check network connectivity
      debugPrint('🌐 [GOOGLE_SIGNIN] Checking network connectivity...');
      final connectivityStart = DateTime.now();
      final hasConnectivity = await _checkConnectivity();
      final connectivityDuration = DateTime.now().difference(connectivityStart);

      debugPrint('🌐 [GOOGLE_SIGNIN] Network connectivity check completed in ${connectivityDuration.inMilliseconds}ms - Connected: $hasConnectivity');

      if (!hasConnectivity) {
        debugPrint('❌ [GOOGLE_SIGNIN] No internet connection detected');
        throw Exception('No internet connection detected. Please check your network and try again.');
      }

      // Step 1: Smart Google Sign-In with account switching support
      debugPrint('📱 [GOOGLE_SIGNIN] Starting Google Sign-In (${forceAccountPicker ? 'forced account picker' : 'smart mode'})...');

      GoogleSignInAccount? googleUser;
      int retryCount = 0;
      const maxRetries = 2;
      Duration? signInDuration; // Track total account selection time

      while (retryCount <= maxRetries) {
        final attemptStart = DateTime.now();
        debugPrint('🎯 [GOOGLE_SIGNIN] Attempt ${retryCount + 1}/${maxRetries + 1} - ${forceAccountPicker ? 'Forced account picker' : 'Smart sign-in'}');

        try {
          // Always force account picker when requested, otherwise try silent first
          if (!forceAccountPicker) {
            // For "Continue as", we expect a specific account - get the stored account info first
            final storedAccount = await getLastGoogleAccount();
            final expectedEmail = storedAccount?['email'];

            debugPrint('🔍 [GOOGLE_SIGNIN] "Continue as" mode - expecting account: ${storedAccount?['displayName']} (${expectedEmail})');

            // For "Continue as", we need to ensure we get the expected account
            // If silent sign-in returns a different account, we should force account picker
            debugPrint('🔍 [GOOGLE_SIGNIN] Checking for existing silent session...');
            try {
              final silentStart = DateTime.now();
              final silentUser = await _googleSignIn.signInSilently()
                .timeout(const Duration(seconds: 5)); // Increased timeout for better success rate

              final silentDuration = DateTime.now().difference(silentStart);

              if (silentUser != null) {
                debugPrint('✅ [GOOGLE_SIGNIN] Silent sign-in successful: ${silentUser.displayName} (${silentUser.email}) in ${silentDuration.inMilliseconds}ms');

                // Validate that silent sign-in returned the expected account
                if (expectedEmail != null && silentUser.email == expectedEmail) {
                  debugPrint('✅ [GOOGLE_SIGNIN] Silent sign-in returned expected account - using it');
                  googleUser = silentUser;
                  break; // Success - use silent sign-in result
                } else {
                  debugPrint('⚠️ [GOOGLE_SIGNIN] Silent sign-in returned different account than expected');
                  debugPrint('   Expected: $expectedEmail, Got: ${silentUser.email}');
                  debugPrint('🔄 [GOOGLE_SIGNIN] Forcing account picker to get correct account');

                  // Force account picker by disconnecting and using fresh instance
                  try {
                    await _googleSignIn.disconnect();
                    debugPrint('✅ [GOOGLE_SIGNIN] Disconnected current session for account switch');
                  } catch (e) {
                    debugPrint('ℹ️ [GOOGLE_SIGNIN] Disconnect failed: ${e.toString()}');
                  }

                  // Use fresh instance to force account picker
                  final freshGoogleSignIn = GoogleSignIn(
                    forceCodeForRefreshToken: true,
                    scopes: ['email', 'profile'],
                  );

                  debugPrint('📱 [GOOGLE_SIGNIN] Using fresh instance for account picker...');
                  final pickerStart = DateTime.now();

                  googleUser = await freshGoogleSignIn.signIn().timeout(
                    const Duration(seconds: 60),
                    onTimeout: () {
                      final timeoutDuration = DateTime.now().difference(pickerStart);
                      debugPrint('⏰ [GOOGLE_SIGNIN] Account picker timeout after ${timeoutDuration.inSeconds} seconds');
                      throw Exception('Sign-in timed out. Please try again.');
                    },
                  );

                  final pickerDuration = DateTime.now().difference(pickerStart);
                  debugPrint('✅ [GOOGLE_SIGNIN] Account picker completed in ${pickerDuration.inSeconds}s');

                  if (googleUser != null) {
                    await _storeLastGoogleAccount(googleUser);
                    break; // Success
                  }
                }
              } else {
                debugPrint('ℹ️ [GOOGLE_SIGNIN] Silent sign-in returned null in ${silentDuration.inMilliseconds}ms');
                // Fall through to normal sign-in
              }
            } catch (e) {
              debugPrint('ℹ️ [GOOGLE_SIGNIN] Silent sign-in failed or timed out: ${e.toString()}');
              // Fall through to normal sign-in
            }

            // Try normal sign-in for "Continue as" (allows user to select the expected account)
            debugPrint('🔄 [GOOGLE_SIGNIN] Attempting normal sign-in for "Continue as"...');
            final normalSignInStart = DateTime.now();

            googleUser = await _googleSignIn.signIn().timeout(
              const Duration(seconds: 60), // Longer timeout for user interaction
              onTimeout: () {
                debugPrint('⏰ [GOOGLE_SIGNIN] Normal sign-in timeout for "Continue as"');
                throw Exception('Sign-in timed out. Please try again or use "Sign in with different account".');
              },
            );

            final normalSignInDuration = DateTime.now().difference(normalSignInStart);
            debugPrint('✅ [GOOGLE_SIGNIN] Normal sign-in completed in ${normalSignInDuration.inSeconds}s');

            if (googleUser != null) {
              await _storeLastGoogleAccount(googleUser);
              break; // Success
            }
          }

          // Force account picker (either requested or silent failed)
          debugPrint('🔄 [GOOGLE_SIGNIN] Preparing account picker...');

          // For forced account picker, we need to ensure complete cleanup
          if (forceAccountPicker) {
            debugPrint('🔄 [GOOGLE_SIGNIN] Forced account picker requested - ensuring clean state...');

            // Create a fresh GoogleSignIn instance to force account picker
            final freshGoogleSignIn = GoogleSignIn(
              forceCodeForRefreshToken: true,
              scopes: ['email', 'profile'],
            );

            // Try to disconnect with the fresh instance
            try {
              await freshGoogleSignIn.disconnect();
              debugPrint('✅ [GOOGLE_SIGNIN] Fresh instance disconnect successful');
            } catch (e) {
              debugPrint('ℹ️ [GOOGLE_SIGNIN] Fresh instance disconnect failed: ${e.toString()}');
            }

            // Clear any cached account data
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('last_google_account');
              debugPrint('✅ [GOOGLE_SIGNIN] Cleared cached account data');
            } catch (e) {
              debugPrint('⚠️ [GOOGLE_SIGNIN] Failed to clear cached account data: $e');
            }

            // Use the fresh instance for sign-in to force account picker
            debugPrint('📱 [GOOGLE_SIGNIN] Using fresh GoogleSignIn instance for account picker...');
            final signInStart = DateTime.now();

            googleUser = await freshGoogleSignIn.signIn().timeout(
              const Duration(seconds: 90),
              onTimeout: () {
                final timeoutDuration = DateTime.now().difference(signInStart);
                debugPrint('⏰ [GOOGLE_SIGNIN] Fresh instance account picker timeout after ${timeoutDuration.inSeconds} seconds');
                throw Exception('Google Sign-In timed out. Please ensure you have a stable internet connection and try selecting an account within 90 seconds.');
              },
            );

            signInDuration = DateTime.now().difference(signInStart);
            debugPrint('✅ [GOOGLE_SIGNIN] Fresh instance account picker completed in ${signInDuration!.inSeconds}s');

            if (googleUser != null) {
              await _storeLastGoogleAccount(googleUser);
              break; // Success
            }
          } else {
            // Normal disconnect for regular account picker
            try {
              await _googleSignIn.disconnect();
              debugPrint('✅ [GOOGLE_SIGNIN] Disconnected previous session');
            } catch (e) {
              debugPrint('ℹ️ [GOOGLE_SIGNIN] No active session to disconnect: ${e.toString()}');
            }

            await Future.delayed(const Duration(milliseconds: 500)); // Brief delay

            debugPrint('📱 [GOOGLE_SIGNIN] Showing Google account picker...');
            final signInStart = DateTime.now();

            googleUser = await _googleSignIn.signIn().timeout(
              const Duration(seconds: 90),
              onTimeout: () {
                final timeoutDuration = DateTime.now().difference(signInStart);
                debugPrint('⏰ [GOOGLE_SIGNIN] Account picker timeout after ${timeoutDuration.inSeconds} seconds');
                throw Exception('Google Sign-In timed out. Please ensure you have a stable internet connection and try selecting an account within 90 seconds.');
              },
            );

            signInDuration = DateTime.now().difference(signInStart);
            debugPrint('✅ [GOOGLE_SIGNIN] Account picker completed in ${signInDuration!.inSeconds}s');
          }

          debugPrint('📱 [GOOGLE_SIGNIN] Showing Google account picker...');
          final signInStart = DateTime.now();

          googleUser = await _googleSignIn.signIn().timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              final timeoutDuration = DateTime.now().difference(signInStart);
              debugPrint('⏰ [GOOGLE_SIGNIN] Account picker timeout after ${timeoutDuration.inSeconds} seconds');
              throw Exception('Google Sign-In timed out. Please ensure you have a stable internet connection and try selecting an account within 90 seconds.');
            },
          );

          signInDuration = DateTime.now().difference(signInStart);
          debugPrint('✅ [GOOGLE_SIGNIN] Account picker completed in ${signInDuration!.inSeconds}s');

          if (googleUser != null) {
            debugPrint('✅ [GOOGLE_SIGNIN] User selected: ${googleUser.displayName} (${googleUser.email})');

            // Store account info for future logins
            await _storeLastGoogleAccount(googleUser);

            break; // Success
          }

        } catch (e) {
          final attemptDuration = DateTime.now().difference(attemptStart);
          retryCount++;

          if (retryCount <= maxRetries && _isRetryableError(e)) {
            debugPrint('🔄 [GOOGLE_SIGNIN] Sign-in error, retrying... (attempt $retryCount/$maxRetries)');
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          } else {
            debugPrint('❌ [GOOGLE_SIGNIN] Sign-in failed: ${e.toString()}');
            rethrow;
          }
        }
      }

      if (googleUser == null) {
        final totalDuration = DateTime.now().difference(startTime);
        stopPerformanceTimer('google_signin_optimized');
        debugPrint('❌ [GOOGLE_SIGNIN] User cancelled Google Sign-In after ${totalDuration.inSeconds}s');
        return null; // User cancelled
      }

      debugPrint('✅ [GOOGLE_SIGNIN] Google account selected: ${googleUser.displayName} (ID: ${googleUser.id})');

      // Step 2: Parallel processing - Get tokens and prepare user data simultaneously
      debugPrint('🔄 [GOOGLE_SIGNIN] Starting parallel authentication and data preparation...');
      final parallelStart = DateTime.now();

      final tokenFuture = googleUser.authentication;
      final userDataPrepFuture = _prepareUserDataLocally(googleUser);

      debugPrint('⏳ [GOOGLE_SIGNIN] Awaiting parallel operations: token retrieval + user data preparation');

      final parallelResults = await Future.wait([tokenFuture, userDataPrepFuture]);
      final parallelDuration = DateTime.now().difference(parallelStart);

      debugPrint('✅ [GOOGLE_SIGNIN] Parallel operations completed in ${parallelDuration.inMilliseconds}ms');

      final GoogleSignInAuthentication googleAuth = parallelResults[0] as GoogleSignInAuthentication;
      debugPrint('🔑 [GOOGLE_SIGNIN] Authentication tokens retrieved - AccessToken: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}, IdToken: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ [GOOGLE_SIGNIN] Failed to retrieve authentication tokens from Google');
        throw 'Failed to retrieve authentication tokens from Google';
      }

      // Step 3: Create Firebase credential
      debugPrint('🔧 [GOOGLE_SIGNIN] Creating Firebase credential...');
      final credentialStart = DateTime.now();
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final credentialDuration = DateTime.now().difference(credentialStart);
      debugPrint('✅ [GOOGLE_SIGNIN] Firebase credential created in ${credentialDuration.inMilliseconds}ms');

      // Step 4: Firebase authentication with optimized timeout
      debugPrint('🔐 [GOOGLE_SIGNIN] Authenticating with Firebase...');
      final firebaseStart = DateTime.now();
      final UserCredential userCredential = await _signInWithRetry(credential);
      final firebaseDuration = DateTime.now().difference(firebaseStart);

      debugPrint('✅ [GOOGLE_SIGNIN] Firebase authentication successful in ${firebaseDuration.inMilliseconds}ms for user: ${userCredential.user?.displayName} (UID: ${userCredential.user?.uid})');

      // Step 5: Minimal user data creation (fast)
      debugPrint('👤 [GOOGLE_SIGNIN] Creating minimal user record...');
      final userCreationStart = DateTime.now();
      await _createOrUpdateUserMinimal(userCredential.user!);
      final userCreationDuration = DateTime.now().difference(userCreationStart);
      debugPrint('✅ [GOOGLE_SIGNIN] Minimal user record created in ${userCreationDuration.inMilliseconds}ms');

      // Step 6: Start background sync for heavy operations
      debugPrint('🔄 [GOOGLE_SIGNIN] Starting background synchronization...');
      final backgroundStart = DateTime.now();
      _performBackgroundSetup(userCredential.user!);
      final backgroundSetupDuration = DateTime.now().difference(backgroundStart);
      debugPrint('✅ [GOOGLE_SIGNIN] Background setup initiated in ${backgroundSetupDuration.inMilliseconds}ms');

      final totalDuration = DateTime.now().difference(startTime);
      stopPerformanceTimer('google_signin_optimized');
      debugPrint('🎉 [GOOGLE_SIGNIN] Optimized Google Sign-In completed successfully in ${totalDuration.inSeconds}s');
      debugPrint('📊 [GOOGLE_SIGNIN] Performance breakdown:');
      debugPrint('   - Connectivity check: ${connectivityDuration.inMilliseconds}ms');
      debugPrint('   - Account selection: ${signInDuration?.inSeconds ?? 0}s');
      debugPrint('   - Parallel operations: ${parallelDuration.inMilliseconds}ms');
      debugPrint('   - Firebase auth: ${firebaseDuration.inMilliseconds}ms');
      debugPrint('   - User creation: ${userCreationDuration.inMilliseconds}ms');
      debugPrint('   - Background setup: ${backgroundSetupDuration.inMilliseconds}ms');

      return userCredential;
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      stopPerformanceTimer('google_signin_optimized');

      debugPrint('❌ [GOOGLE_SIGNIN] Google Sign-In failed after ${totalDuration.inSeconds}s');
      debugPrint('❌ [GOOGLE_SIGNIN] Error details: ${e.toString()}');
      debugPrint('❌ [GOOGLE_SIGNIN] Error type: ${e.runtimeType}');

      // Handle the special case where auth succeeded but timed out
      if (e.toString() == 'AUTH_SUCCESS_BUT_TIMEOUT') {
        debugPrint('✅ [GOOGLE_SIGNIN] Handling successful authentication that timed out');

        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          debugPrint('✅ [GOOGLE_SIGNIN] Proceeding with authenticated user: ${currentUser.displayName} (UID: ${currentUser.uid})');

          // Minimal user data for successful auth
          debugPrint('👤 [GOOGLE_SIGNIN] Creating minimal user record for timeout recovery...');
          final recoveryStart = DateTime.now();
          await _createOrUpdateUserMinimal(currentUser);
          final recoveryDuration = DateTime.now().difference(recoveryStart);
          debugPrint('✅ [GOOGLE_SIGNIN] Recovery user record created in ${recoveryDuration.inMilliseconds}ms');

          // Background setup
          _performBackgroundSetup(currentUser);
          debugPrint('✅ [GOOGLE_SIGNIN] Background setup initiated for timeout recovery');

          debugPrint('🎉 [GOOGLE_SIGNIN] Google Sign-In completed successfully despite timeout');
          return null; // Return null to indicate success but no UserCredential
        } else {
          debugPrint('❌ [GOOGLE_SIGNIN] Timeout recovery failed - no current user found');
        }
      }

      // Categorize and provide more specific error messages
      String errorCategory = 'unknown';
      String userMessage = 'Sign-in failed';

      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorCategory = 'network';
        userMessage = 'Network error during sign-in. Please check your internet connection and try again.';
        debugPrint('🌐 [GOOGLE_SIGNIN] Network-related error detected');
      } else if (e.toString().contains('cancelled') || e.toString().contains('CANCELLED')) {
        errorCategory = 'user_cancelled';
        userMessage = 'Sign-in was cancelled.';
        debugPrint('🚫 [GOOGLE_SIGNIN] User cancelled the sign-in process');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('SIGN_IN_FAILED')) {
        errorCategory = 'auth_failed';
        userMessage = 'Authentication failed. Please try again.';
        debugPrint('🔐 [GOOGLE_SIGNIN] Authentication failure detected');
      } else if (e.toString().contains('account') || e.toString().contains('ACCOUNT')) {
        errorCategory = 'account_issue';
        userMessage = 'Account selection failed. Please try selecting a different account.';
        debugPrint('👤 [GOOGLE_SIGNIN] Account-related error detected');
      } else {
        errorCategory = 'unknown';
        userMessage = 'Sign-in failed: ${e.toString()}';
        debugPrint('❓ [GOOGLE_SIGNIN] Unknown error category');
      }

      debugPrint('📊 [GOOGLE_SIGNIN] Error summary:');
      debugPrint('   - Category: $errorCategory');
      debugPrint('   - Duration: ${totalDuration.inSeconds}s');
      debugPrint('   - User message: $userMessage');

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
        debugPrint('👤 Creating new user record...');
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
          xpPoints: 0,
          premium: false,
          createdAt: DateTime.now(),
          photoURL: firebaseUser.photoURL,
        );

        // Use set with merge to ensure atomic operation
        await userDoc.set(userModel.toJson(), SetOptions(merge: true));

        // Create default quota for new user (optimized)
        await _createDefaultUserQuotaOptimized(firebaseUser.uid);

        debugPrint('✅ New user created successfully');
      } else {
        debugPrint('🔄 Updating existing user record...');
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
          debugPrint('✅ User data updated successfully');
        } else {
          debugPrint('ℹ️ No user data changes needed');
        }
      }

      stopPerformanceTimer('user_data_setup');
    } catch (e) {
      stopPerformanceTimer('user_data_setup');
      debugPrint('❌ Error in createOrUpdateUser: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign out - Enhanced to properly clear Google Sign-In cache and temporary data
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Starting enhanced sign-out process...');

      // Step 1: Sign out from Firebase Auth
      await _firebaseAuth.signOut();
      debugPrint('✅ Firebase Auth sign-out completed');

      // Step 2: Sign out from Google (not disconnect - this preserves account selection)
      // Using signOut() instead of disconnect() to avoid token retrieval issues
      await _googleSignIn.signOut();
      debugPrint('✅ Google account signed out');

      // Note: We keep the stored Google account info for smart login UX convenience
      // This allows users to quickly sign back in with the same account
      debugPrint('ℹ️ Stored Google account info preserved for quick re-login');

      // Step 3: Clear session-specific cache and temporary files (but keep user preferences)
      await _clearLogoutCache();
      debugPrint('✅ Session cache cleared');

      // Step 4: Clear GetX controllers to reset app state
      await _clearAllControllers();
      debugPrint('✅ App controllers reset');

      debugPrint('🚪 Enhanced sign-out completed successfully');
    } catch (e) {
      debugPrint('⚠️ Error during enhanced sign-out: $e');
      // Fallback to basic sign-out if enhanced fails
      try {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        // Keep stored account info in fallback for UX convenience
        await _clearLogoutCache();
        await _clearAllControllers();
        debugPrint('⚠️ Fallback sign-out completed');
      } catch (fallbackError) {
        debugPrint('❌ Fallback sign-out also failed: $fallbackError');
        // At minimum, try basic cleanup
        try {
          await _clearAllControllers();
        } catch (controllerError) {
          debugPrint('❌ Controller cleanup also failed: $controllerError');
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
      debugPrint('❌ Could not get storage info: $e');
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
      debugPrint('🧹 Manual storage cleanup initiated...');

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
        debugPrint('✅ Firebase cache cleared during manual cleanup');
      } catch (e) {
        debugPrint('Warning: Could not clear Firebase cache: $e');
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

      debugPrint('✅ Manual cleanup completed:');
      debugPrint(
        '   Initial size: ${(result['initialSize'] as int) / 1024 / 1024} MB',
      );
      debugPrint(
        '   Final size: ${(result['finalSize'] as int) / 1024 / 1024} MB',
      );
      debugPrint(
        '   Cleaned: ${(result['cleanedSize'] as int) / 1024 / 1024} MB',
      );

      return result;
    } catch (e) {
      debugPrint('❌ Manual storage cleanup failed: $e');
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
      debugPrint('🔍 Analyzing app storage on startup...');

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
        debugPrint(
          '⚠️ Excessive storage detected (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB), cleaning up...',
        );
        await _cleanupExcessiveStorage();
      } else {
        debugPrint(
          '✅ Storage usage normal (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
      }
    } catch (e) {
      debugPrint('ℹ️ Could not analyze storage: $e');
    }
  }

  // Clean up excessive storage
  Future<void> _cleanupExcessiveStorage() async {
    try {
      debugPrint('🧹 Cleaning up excessive storage...');

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
                debugPrint(
                  '🗑️ Deleted old cache file: ${file.path} (${(size / 1024).round()} KB)',
                );
              }
            } catch (e) {
              debugPrint(
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
          debugPrint(
            '🔥 Firebase cache too large (${(firebaseSize / 1024 / 1024).toStringAsFixed(2)} MB), clearing...',
          );
          try {
            await _firestore.clearPersistence();
            cleanedSize += firebaseSize;
            debugPrint('✅ Firebase cache cleared');
          } catch (e) {
            debugPrint('Warning: Could not clear Firebase cache: $e');
          }
        }
      }

      if (cleanedSize > 0) {
        debugPrint(
          '✅ Cleaned up ${(cleanedSize / 1024 / 1024).toStringAsFixed(2)} MB, deleted $deletedFiles files',
        );
      } else {
        debugPrint('ℹ️ No excessive storage found to clean');
      }
    } catch (e) {
      debugPrint('Warning: Could not cleanup excessive storage: $e');
    }
  }

  // Create default quota for new user
  Future<void> _createDefaultUserQuota(String userId) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      final quotaData = {
        'userId': userId,
        'dailyLimit': 20,
        'messagesSent': 0,
        'extraQuota': 0,
        'lastReset': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await quotaRef.set(quotaData);
      debugPrint('✅ Created default quota for new user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to create default quota for user $userId: $e');
      // Don't throw here as user creation should succeed even if quota creation fails
    }
  }

  // Create default quota for new user - Optimized version
  Future<void> _createDefaultUserQuotaOptimized(String userId) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      final now = DateTime.now();

      // Use server timestamp for better consistency
      final quotaData = {
        'userId': userId,
        'dailyLimit': 20,
        'messagesSent': 0,
        'extraQuota': 0,
        'lastReset': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Use set with merge for atomic operation
      await quotaRef.set(quotaData, SetOptions(merge: true));
      debugPrint('✅ Created optimized default quota for new user: $userId');
    } catch (e) {
      debugPrint(
        '❌ Failed to create optimized default quota for user $userId: $e',
      );
      // Fallback to original method
      await _createDefaultUserQuota(userId);
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
    debugPrint('🗑️ Starting account deletion for user: $userId');

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
      debugPrint('🔐 Deleting Firebase Auth account...');
      await user.delete();
      debugPrint('✅ Firebase Auth account deleted');

      // Force sign out from Google (if applicable)
      await _googleSignIn.signOut();

      // Clear all local app data and cache AFTER auth deletion
      await _clearAppCache();

      // Clear all GetX controllers
      await _clearAllControllers();

      debugPrint('✅ Account deletion completed successfully');
    } catch (e) {
      debugPrint('❌ Account deletion failed: $e');

      // If Firestore deletion fails, still try to delete from Auth
      try {
        await user.delete();
        await _googleSignIn.signOut();
        await _clearAppCache();
        await _clearAllControllers();
        debugPrint('⚠️ Partial deletion completed - some data may remain');
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
        debugPrint('📦 Committed batch $currentBatchIndex');
      }
    }

    try {
      // 1. Delete user document and subcollections
      debugPrint('📄 Deleting user document and subcollections...');
      await _deleteUserDocumentChunked(userId, getCurrentBatch, commitIfNeeded);

      // 2. Delete conversations and messages (this can be large)
      debugPrint('💬 Deleting conversations and messages...');
      await _deleteConversationsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 3. Delete rewards
      debugPrint('🏆 Deleting rewards...');
      await _deleteRewardsChunked(userId, getCurrentBatch, commitIfNeeded);

      // 4. Delete XP transactions
      debugPrint('⭐ Deleting XP transactions...');
      await _deleteXpTransactionsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 5. If user is a candidate, delete candidate data
      if (isCandidate) {
        debugPrint('👥 Deleting candidate data...');
        await _deleteCandidateDataChunked(
          userId,
          getCurrentBatch,
          commitIfNeeded,
        );
      }

      // 6. Delete chat rooms created by the user
      debugPrint('🏠 Deleting user chat rooms...');
      await _deleteUserChatRoomsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 7. Delete user quota data
      debugPrint('📊 Deleting user quota...');
      await _deleteUserQuota(userId, getCurrentBatch());

      // 8. Delete reported messages by the user
      debugPrint('🚨 Deleting reported messages...');
      await _deleteUserReportedMessagesChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 9. Delete user subscriptions
      debugPrint('💳 Deleting user subscriptions...');
      await _deleteUserSubscriptionsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 10. Delete user devices
      debugPrint('📱 Deleting user devices...');
      await _deleteUserDevicesChunked(userId, getCurrentBatch, commitIfNeeded);

      // Commit all remaining batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        await batches[i].commit();
        debugPrint('📦 Committed final batch ${i + 1}');
      }

      debugPrint('✅ All user data deleted successfully');
    } catch (e) {
      debugPrint('❌ Error during chunked deletion: $e');
      // Try to commit any pending batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        try {
          await batches[i].commit();
        } catch (batchError) {
          debugPrint('❌ Failed to commit batch ${i + 1}: $batchError');
        }
      }
      rethrow;
    }
  }

  // Clear all app cache and local storage
  Future<void> _clearAppCache() async {
    try {
      debugPrint('🧹 Starting comprehensive cache cleanup...');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ SharedPreferences cleared');

      // Clear Firebase local cache (handle errors gracefully)
      try {
        await _firestore.clearPersistence();
        debugPrint('✅ Firebase local cache cleared');
      } catch (cacheError) {
        // Handle specific cache clearing errors gracefully
        final errorMessage = cacheError.toString();
        if (errorMessage.contains('failed-precondition') ||
            errorMessage.contains('not in a state') ||
            errorMessage.contains('Operation was rejected')) {
          debugPrint(
            'ℹ️ Firebase cache clearing skipped (normal after account deletion)',
          );
        } else {
          debugPrint('Warning: Firebase cache clearing failed: $cacheError');
        }
      }

      // Clear any cached data in Firebase Auth
      await _firebaseAuth.signOut();
      debugPrint('✅ Firebase Auth cache cleared');

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

      debugPrint('✅ Comprehensive cache cleanup completed');
    } catch (e) {
      debugPrint('Warning: Failed to clear some cache: $e');
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
      if (Get.isRegistered<AdMobService>()) {
        Get.delete<AdMobService>(force: true);
      }

      debugPrint(
        '✅ Controllers cleared (LoginController preserved for login screen)',
      );
    } catch (e) {
      debugPrint('Warning: Failed to clear some controllers: $e');
    }
  }

  // Clear cache for logout (lighter version that preserves user preferences)
  Future<void> _clearLogoutCache() async {
    try {
      debugPrint('🧹 Starting logout cache cleanup...');

      // Log initial storage state
      await _logStorageState('BEFORE logout');

      // Clear Firebase local cache (but keep user data)
      try {
        await _firestore.clearPersistence();
        debugPrint('✅ Firebase local cache cleared');
      } catch (cacheError) {
        // Handle specific cache clearing errors gracefully
        final errorMessage = cacheError.toString();
        if (errorMessage.contains('failed-precondition') ||
            errorMessage.contains('not in a state') ||
            errorMessage.contains('Operation was rejected')) {
          debugPrint(
            'ℹ️ Firebase cache clearing skipped (normal after sign-out)',
          );
        } else {
          debugPrint('Warning: Firebase cache clearing failed: $cacheError');
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
        debugPrint('📁 Checking cache directory: ${cacheDir.path}');
        if (await cacheDir.exists()) {
          final files = cacheDir.listSync(recursive: true);
          debugPrint('📊 Found ${files.length} items in cache directory');

          int deletedFiles = 0;
          int deletedDirs = 0;

          for (final file in files) {
            if (file is File) {
              try {
                final size = await file.length();
                await file.delete();
                deletedFiles++;
                debugPrint(
                  '🗑️ Deleted cache file: ${file.path} ($size bytes)',
                );
              } catch (e) {
                debugPrint(
                  'Warning: Failed to delete cache file ${file.path}: $e',
                );
              }
            } else if (file is Directory) {
              try {
                await file.delete(recursive: true);
                deletedDirs++;
                debugPrint('🗑️ Deleted cache directory: ${file.path}');
              } catch (e) {
                debugPrint(
                  'Warning: Failed to delete cache directory ${file.path}: $e',
                );
              }
            }
          }
          debugPrint(
            '✅ Cache directory cleared - deleted $deletedFiles files and $deletedDirs directories',
          );
        } else {
          debugPrint('ℹ️ Cache directory does not exist');
        }
      } catch (e) {
        debugPrint('Warning: Failed to clear cache directory: $e');
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
              debugPrint('✅ Cleared temp directory: $dirName');
            }
          } catch (e) {
            debugPrint('Warning: Failed to clear $dirName: $e');
          }
        }
      } catch (e) {
        debugPrint('Warning: Failed to clear app temp directories: $e');
      }

      debugPrint('✅ Logout cache cleanup completed');

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

        debugPrint('📊 Storage cleanup summary:');
        debugPrint('   Cache directory: $cacheItems items remaining');
        debugPrint('   App temp dirs: $appTempItems items remaining');
        debugPrint('   ✅ Session data cleared successfully');
      } catch (e) {
        debugPrint('ℹ️ Could not generate cleanup summary: $e');
      }
    } catch (e) {
      debugPrint('Warning: Failed to clear some logout cache: $e');
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

      debugPrint('📊 Storage state $context:');
      debugPrint(
        '   Cache directory: $cacheFiles files (${(cacheSize / 1024).round()} KB)',
      );
      debugPrint('   App temp files: $appTempFiles items');
      debugPrint(
        '   App support: $appSupportFiles files (${(appSupportSize / 1024).round()} KB)',
      );
      debugPrint(
        '   📈 Total estimated: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Detailed breakdown if size is significant
      if (totalSize > 10 * 1024 * 1024) {
        // > 10MB
        await _analyzeLargeStorage(cacheDir, appDir, appSupportDir);
      }
    } catch (e) {
      debugPrint('ℹ️ Could not log storage state: $e');
    }
  }

  // Analyze what's taking up large amounts of storage
  Future<void> _analyzeLargeStorage(
    Directory cacheDir,
    Directory appDir,
    Directory appSupportDir,
  ) async {
    try {
      debugPrint('🔍 Analyzing large storage usage...');

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
              debugPrint(
                '   📁 Large cache dir: ${item.path} (${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB, ${files.length} files)',
              );
            }
          } else if (item is File) {
            try {
              final size = await item.length();
              if (size > 1024 * 1024) {
                // > 1MB
                debugPrint(
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
              debugPrint(
                '   📁 Large support dir: ${item.path} (${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB, ${files.length} files)',
              );
            }
          } else if (item is File) {
            try {
              final size = await item.length();
              if (size > 1024 * 1024) {
                // > 1MB
                debugPrint(
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
        debugPrint(
          '   🔥 Firebase cache: ${firebaseFiles.length} files (${(firebaseSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
      }
    } catch (e) {
      debugPrint('ℹ️ Could not analyze large storage: $e');
    }
  }

  // Clear image cache
  Future<void> _clearImageCache() async {
    try {
      // Clear Flutter's image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('✅ Flutter image cache cleared');

      // Note: If using cached_network_image package, you would also clear its cache:
      // await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('Warning: Failed to clear image cache: $e');
    }
  }

  // Clear HTTP cache
  Future<void> _clearHttpCache() async {
    try {
      // Note: Flutter doesn't have a built-in HTTP cache, but if you're using
      // packages like dio with cache interceptors, you would clear them here
      debugPrint(
        'ℹ️ HTTP cache clearing not implemented (no HTTP caching detected)',
      );
    } catch (e) {
      debugPrint('Warning: Failed to clear HTTP cache: $e');
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
            debugPrint('Warning: Failed to delete temp item ${file.path}: $e');
          }
        }

        if (deletedCount > 0) {
          debugPrint('✅ Cleared $deletedCount temp files/directories');
        } else {
          debugPrint('ℹ️ No old temp files to clear');
        }
      }
    } catch (e) {
      debugPrint('Warning: Failed to clear temp files: $e');
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
          debugPrint('✅ File upload temp photos cleared');
        }
      } catch (e) {
        debugPrint('Warning: Failed to clear temp photos: $e');
      }

      // Clear media temp directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        final mediaTempDir = Directory('${directory.path}/media_temp');
        if (await mediaTempDir.exists()) {
          await mediaTempDir.delete(recursive: true);
          debugPrint('✅ File upload media temp files cleared');
        }
      } catch (e) {
        debugPrint('Warning: Failed to clear media temp files: $e');
      }
    } catch (e) {
      debugPrint('Warning: Failed to clear file upload temp files: $e');
    }
  }

  // Clear all app directories and cache
  Future<void> _clearAllAppDirectories() async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      debugPrint('📁 Clearing app directory: ${appDir.path}');

      // Clear all subdirectories except those we want to keep
      final subDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];
      for (final subDirName in subDirs) {
        try {
          final subDir = Directory('${appDir.path}/$subDirName');
          if (await subDir.exists()) {
            await subDir.delete(recursive: true);
            debugPrint('✅ Cleared directory: $subDirName');
          }
        } catch (e) {
          debugPrint('Warning: Failed to clear $subDirName: $e');
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
                debugPrint(
                  'Warning: Failed to delete cache file ${file.path}: $e',
                );
              }
            }
          }
          debugPrint('✅ Cache directory cleared');
        }
      } catch (e) {
        debugPrint('Warning: Failed to clear cache directory: $e');
      }

      // Note: External storage cache clearing removed to avoid import complexity
      // In production, you might want to add this back with proper platform-specific imports
    } catch (e) {
      debugPrint('Warning: Failed to clear app directories: $e');
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

  Future<void> _deleteXpTransactionsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    final xpTransactionsSnapshot = await _firestore
        .collection('xp_transactions')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in xpTransactionsSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }
  }

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
        final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

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

              debugPrint(
                '✅ Deleted candidate data from: /districts/${districtDoc.id}/bodies/${bodyDoc.id}/wards/${wardDoc.id}/candidates/${candidateDoc.id}',
              );
              return; // Found and deleted, no need to continue searching
            }
          }
        }
      }

      debugPrint('⚠️ No candidate data found for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting candidate data: $e');
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

        debugPrint(
          '✅ Deleted chat room: $roomId with ${messagesSnapshot.docs.length} messages and ${pollsSnapshot.docs.length} polls',
        );
      }

      debugPrint(
        '✅ Deleted ${chatRoomsSnapshot.docs.length} chat rooms created by user: $userId',
      );
    } catch (e) {
      debugPrint('❌ Error deleting user chat rooms: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserQuota(String userId, WriteBatch batch) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      batch.delete(quotaRef);
      debugPrint('✅ Deleted user quota for: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user quota: $e');
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

      debugPrint(
        '✅ Deleted ${reportsSnapshot.docs.length} reported messages by user: $userId',
      );
    } catch (e) {
      debugPrint('❌ Error deleting user reported messages: $e');
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

      debugPrint(
        '✅ Deleted ${subscriptionsSnapshot.docs.length} subscriptions for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ Error deleting user subscriptions: $e');
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

      debugPrint(
        '✅ Deleted ${devicesSnapshot.docs.length} devices for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ Error deleting user devices: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserMediaFiles(String userId) async {
    try {
      // Note: Firebase Storage deletion is more complex and might require
      // listing all files in the user's media folder and deleting them individually
      // For now, we'll log this as a reminder that media files should be cleaned up
      debugPrint(
        '📝 Reminder: Media files in Firebase Storage for user $userId should be manually cleaned up',
      );
      debugPrint('   Location: chat_media/ and other user-uploaded files');

      // In a production app, you would:
      // 1. List all files in user's media folders
      // 2. Delete each file individually
      // 3. This can be expensive, so consider doing it asynchronously
    } catch (e) {
      debugPrint('❌ Error deleting user media files: $e');
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

  // Enhanced Firebase authentication with retry logic
  Future<UserCredential> _signInWithRetry(OAuthCredential credential) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final result = await _firebaseAuth.signInWithCredential(credential)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                // Check if authentication actually succeeded despite the timeout
                final currentUser = _firebaseAuth.currentUser;
                if (currentUser != null) {
                  debugPrint('✅ Authentication succeeded despite timeout');
                  throw 'AUTH_SUCCESS_BUT_TIMEOUT';
                } else {
                  throw Exception('Firebase authentication timed out');
                }
              },
            );
        return result;
      } catch (e) {
        if (e.toString() == 'AUTH_SUCCESS_BUT_TIMEOUT') {
          // Authentication succeeded despite timeout
          throw e;
        }

        retryCount++;
        if (retryCount < maxRetries && _isRetryableError(e)) {
          debugPrint('🔄 Firebase auth retry $retryCount/$maxRetries');
          final delay = Duration(seconds: retryCount * 2); // Exponential backoff
          await Future.delayed(delay);
          continue;
        } else {
          rethrow;
        }
      }
    }

    throw Exception('Firebase authentication failed after $maxRetries retries');
  }

  // Prepare user data locally (fast operation)
  Future<Map<String, dynamic>> _prepareUserDataLocally(GoogleSignInAccount googleUser) async {
    debugPrint('📋 Preparing user data locally...');

    final userData = {
      'name': googleUser.displayName ?? 'User',
      'email': googleUser.email,
      'photoURL': googleUser.photoUrl,
      'preparedAt': DateTime.now().toIso8601String(),
    };

    // Cache locally for immediate access
    await _cacheService.cacheTempUserData(userData);

    debugPrint('✅ User data prepared and cached locally');
    return userData;
  }

  // Create minimal user record (fast operation)
  Future<void> _createOrUpdateUserMinimal(User firebaseUser) async {
    startPerformanceTimer('minimal_user_creation');

    try {
      debugPrint('👤 Creating minimal user record...');

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

      debugPrint('✅ Minimal user record created');
    } catch (e) {
      debugPrint('❌ Error creating minimal user record: $e');
      rethrow;
    } finally {
      stopPerformanceTimer('minimal_user_creation');
    }
  }

  // Perform background setup operations (non-blocking)
  void _performBackgroundSetup(User user) {
    debugPrint('🔄 Starting background setup...');

    // Use the background sync manager for comprehensive sync
    _syncManager.performFullBackgroundSync(user);
  }



  // Store last used Google account info for smart login UX
  Future<void> _storeLastGoogleAccount(GoogleSignInAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountData = {
        'email': account.email,
        'displayName': account.displayName ?? 'User',
        'photoUrl': account.photoUrl,
        'id': account.id,
        'lastLogin': DateTime.now().toIso8601String(),
      };

      // Properly encode as JSON string
      final accountJson = jsonEncode(accountData);
      await prefs.setString('last_google_account', accountJson);
      debugPrint('✅ Stored last Google account: ${account.email}');
    } catch (e) {
      debugPrint('⚠️ Error storing last Google account: $e');
    }
  }

  // Get last used Google account info
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountData = prefs.getString('last_google_account');

      if (accountData == null) {
        debugPrint('ℹ️ No stored Google account found');
        return null;
      }

      debugPrint('📋 Found stored Google account data');

      // Parse the stored JSON string
      final accountMap = jsonDecode(accountData) as Map<String, dynamic>;

      debugPrint('✅ Successfully parsed stored account: ${accountMap['displayName']} (${accountMap['email']})');

      return accountMap;
    } catch (e) {
      debugPrint('⚠️ Error retrieving last Google account: $e');
      // Clear corrupted data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_google_account');
        debugPrint('🧹 Cleared corrupted account data');
      } catch (clearError) {
        debugPrint('⚠️ Error clearing corrupted data: $clearError');
      }
      return null;
    }
  }

  // Clear stored Google account info (on logout)
  Future<void> clearLastGoogleAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_google_account');
      debugPrint('✅ Cleared last Google account info');
    } catch (e) {
      debugPrint('⚠️ Error clearing last Google account: $e');
    }
  }
}
