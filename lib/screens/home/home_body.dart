import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/candidate_model.dart';
import '../../services/trial_service.dart';
import '../../utils/symbol_utils.dart';
import '../candidate/candidate_list_screen.dart';
import '../candidate/candidate_dashboard_screen.dart';
import '../candidate/my_area_candidates_screen.dart';
import '../monetization/monetization_screen.dart';
import 'home_utils.dart';
import 'home_widgets.dart';
import 'home_navigation.dart';


class HomeBody extends StatelessWidget {
  final UserModel? userModel;
  final Candidate? candidateModel;
  final User? currentUser;

  const HomeBody({
    super.key,
    required this.userModel,
    required this.candidateModel,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(context),

          // Trial Status Banner (only for candidates with active trials)
          if (userModel?.role == 'candidate' && userModel?.isTrialActive == true)
            _buildTrialBanner(context),

          const SizedBox(height: 32),

          // Premium Features Card
          _buildPremiumCard(context),

          const SizedBox(height: 32),

          // Quick Actions
          _buildQuickActions(context),

          if (userModel?.role == 'candidate') ...[
            const SizedBox(height: 32),
            _buildCandidateDashboard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${userModel?.name ?? currentUser?.displayName ?? 'User'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (candidateModel != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image(
                    image: SymbolUtils.getSymbolImageProvider(
                      SymbolUtils.getPartySymbolPath(candidateModel!.party, candidate: candidateModel)
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/symbols/default.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          userModel?.role == 'candidate'
              ? AppLocalizations.of(context)!.manageYourCampaignAndConnectWithVoters
              : AppLocalizations.of(context)!.stayInformedAboutYourLocalCandidates,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTrialBanner(BuildContext context) {
    return FutureBuilder<int>(
      future: TrialService().getTrialDaysRemaining(userModel!.uid),
      builder: (context, snapshot) {
        final daysRemaining = snapshot.data ?? 0;
        if (daysRemaining <= 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.premiumTrialActive,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysRemaining == 1
                          ? AppLocalizations.of(context)!.oneDayRemainingUpgrade
                          : AppLocalizations.of(context)!.daysRemainingInTrial(daysRemaining.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (daysRemaining <= 1)
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to premium upgrade screen
                    Get.snackbar(
                      AppLocalizations.of(context)!.upgradeAvailable,
                      AppLocalizations.of(context)!.premiumUpgradeFeatureComingSoon,
                      backgroundColor: Colors.white,
                      colorText: Colors.blue,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(AppLocalizations.of(context)!.upgrade),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[400]!, Colors.orange[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.unlockPremiumFeatures,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userModel?.role == 'candidate'
                              ? (userModel?.isTrialActive == true
                                  ? AppLocalizations.of(context)!.enjoyFullPremiumFeaturesDuringTrial
                                  : AppLocalizations.of(context)!.getPremiumVisibilityAndAnalytics)
                              : AppLocalizations.of(context)!.accessExclusiveContentAndFeatures,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => HomeNavigation.toRightToLeft(const MonetizationScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.explorePremium,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.people,
              title: AppLocalizations.of(context)!.browseCandidates,
              page: const CandidateListScreen(),
            ),
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.location_on,
              title: AppLocalizations.of(context)!.myArea,
              page: const MyAreaCandidatesScreen(),
            ),
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.chat,
              title: AppLocalizations.of(context)!.chatRooms,
              routeName: '/chat',
            ),
            HomeWidgets.buildAnimatedQuickActionCard(
              icon: Icons.poll,
              title: AppLocalizations.of(context)!.polls,
              routeName: '/polls',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCandidateDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.candidateDashboard,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blue),
            title: Text(AppLocalizations.of(context)!.manageYourCampaign),
            subtitle: Text(AppLocalizations.of(context)!.viewAnalyticsAndUpdateYourProfile),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => HomeNavigation.toRightToLeft(const CandidateDashboardScreen()),
          ),
        ),
      ],
    );
  }
}