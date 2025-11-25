import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../user/models/user_model.dart';
import '../../../core/app_route_names.dart';
import '../repositories/candidate_repository.dart';
import '../../../services/location_data_service.dart';
import '../../../utils/snackbar_utils.dart';

class FollowerCard extends StatelessWidget {
  final Map<String, dynamic> follower;
  final UserModel? userData;

  const FollowerCard({super.key, required this.follower, this.userData});

  @override
  Widget build(BuildContext context) {
    final followedAt = follower['followedAt'] as Timestamp?;
    final notificationsEnabled =
        follower['notificationsEnabled'] as bool? ?? true;

    // Get user display name
    final displayName = userData != null ? userData!.name : 'Loading...';

    // Get location information - use IDs as fallback
    final wardId = userData?.primaryWardId ?? 'N/A';
    final bodyId = userData?.bodyId ?? 'N/A';
    final districtId = userData?.districtId ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Name, and Follower Badge
              Row(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    backgroundImage:
                        userData != null && userData!.photoURL != null
                        ? NetworkImage(userData!.photoURL!)
                        : null,
                    child: userData == null || userData!.photoURL == null
                        ? Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // User Name and Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (userData != null)
                          Text(
                            userData!.role.isNotEmpty
                                ? userData!.role.capitalizeFirst!
                                : 'User',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Follower Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Follower',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location Information
              if (userData != null)
                (FutureBuilder<Map<String, String>>(
                  future: LocationDataService.instance.getLocationNames(
                    stateId: userData!.stateId,
                    districtId: userData!.districtId,
                    bodyId: userData!.bodyId,
                    wardId: userData!.primaryWardId,
                  ),
                  builder: (context, snapshot) {
                    final locationNames = snapshot.data ?? {};
                    final wardName = locationNames['wardName'] ?? wardId;
                    final bodyName = locationNames['bodyName'] ?? bodyId;
                    final districtName =
                        locationNames['districtName'] ?? districtId;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$wardName | $bodyName | $districtName',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )),

              const SizedBox(height: 12),

              // Bottom Row: Follow info and View button
              Row(
                children: [
                  // Follow Date and Notifications
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Follow Date
                        if (followedAt != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Followed ${_formatDate(followedAt.toDate())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                        // Notifications Status
                        if (notificationsEnabled) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.notifications,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Notifications enabled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // View Button
                  if (userData != null)
                    ElevatedButton.icon(
                      onPressed: () => _viewProfile(context, userData!),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewProfile(BuildContext context, UserModel user) async {
    if (user.role.toLowerCase() == 'candidate') {
      try {
        // Show loading indicator
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Fetch candidate data
        final candidateRepository = CandidateRepository();
        final candidate = await candidateRepository.getCandidateData(user.uid);

        // Close loading dialog
        Get.back();

        if (candidate != null) {
          Get.toNamed(AppRouteNames.candidateProfile, arguments: candidate);
        } else {
          SnackbarUtils.showError('Candidate profile not found');
        }
      } catch (e) {
        // Close loading dialog if open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        SnackbarUtils.showError('Failed to load candidate profile: $e');
      }
    } else {
      Get.toNamed(AppRouteNames.profile, arguments: user.uid);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}
