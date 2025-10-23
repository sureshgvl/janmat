import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/symbol_utils.dart';
import '../../candidate/controllers/candidate_user_controller.dart';
import '../../candidate/screens/candidate_list_screen.dart';
import '../../candidate/screens/my_area_candidates_screen.dart';
import '../../monetization/screens/monetization_screen.dart';
import '../screens/home_navigation.dart';

class HomeWidgets {
  // Welcome Section Widget
  static Widget buildWelcomeSection(BuildContext context, UserModel? userModel, User? currentUser) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;

    // For candidates, use reactive widget
    if (userModel?.role == 'candidate') {
      return GetBuilder<CandidateUserController>(
        builder: (candidateController) {
          final candidateModel = candidateController.candidate.value;
          // Debug: Log candidate data status
          AppLogger.common('🏠 Welcome Section - CandidateUserController Status:', tag: 'HOME');
          AppLogger.common('  👤 User Role: ${candidateController.user.value?.role ?? 'No user'}', tag: 'HOME');
          AppLogger.common('  🎯 Candidate Available: ${candidateModel != null}', tag: 'HOME');
          if (candidateModel != null) {
            AppLogger.common('  👥 Candidate Name: ${candidateModel.name}', tag: 'HOME');
            AppLogger.common('  🎭 Candidate Party: ${candidateModel.party}', tag: 'HOME');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${userModel?.role == 'candidate' && candidateModel != null ? candidateModel.name : userModel?.name ?? currentUser?.displayName ?? 'User'}!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (candidateModel != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image(
                          image: SymbolUtils.getSymbolImageProvider(
                            SymbolUtils.getPartySymbolPath(
                              candidateModel.party,
                              candidate: candidateModel,
                            ),
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
                  color: onSurfaceColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          );
        },
      );
    }

    // For non-candidates, return static widget
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${userModel?.name ?? currentUser?.displayName ?? 'User'}!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.stayInformedAboutYourLocalCandidates,
          style: TextStyle(
            fontSize: 16,
            color: onSurfaceColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // Trial Banner Widget
  static Widget buildTrialBanner(BuildContext context, UserModel userModel) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    return FutureBuilder<int>(
      // future: TrialService().getTrialDaysRemaining(userModel.uid), // Commented out - no trial service in app
      future: Future.value(0), // Return 0 since no trial service
      builder: (context, snapshot) {
        final daysRemaining = snapshot.data ?? 0;
        if (daysRemaining <= 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.8),
                primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: onPrimaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.premiumTrialActive,
                      style: TextStyle(
                        color: onPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysRemaining == 1
                          ? AppLocalizations.of(context)!.oneDayRemainingUpgrade
                          : AppLocalizations.of(context)!.daysRemainingInTrial(daysRemaining.toString()),
                      style: TextStyle(color: onPrimaryColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (daysRemaining <= 1)
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to premium upgrade screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.premiumUpgradeFeatureComingSoon),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onPrimaryColor,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.upgrade),
                ),
            ],
          ),
        );
      },
    );
  }

  // Premium Card Widget
  static Widget buildPremiumCard(BuildContext context, UserModel? userModel) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: onPrimaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.unlockPremiumFeatures,
                          style: TextStyle(
                            color: onPrimaryColor,
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
                            color: onPrimaryColor.withValues(alpha: 0.9),
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
                    backgroundColor: onPrimaryColor,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.explorePremium,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Actions Widget
  static Widget buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurfaceColor,
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
            _buildAnimatedQuickActionCard(
              icon: Icons.people,
              title: AppLocalizations.of(context)!.browseCandidates,
              page: const CandidateListScreen(),
            ),
            _buildAnimatedQuickActionCard(
              icon: Icons.location_on,
              title: AppLocalizations.of(context)!.myArea,
              page: const MyAreaCandidatesScreen(),
            ),
            _buildAnimatedQuickActionCard(
              icon: Icons.chat,
              title: AppLocalizations.of(context)!.chatRooms,
              routeName: '/chat',
            ),
            _buildAnimatedQuickActionCard(
              icon: Icons.poll,
              title: AppLocalizations.of(context)!.polls,
              routeName: '/polls',
            ),
          ],
        ),
      ],
    );
  }

  // Animated Quick Action Card
  static Widget _buildAnimatedQuickActionCard({
    required IconData icon,
    required String title,
    Widget? page,
    String? routeName,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final onSurfaceColor = theme.colorScheme.onSurface;

        return GestureDetector(
          onTap: () {
            if (page != null) {
              // Navigate to page
            } else if (routeName != null) {
              // Navigate to route
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
