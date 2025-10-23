import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/candidate_controller.dart';
import '../../../features/user/models/user_model.dart';
import '../widgets/candidate_card.dart';
import '../../../utils/app_logger.dart';

class MyAreaCandidatesScreen extends StatefulWidget {
  const MyAreaCandidatesScreen({super.key});

  @override
  State<MyAreaCandidatesScreen> createState() => _MyAreaCandidatesScreenState();
}

class _MyAreaCandidatesScreenState extends State<MyAreaCandidatesScreen> {
  final CandidateController candidateController =
      Get.find<CandidateController>();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndCandidates();
  }

  Future<void> _loadUserDataAndCandidates() async {
    if (currentUserId != null) {
      try {
        // Get user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (userDoc.exists) {
          currentUser = UserModel.fromJson(userDoc.data()!);

          // Load candidates from user's ward using new electionAreas structure
          final regularArea = currentUser!.electionAreas.isNotEmpty
              ? currentUser!.electionAreas.firstWhere(
                  (area) => area.type == ElectionType.regular,
                  orElse: () => currentUser!.electionAreas.first,
                )
              : null;

          if (regularArea != null) {
            await candidateController.fetchCandidatesByWard(
              currentUser!.districtId!,
              regularArea.bodyId,
              regularArea.wardId,
            );
          }

          // If current user is a candidate, add them to the list
          if (currentUser!.role == 'candidate') {
            await _addCurrentUserToCandidatesList();
          }
        }
      } catch (e) {
        AppLogger.candidateError('Error loading user data: $e');
      }
    }
  }

  Future<void> _addCurrentUserToCandidatesList() async {
    try {
      // Get current user's candidate data using the repository method
      final currentUserCandidate = await candidateController.candidateRepository
          .getCandidateData(currentUserId!);

      if (currentUserCandidate != null) {
        // Check if current user is already in the list (avoid duplicates)
        final existingIndex = candidateController.candidates.indexWhere(
          (c) => c.candidateId == currentUserCandidate.candidateId,
        );

        if (existingIndex == -1) {
          // Add current user to the beginning of the list
          candidateController.candidates.insert(0, currentUserCandidate);
          candidateController.update();
        }
      }
    } catch (e) {
      AppLogger.candidateError('Error adding current user to candidates list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Area Candidates'),
        elevation: 0,
      ),
      body: GetBuilder<CandidateController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load candidates',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserDataAndCandidates,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.candidates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No candidates in your area',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are no registered candidates in your ward yet.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadUserDataAndCandidates,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.candidates.length,
              itemBuilder: (context, index) {
                final candidate = controller.candidates[index];
                return CandidateCard(
                  candidate: candidate,
                  showCurrentUserIndicator: true,
                  currentUserId: currentUserId,
                  onFollowChanged: () {
                    setState(() {});
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }


}

