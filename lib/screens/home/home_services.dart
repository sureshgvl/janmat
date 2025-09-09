import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/candidate_model.dart';
import '../../repositories/candidate_repository.dart';

class HomeServices {
  final CandidateRepository _candidateRepository = CandidateRepository();

  Future<Map<String, dynamic>> getUserData(String? uid) async {
    if (uid == null) return {'user': null, 'candidate': null};

    // Add a small delay to ensure any recent updates are reflected
    await Future.delayed(const Duration(milliseconds: 500));

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    UserModel? userModel;
    Candidate? candidateModel;

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      userModel = UserModel.fromJson(userData);

      // If user is a candidate, fetch candidate data from hierarchical structure
      if (userModel.role == 'candidate') {
        try {
          candidateModel = await _candidateRepository.getCandidateData(uid);
        debugPrint('🏛️ Home Screen: Fetched candidate data for ${userModel.name}');
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