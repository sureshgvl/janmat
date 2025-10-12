import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/district_spotlight_model.dart';
import '../utils/app_logger.dart';
import '../widgets/district_spotlight_overlay.dart';
import '../services/local_database_service.dart';

class DistrictSpotlightService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Global flag to track if spotlight has been dismissed for this app session
  static bool _isSpotlightDismissedForSession = false;

  // Getter for dismissal state
  static bool get isSpotlightDismissedForSession => _isSpotlightDismissedForSession;

  // Method to dismiss spotlight for the session
  static void dismissSpotlightForSession() {
    _isSpotlightDismissedForSession = true;
    AppLogger.common('🚫 District spotlight dismissed for this app session');
  }

  // Method to reset dismissal state (for testing or new sessions)
  static void resetSpotlightDismissal() {
    _isSpotlightDismissedForSession = false;
    AppLogger.common('🔄 District spotlight dismissal reset');
  }

  // Global method to show district spotlight anywhere in the app
  static Future<void> showDistrictSpotlightIfAvailable(String stateId, String districtId) async {
    // Check if already dismissed for this session
    if (_isSpotlightDismissedForSession) {
      AppLogger.common('ℹ️ District spotlight already dismissed for this session');
      return;
    }

    // Check if dialog is already open
    if (Get.isDialogOpen ?? false) {
      AppLogger.common('ℹ️ Dialog already open, skipping spotlight');
      return;
    }

    try {
      AppLogger.common('🔍 Checking spotlight for $stateId/$districtId globally');
      final spotlight = await getActiveDistrictSpotlight(stateId, districtId);

      if (spotlight != null) {
        AppLogger.common('✅ Found active spotlight for $districtId: ${spotlight.fullImage}');
        debugPrint('🎯 Spotlight object: partyId=${spotlight.partyId}, fullImage=${spotlight.fullImage}, isActive=${spotlight.isActive}');

        // Check if image URL is valid
        if (spotlight.fullImage == null || spotlight.fullImage.isEmpty) {
          AppLogger.common('⚠️ District spotlight has empty/null fullImage URL');
          return;
        }

        // Check if we need to download the image (partyId comparison)
        final localDb = LocalDatabaseService();
        final cachedSpotlight = await localDb.getDistrictSpotlight(stateId, districtId);
        final needsImageDownload = cachedSpotlight == null ||
            cachedSpotlight.partyId != spotlight.partyId;

        if (needsImageDownload) {
          AppLogger.districtSpotlight('📥 Downloading/preloading spotlight image for party: ${spotlight.partyId}');
          // Preload the image before showing the dialog
          await _preloadSpotlightImage(spotlight.fullImage);
        } else {
          AppLogger.districtSpotlight('✅ Using cached image for party: ${spotlight.partyId}');
          // Still preload to ensure image is ready, but it should be fast
          await _preloadSpotlightImage(spotlight.fullImage);
        }

        // Show the spotlight as a global dialog
        AppLogger.common('🎯 Showing district spotlight dialog globally');
        Get.dialog(
          DistrictSpotlightOverlay(
            spotlight: spotlight,
            onClose: () {
              Get.back(); // Close the dialog
              dismissSpotlightForSession(); // Mark as dismissed for session
            },
          ),
          barrierDismissible: false, // Prevent accidental dismissal
          useSafeArea: false, // Full screen overlay
        );
      } else {
        AppLogger.common('ℹ️ No active spotlight found for $districtId');
      }
    } catch (e) {
      AppLogger.common('❌ Error showing district spotlight globally: $e');
    }
  }

  // Preload spotlight image before showing dialog
  static Future<void> _preloadSpotlightImage(String imageUrl) async {
    try {
      AppLogger.common('📥 Preloading district spotlight image: $imageUrl');

      final image = NetworkImage(imageUrl);
      final completer = Completer<void>();

      final listener = ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          completer.complete();
          AppLogger.common('✅ District spotlight image preloaded successfully');
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          completer.completeError(exception);
          AppLogger.common('❌ Failed to preload district spotlight image: $exception');
        },
      );

      image.resolve(const ImageConfiguration()).addListener(listener);

      // Wait for image to load with timeout
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.common('⏰ District spotlight image preload timeout');
          throw TimeoutException('Image preload timeout');
        },
      );
    } catch (e) {
      AppLogger.common('❌ Error preloading district spotlight image: $e');
      // Continue anyway - the Image.network widget will handle loading states
    }
  }

  /// Get district spotlight for a specific district
  static Future<DistrictSpotlight?> getDistrictSpotlight(String stateId, String districtId) async {
    try {
      AppLogger.common('🔥 FIRESTORE: Fetching district spotlight for $stateId/$districtId');

      final doc = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('district_spotlight')
          .doc('spotlight')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;

        // Debug logging
        AppLogger.common('📊 FIRESTORE: Raw spotlight data: $data');
        AppLogger.common('📊 FIRESTORE: fullImage field: ${data['fullImage']}');
        AppLogger.common('📊 FIRESTORE: partyId field: ${data['partyId']}');
        AppLogger.common('📊 FIRESTORE: isActive field: ${data['isActive']}');

        final spotlight = DistrictSpotlight.fromJson(data);
        AppLogger.common('✅ FIRESTORE: Found district spotlight for $districtId');
        AppLogger.common('✅ FIRESTORE: Spotlight fullImage: ${spotlight.fullImage}');
        return spotlight;
      }

      AppLogger.common('ℹ️ FIRESTORE: No district spotlight found for $districtId');
      return null;
    } catch (e) {
      AppLogger.common('❌ FIRESTORE ERROR: Failed to fetch district spotlight: $e');
      return null;
    }
  }

  /// Get active district spotlight for a specific district with caching
  static Future<DistrictSpotlight?> getActiveDistrictSpotlight(String stateId, String districtId) async {
    try {
      AppLogger.common('🔍 Checking cached district spotlight for $stateId/$districtId');

      // First check local database for cached spotlight
      final localDb = LocalDatabaseService();
      final cachedSpotlight = await localDb.getDistrictSpotlight(stateId, districtId);

      if (cachedSpotlight != null && cachedSpotlight.isActive) {
        AppLogger.common('✅ Found cached active spotlight for $districtId');
        // Use persistent cache - no expiry check needed
        AppLogger.districtSpotlight('📦 Using persistent cached spotlight for $districtId');
        return cachedSpotlight;
      }

      // Fetch from Firestore
      AppLogger.common('🔥 Fetching fresh district spotlight from Firestore for $stateId/$districtId');
      final freshSpotlight = await getDistrictSpotlight(stateId, districtId);

      if (freshSpotlight != null && freshSpotlight.isActive) {
        // Compare partyId to decide if we need to download image
        final needsImageDownload = cachedSpotlight == null ||
            cachedSpotlight.partyId != freshSpotlight.partyId;

        if (needsImageDownload) {
          AppLogger.districtSpotlight('📥 Party ID changed (${cachedSpotlight?.partyId} -> ${freshSpotlight.partyId}), will download image');
        } else {
          AppLogger.districtSpotlight('✅ Party ID same (${freshSpotlight.partyId}), no image download needed');
        }

        // Cache the fresh data
        await localDb.insertDistrictSpotlight(freshSpotlight, stateId, districtId);
        AppLogger.districtSpotlight('💾 Cached fresh spotlight data for $stateId/$districtId');

        return freshSpotlight;
      } else {
        AppLogger.common('ℹ️ No active spotlight found in Firestore for $districtId');
        return null;
      }
    } catch (e) {
      AppLogger.common('❌ ERROR: Failed to get active district spotlight: $e');
      return null;
    }
  }

  /// Get all district spotlights (for admin purposes)
  static Future<List<Map<String, dynamic>>> getAllDistrictSpotlights() async {
    try {
      AppLogger.common('🔥 FIRESTORE: Fetching all district spotlights');

      final statesSnapshot = await _firestore.collection('states').get();

      List<Map<String, dynamic>> spotlights = [];

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          final spotlightDoc = await districtDoc.reference
              .collection('district_spotlight')
              .doc('spotlight')
              .get();

          if (spotlightDoc.exists) {
            final data = spotlightDoc.data()!;
            data['id'] = spotlightDoc.id;
            data['stateId'] = stateDoc.id;
            data['districtId'] = districtDoc.id;
            spotlights.add(data);
          }
        }
      }

      AppLogger.common('✅ FIRESTORE: Found ${spotlights.length} district spotlights');
      return spotlights;
    } catch (e) {
      AppLogger.common('❌ FIRESTORE ERROR: Failed to fetch all district spotlights: $e');
      return [];
    }
  }
}