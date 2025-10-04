import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/controllers/candidate_data_controller.dart';

class HomeServices {

  Future<Map<String, dynamic>> getUserData(String? uid) async {
    // Check if user is authenticated before attempting to fetch data
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || uid == null) {
      debugPrint('ℹ️ User not authenticated, skipping data fetch');
      return {'user': null, 'candidate': null};
    }

    // Verify the requested uid matches the authenticated user
    if (currentUser.uid != uid) {
      debugPrint('⚠️ UID mismatch - requested: $uid, authenticated: ${currentUser.uid}');
      return {'user': null, 'candidate': null};
    }

    // Add a small delay to ensure any recent updates are reflected
    await Future.delayed(const Duration(milliseconds: 500));

    // Double-check authentication right before Firestore call (in case user logged out during delay)
    final currentUserCheck = FirebaseAuth.instance.currentUser;
    if (currentUserCheck == null || currentUserCheck.uid != uid) {
      debugPrint('🚫 User authentication lost during data fetch, aborting');
      return {'user': null, 'candidate': null};
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    UserModel? userModel;
    Candidate? candidateModel;

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      userModel = UserModel.fromJson(userData);

      // Get candidate data from CandidateDataController if available
      if (userModel.profileCompleted && userModel.role == 'candidate') {
        try {
          // Try to get candidate data from the controller if it's already loaded
          final candidateController = Get.find<CandidateDataController>();
          if (candidateController.candidateData.value != null) {
            candidateModel = candidateController.candidateData.value;
            debugPrint(
              '🏛️ Home Screen: Using cached candidate data for ${userModel.name}',
            );
          } else {
            debugPrint('⏭️ Candidate data not yet loaded in controller, will be loaded separately');
          }
        } catch (e) {
          debugPrint('⚠️ Could not get candidate data from controller: $e');
          // Continue without candidate data if there's an error
        }
      } else {
        debugPrint('⏭️ Skipping candidate data - profile not completed or user is not a candidate');
      }
    }

    return {'user': userModel, 'candidate': candidateModel};
  }
}

