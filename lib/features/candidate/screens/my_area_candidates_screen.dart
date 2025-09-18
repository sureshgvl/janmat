import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/candidate_controller.dart';
import '../models/candidate_model.dart';
import '../../../models/user_model.dart';
import '../widgets/follow_button.dart';
import 'candidate_profile_screen.dart';

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

          // Load candidates from user's ward using new district/body/ward structure
          await candidateController.fetchCandidatesByWard(
            currentUser!.districtId!,
            currentUser!.bodyId!,
            currentUser!.wardId,
          );

          // If current user is a candidate, add them to the list
          if (currentUser!.role == 'candidate') {
            await _addCurrentUserToCandidatesList();
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
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
      debugPrint('Error adding current user to candidates list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Area Candidates'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
                return _buildCandidateCard(candidate);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandidateCard(Candidate candidate) {
    final isCurrentUser = candidate.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentUser ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.to(() => const CandidateProfileScreen(), arguments: candidate);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isCurrentUser
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with photo and basic info
                Row(
                  children: [
                    // Profile Photo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrentUser
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: isCurrentUser ? 3 : 1,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            candidate.photo != null &&
                                candidate.photo!.isNotEmpty
                            ? Image.network(
                                candidate.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return CircleAvatar(
                                    backgroundColor: candidate.sponsored
                                        ? Colors.grey.shade600
                                        : Colors.blue,
                                    child: Text(
                                      candidate.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : CircleAvatar(
                                backgroundColor: candidate.sponsored
                                    ? Colors.grey.shade600
                                    : Colors.blue,
                                child: Text(
                                  candidate.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Party
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        candidate.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrentUser
                                              ? Colors.blue
                                              : const Color(0xFF1f2937),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'YOU',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (candidate.sponsored)
                                Flexible(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'SPONSORED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF374151),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            candidate.party,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats Row
                Row(
                  children: [
                    _buildStatItem('${candidate.followersCount}', 'Followers'),
                    const SizedBox(width: 16),
                    _buildStatItem('${candidate.followingCount}', 'Following'),
                  ],
                ),
                const SizedBox(height: 12),

                // Manifesto preview
                if (candidate.manifesto != null &&
                    candidate.manifesto!.isNotEmpty)
                  Text(
                    candidate.manifesto!.length > 100
                        ? '${candidate.manifesto!.substring(0, 100)}...'
                        : candidate.manifesto!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.4,
                    ),
                  ),

                const SizedBox(height: 16),

                // Follow Button (don't show for current user)
                if (currentUserId != null && !isCurrentUser)
                  SizedBox(
                    width: double.infinity,
                    child: FollowButton(
                      candidateId: candidate.candidateId,
                      userId: currentUserId!,
                      showFollowersCount: false,
                      onFollowChanged: () {
                        setState(() {});
                      },
                    ),
                  ),

                // Current user indicator
                if (isCurrentUser)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'This is your profile',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1f2937),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
        ),
      ],
    );
  }
}
