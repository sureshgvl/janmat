import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/repositories/candidate_repository.dart';

class HomeServices {
  final CandidateRepository _candidateRepository = CandidateRepository();

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

      // If user is a candidate, fetch candidate data from hierarchical structure
      if (userModel.role == 'candidate') {
        try {
          candidateModel = await _candidateRepository.getCandidateData(uid);
          debugPrint(
            '🏛️ Home Screen: Fetched candidate data for ${userModel.name}',
          );
          debugPrint('   Party: ${candidateModel?.party ?? 'No party data'}');
          debugPrint('   Symbol path: ${candidateModel?.party ?? ''}');
        } catch (e) {
          debugPrint('❌ Error fetching candidate data: $e');
          // Continue without candidate data if there's an error
        }
      }
    }

    return {'user': userModel, 'candidate': candidateModel};
  }
}
