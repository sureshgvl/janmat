import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../candidate/controllers/candidate_user_controller.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/screens/candidate_list_screen.dart';
import '../../candidate/screens/candidate_dashboard_screen.dart';
import '../../candidate/screens/my_area_candidates_screen.dart';
import '../../candidate/screens/candidate_profile_screen.dart';
import '../../candidate/screens/change_party_symbol_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../monetization/screens/monetization_screen.dart';
import 'about_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../notifications/screens/notification_center_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import 'home_navigation.dart';

class HomeDrawer extends StatelessWidget {
  final UserModel? userModel;
  final User? currentUser;
  final Candidate? candidateModel;

  const HomeDrawer({
    super.key,
    required this.userModel,
    required this.currentUser,
    this.candidateModel,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CandidateUserController>(
      builder: (candidateController) {
        // Use the candidateModel parameter or controller data if available
        final currentCandidateModel = candidateModel ?? candidateController.candidate.value;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            physics:
                const AlwaysScrollableScrollPhysics(), // Ensure always scrollable
            children: [
              // Profile Header Section (Scrollable)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Allow natural height
                    children: [
                      const SizedBox(height: 20), // Top padding above profile pic
                      // Profile Picture at Top
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            currentCandidateModel?.photo != null &&
                                currentCandidateModel!.photo!.isNotEmpty
                            ? NetworkImage(currentCandidateModel!.photo!)
                            : userModel?.photoURL != null
                            ? NetworkImage(userModel!.photoURL!)
                            : currentUser?.photoURL != null
                            ? NetworkImage(currentUser!.photoURL!)
                            : null,
                        child:
                            (currentCandidateModel?.photo == null ||
                                    currentCandidateModel!.photo!.isEmpty) &&
                                userModel?.photoURL == null &&
                                currentUser?.photoURL == null
                            ? Text(
                                ((userModel?.role == 'candidate' && currentCandidateModel != null
                                      ? (currentCandidateModel!.basicInfo?.fullName ?? currentCandidateModel.basicInfo!.fullName ?? userModel?.name ?? currentUser?.displayName ?? 'Candidate')
                                      : userModel?.name ?? currentUser?.displayName ?? 'U')
                                            .isEmpty
                                        ? 'U'
                                        : (userModel?.role == 'candidate' && currentCandidateModel != null
                                            ? (currentCandidateModel!.basicInfo?.fullName ?? currentCandidateModel.basicInfo!.fullName ?? userModel?.name ?? currentUser?.displayName ?? 'Candidate')
                                            : userModel?.name ?? currentUser?.displayName ?? 'U')[0])
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 40,
                                  color: Theme.of(context).appBarTheme.foregroundColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // User Info Below Picture
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name
                          Text(
                            userModel?.role == 'candidate' && currentCandidateModel != null
                                ? (currentCandidateModel!.basicInfo?.fullName ?? currentCandidateModel.basicInfo!.fullName ?? userModel?.name ?? currentUser?.displayName ?? 'Candidate')
                                : userModel?.name ?? currentUser?.displayName ?? 'User',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).appBarTheme.foregroundColor,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          // Email/Phone
                          Text(
                            userModel?.email ??
                                currentUser?.email ??
                                currentUser?.phoneNumber ??
                                '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).appBarTheme.foregroundColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Plan Badge (only for candidates)
                          if (userModel?.role == 'candidate') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userModel?.premium == true
                                        ? Icons.star
                                        : userModel?.isTrialActive == true
                                        ? Icons.access_time
                                        : Icons.free_breakfast,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getPlanDisplayText(userModel!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).appBarTheme.foregroundColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(
                            height: 16,
                          ), // Extra space before menu items
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppLocalizations.of(context)!.profile),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate based on user role
              if (userModel?.role == 'candidate' && currentCandidateModel != null) {
                HomeNavigation.toRightToLeft(
                  const CandidateProfileScreen(),
                  arguments: currentCandidateModel,
                );
              } else {
                HomeNavigation.toNamedRightToLeft('/profile');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(AppLocalizations.of(context)!.myAreaCandidates),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(const MyAreaCandidatesScreen());
            },
          ),
          // Show candidate-specific menu items
          if (userModel?.role == 'candidate' && currentCandidateModel != null) ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(AppLocalizations.of(context)!.candidateDashboard),
              onTap: () {
                Navigator.pop(context); // Close drawer
                HomeNavigation.toRightToLeft(
                  const CandidateDashboardScreen(),
                ); // Navigate to candidate dashboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(AppLocalizations.of(context)!.changePartySymbolTitle),
              onTap: () {
                Navigator.pop(context); // Close drawer
                HomeNavigation.toRightToLeft(
                  ChangePartySymbolScreen(
                    currentCandidate: currentCandidateModel,
                  ),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(AppLocalizations.of(context)!.searchByWard),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(
                const CandidateListScreen(),
              ); // Navigate to candidate list screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: Text(AppLocalizations.of(context)!.chatRooms),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(
                const ChatListScreen(),
              ); // Navigate to chat list screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(AppLocalizations.of(context)!.notifications),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(
                const NotificationCenterScreen(),
              ); // Navigate to notification center
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(
                const SettingsScreen(),
              ); // Navigate to settings screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppLocalizations.of(context)!.about),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(
                const AboutScreen(),
              ); // Navigate to about screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFFFF9933)),
            title: Text(AppLocalizations.of(context)!.premiumFeatures),
            subtitle: Text(
              AppLocalizations.of(context)!.upgradeToUnlockPremiumFeatures,
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(const MonetizationScreen());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: Text(
              AppLocalizations.of(context)!.logout,
              style: TextStyle(color: Colors.orange),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.signOutOfYourAccount,
            ),
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout == true) {
                // Close drawer first
                Navigator.of(context).pop();
                // Then logout
                final authController = Get.find<AuthController>();
                await authController.logout();
              }
            },
          ),
            ],
          ),
        );
      },
    );
  }

  String _getPlanDisplayText(UserModel userModel) {
    if (userModel.premium) {
      if (userModel.subscriptionPlanId != null) {
        return 'Premium (${userModel.subscriptionPlanId})';
      }
      return 'Premium';
    } else if (userModel.isTrialActive) {
      return 'Trial Active';
    } else {
      return 'Free Plan';
    }
  }
}
