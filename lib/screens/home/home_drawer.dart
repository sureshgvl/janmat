import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/candidate_model.dart';
import '../../utils/symbol_utils.dart';
import '../candidate/candidate_list_screen.dart';
import '../candidate/candidate_dashboard_screen.dart';
import '../candidate/my_area_candidates_screen.dart';
import '../candidate/candidate_profile_screen.dart';
import '../candidate/change_party_symbol_screen.dart';
import '../settings/settings_screen.dart';
import '../monetization/monetization_screen.dart';
import '../chat/chat_list_screen.dart';
import 'home_navigation.dart';


class HomeDrawer extends StatelessWidget {
  final UserModel? userModel;
  final Candidate? candidateModel;
  final User? currentUser;
  final Function(BuildContext, UserModel?) onDeleteAccount;

  const HomeDrawer({
    super.key,
    required this.userModel,
    required this.candidateModel,
    required this.currentUser,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Row(
              children: [
                Expanded(
                  child: Text(
                    userModel?.name ?? currentUser?.displayName ?? 'User',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (candidateModel != null) ...[
                  const SizedBox(width: 8),
                  // Container(
                  //   width: 100,
                  //   height: 100,
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(4),
                  //     border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  //   ),
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius.circular(3),
                  //     child: Image(
                  //       image: SymbolUtils.getSymbolImageProvider(
                  //         SymbolUtils.getPartySymbolPath(candidateModel?.party ?? '', candidate: candidateModel)
                  //       ),
                  //       fit: BoxFit.cover,
                  //       errorBuilder: (context, error, stackTrace) {
                  //         return Image.asset(
                  //           'assets/symbols/default.png',
                  //           fit: BoxFit.cover,
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ),
                ],
              ],
            ),
            accountEmail: Text(userModel?.email ?? currentUser?.email ?? currentUser?.phoneNumber ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: candidateModel?.photo != null && candidateModel!.photo!.isNotEmpty
                  ? NetworkImage(candidateModel!.photo!)
                  : userModel?.photoURL != null
                      ? NetworkImage(userModel!.photoURL!)
                      : currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
              child: (candidateModel?.photo == null || candidateModel!.photo!.isEmpty) &&
                     userModel?.photoURL == null &&
                     currentUser?.photoURL == null
                  ? Text(
                      ((userModel?.name ?? currentUser?.displayName ?? 'U').isEmpty
                          ? 'U'
                          : (userModel?.name ?? currentUser?.displayName ?? 'U')[0]).toUpperCase(),
                      style: const TextStyle(fontSize: 24, color: Colors.blue),
                    )
                  : null,
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppLocalizations.of(context)!.profile),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate based on user role
              if (userModel?.role == 'candidate' && candidateModel != null) {
                HomeNavigation.toRightToLeft(const CandidateProfileScreen(), arguments: candidateModel);
              } else {
                HomeNavigation.toNamedRightToLeft('/profile');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(AppLocalizations.of(context)!.myAreaCandidates),
            subtitle: Text(AppLocalizations.of(context)!.candidatesFromYourWard),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(const MyAreaCandidatesScreen());
            },
          ),
          if (userModel?.role == 'candidate') ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(AppLocalizations.of(context)!.candidateDashboard),
              onTap: () {
                Navigator.pop(context); // Close drawer
                HomeNavigation.toRightToLeft(const CandidateDashboardScreen()); // Navigate to candidate dashboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Change Party & Symbol'),
              subtitle: const Text('Update your party affiliation and symbol'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                HomeNavigation.toRightToLeft(ChangePartySymbolScreen(
                  currentCandidate: candidateModel,
                  currentUser: currentUser,
                ));
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(AppLocalizations.of(context)!.searchByWard),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(const CandidateListScreen()); // Navigate to candidate list screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: Text(AppLocalizations.of(context)!.chatRooms),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(const ChatListScreen()); // Navigate to chat list screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(const SettingsScreen()); // Navigate to settings screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.orange),
            title: Text(AppLocalizations.of(context)!.premiumFeatures),
            subtitle: Text(AppLocalizations.of(context)!.upgradeToUnlockPremiumFeatures),
            onTap: () {
              Navigator.pop(context); // Close drawer
              HomeNavigation.toRightToLeft(const MonetizationScreen());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(AppLocalizations.of(context)!.deleteAccount, style: TextStyle(color: Colors.red)),
            subtitle: Text(AppLocalizations.of(context)!.permanentlyDeleteYourAccountAndData),
            onTap: () => onDeleteAccount(context, userModel),
          ),
        ],
      ),
    );
  }
}