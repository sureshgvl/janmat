import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../../user/models/user_model.dart';
import '../../user/controllers/user_controller.dart';
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
    AppLogger.common(
      '🏠 [HOME_DRAWER] Building drawer - userModel: ${userModel?.name} (${userModel?.role}), candidateModel param: ${candidateModel?.basicInfo?.fullName ?? "null"}',
    );

    // Profile header uses UserController only
    return GetBuilder<UserController>(
      builder: (userController) {
        AppLogger.common(
          '🏠 [HOME_DRAWER] User controller available with photoURL: ${userController.user.value?.photoURL}',
        );

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Profile Header Section (USES ONLY UserController)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Picture - from UserController.user.value
                      Builder(
                        builder: (context) {
                          String displayName = '';
                          String source = '';

                          if (userModel?.role == 'candidate') {
                            // Show user name for candidates header
                            if (userModel?.name != null && userModel!.name.isNotEmpty) {
                              displayName = userModel!.name;
                              source = 'user_name';
                            } else if (currentUser?.displayName?.isNotEmpty == true) {
                              displayName = currentUser!.displayName!;
                              source = 'firebase_display_name';
                            } else {
                              displayName = 'Candidate';
                              source = 'default_candidate';
                            }
                          } else {
                            // For non-candidates
                            if (userModel?.name != null && userModel!.name.isNotEmpty) {
                              displayName = userModel!.name;
                              source = 'user_name';
                            } else if (currentUser?.displayName?.isNotEmpty == true) {
                              displayName = currentUser!.displayName!;
                              source = 'firebase_display_name';
                            } else {
                              displayName = 'User';
                              source = 'default_user';
                            }
                          }

                          String initials = displayName.isNotEmpty
                              ? displayName.trim().split(' ').length > 1
                                    ? '${displayName.trim().split(' ')[0][0]}${displayName.trim().split(' ')[1][0]}'
                                          .toUpperCase()
                                    : displayName.trim()[0].toUpperCase()
                              : 'U';

                          // PHOTO SOURCE: UserController.user.value.photoURL
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue[600],
                            backgroundImage:
                                userController.user.value?.photoURL != null
                                ? NetworkImage(userController.user.value!.photoURL!)
                                : currentUser?.photoURL != null
                                ? NetworkImage(currentUser!.photoURL!)
                                : null,
                            child:
                                (userController.user.value?.photoURL == null &&
                                    currentUser?.photoURL == null)
                                ? Text(
                                    initials,
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // User Info Below Picture - from UserController and userModel
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name
                          Text(
                            userModel?.role == 'candidate'
                                ? (userModel?.name ?? currentUser?.displayName ?? 'Candidate')
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
                            userModel?.email ?? currentUser?.email ?? currentUser?.phoneNumber ?? '',
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // REST OF DRAWER - keeps existing candidate logic for menus
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(AppLocalizations.of(context)!.profile),
                onTap: () {
                  Navigator.pop(context);
                  if (userModel?.role == 'candidate' && candidateModel != null) {
                    HomeNavigation.toRightToLeft(
                      const CandidateProfileScreen(),
                      arguments: candidateModel,
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
                  Navigator.pop(context);
                  HomeNavigation.toRightToLeft(const MyAreaCandidatesScreen());
                },
              ),
              // Show candidate-specific menu items
              if (userModel?.role == 'candidate' && candidateModel != null) ...[
                Builder(
                  builder: (context) {
                    AppLogger.common(
                      '🏠 [HOME_DRAWER] Showing candidate menu items - user role: ${userModel?.role}',
                    );
                    return const SizedBox.shrink();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: Text(AppLocalizations.of(context)!.candidateDashboard),
                  onTap: () {
                    Navigator.pop(context);
                    HomeNavigation.toRightToLeft(const CandidateDashboardScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(AppLocalizations.of(context)!.changePartySymbolTitle),
                  onTap: () {
                    Navigator.pop(context);
                    HomeNavigation.toRightToLeft(ChangePartySymbolScreen(currentCandidate: candidateModel));
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(AppLocalizations.of(context)!.searchByWard),
                onTap: () {
                  Navigator.pop(context);
                  HomeNavigation.toRightToLeft(const CandidateListScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(AppLocalizations.of(context)!.chatRooms),
                onTap: () {
                  Navigator.pop(context);
                  HomeNavigation.toRightToLeft(const ChatListScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(AppLocalizations.of(context)!.notifications),
                onTap: () {
                  Navigator.pop(context);
                  HomeNavigation.toRightToLeft(const NotificationCenterScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(AppLocalizations.of(context)!.settings),
                onTap: () {
                  Navigator.pop(context);
                  HomeNavigation.toRightToLeft(const SettingsScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(AppLocalizations.of(context)!.about),
                onTap: () {
                  Navigator.pop(context);
                  HomeNavigation.toRightToLeft(const AboutScreen());
                },
              ),

              // Premium Features
              Builder(
                builder: (context) {
                  final showPremiumFeatures = userModel?.role == 'candidate';
                  AppLogger.candidate(
                    '🏠 [HOME_DRAWER] Role check: ${userModel?.role}, showPremiumFeatures: $showPremiumFeatures',
                  );

                  if (!showPremiumFeatures) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(),
                      Builder(
                        builder: (context) {
                          AppLogger.candidate('🏠 [HOME_DRAWER] Rendering premium features button');
                          return ListTile(
                            leading: const Icon(Icons.star, color: Color(0xFFFF9933)),
                            title: Text(AppLocalizations.of(context)!.premiumFeatures),
                            subtitle: Text(AppLocalizations.of(context)!.upgradeToUnlockPremiumFeatures),
                            onTap: () {
                              AppLogger.core('🏠 [HOME_DRAWER] 🔥 PREMIUM FEATURES BUTTON CLICKED! 🔥');
                              Navigator.pop(context);
                              HomeNavigation.toRightToLeft(const MonetizationScreen());
                            },
                          );
                        },
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: Text(AppLocalizations.of(context)!.logout, style: TextStyle(color: Colors.orange)),
                subtitle: Text(AppLocalizations.of(context)!.signOutOfYourAccount),
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(foregroundColor: Colors.orange),
                            child: const Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldLogout == true) {
                    Navigator.of(context).pop();
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
