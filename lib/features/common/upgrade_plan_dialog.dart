import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../monetization/services/plan_service.dart';
import '../../l10n/features/candidate/candidate_localizations.dart';
import '../../core/app_route_names.dart';

/// Comprehensive upgrade plan dialog for showing plan limitations
/// 
/// This dialog provides consistent messaging for free plan candidates when they
/// try to access premium features like:
/// - Adding more than 2 promises
/// - Uploading images/videos to manifesto
/// - Other premium features
class UpgradePlanDialog {
  /// Shows upgrade dialog for promise limit exceeded
  static Future<bool?> showPromiseLimitExceeded({
    required BuildContext context,
    required int currentPromises,
    required int maxPromises,
  }) async {
    final localizations = CandidateLocalizations.of(context);
    if (localizations == null) return null;

    return await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialog(
        context: context,
        icon: Icons.trending_up,
        iconColor: Colors.orange,
        title: localizations.translate('promiseLimitReached') ?? 'Promise Limit Reached',
        message: currentPromises >= maxPromises 
            ? (localizations.translate('promiseLimitMessage', args: {
                'count': maxPromises.toString(),
                'promiseText': maxPromises == 1 
                    ? localizations.translate('promiseSingular') ?? 'promise'
                    : localizations.translate('promisePlural') ?? 'promises'
              }) ?? 'You can add up to $maxPromises promises with your current plan.')
            : localizations.translate('freePlanPromiseLimitMessage') ?? 'Free plan allows only 2 promises. Upgrade to add more detailed promises and make your manifesto more comprehensive.',
        features: [
          'Add unlimited promises to your manifesto',
          'Detailed promise points and sub-points',
          'Professional manifesto presentation',
          'Enhanced voter engagement',
        ],
        upgradeButtonText: localizations.translate('upgradeToGold') ?? 'Upgrade to Gold Plan',
        cancelButtonText: localizations.translate('cancel') ?? 'Cancel',
      ),
    );
  }

  /// Shows upgrade dialog for image upload attempt
  static Future<bool?> showImageUploadRestricted({
    required BuildContext context,
  }) async {
    final localizations = CandidateLocalizations.of(context);
    if (localizations == null) return null;

    return await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialog(
        context: context,
        icon: Icons.image,
        iconColor: Colors.green,
        title: localizations.translate('premiumFeatureRequired') ?? 'Premium Feature Required',
        message: localizations.translate('freePlanImageUploadMessage') ?? 'Image upload is a premium feature. Add visual appeal to your manifesto with high-quality images that showcase your vision and connect with voters.',
        features: [
          'Upload manifesto images',
          'Visual storytelling for your promises',
          'Professional candidate presentation',
          'Enhanced voter engagement',
        ],
        upgradeButtonText: localizations.translate('upgradeNow') ?? 'Upgrade Now',
        cancelButtonText: localizations.translate('cancel') ?? 'Cancel',
      ),
    );
  }

  /// Shows upgrade dialog for video upload attempt
  static Future<bool?> showVideoUploadRestricted({
    required BuildContext context,
  }) async {
    final localizations = CandidateLocalizations.of(context);
    if (localizations == null) return null;

    return await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialog(
        context: context,
        icon: Icons.video_call,
        iconColor: Colors.purple,
        title: localizations.translate('premiumFeatureRequired') ?? 'Premium Feature Required',
        message: localizations.translate('freePlanVideoUploadMessage') ?? 'Video upload is a premium feature. Create powerful video content to communicate your vision directly to voters and build stronger connections.',
        features: [
          'Upload manifesto videos',
          'Direct voter communication',
          'Video testimonials and promises',
          'Maximum voter engagement',
        ],
        upgradeButtonText: localizations.translate('upgradeNow') ?? 'Upgrade Now',
        cancelButtonText: localizations.translate('cancel') ?? 'Cancel',
      ),
    );
  }

  /// Shows upgrade dialog for PDF upload attempt
  static Future<bool?> showPdfUploadRestricted({
    required BuildContext context,
  }) async {
    final localizations = CandidateLocalizations.of(context);
    if (localizations == null) return null;

    return await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialog(
        context: context,
        icon: Icons.picture_as_pdf,
        iconColor: Colors.red,
        title: localizations.translate('premiumFeatureRequired') ?? 'Premium Feature Required',
        message: localizations.translate('freePlanPdfUploadMessage') ?? 'PDF manifesto upload is a premium feature. Share detailed policy documents and comprehensive plans with voters.',
        features: [
          'Upload detailed PDF manifestos',
          'Policy documents and whitepapers',
          'Comprehensive development plans',
          'Professional document presentation',
        ],
        upgradeButtonText: localizations.translate('upgradeNow') ?? 'Upgrade Now',
        cancelButtonText: localizations.translate('cancel') ?? 'Cancel',
      ),
    );
  }

  /// Generic upgrade dialog for any premium feature
  static Future<bool?> showGeneric({
    required BuildContext context,
    required String featureName,
    required String description,
    required List<String> features,
    IconData? icon,
    Color? iconColor,
  }) async {
    final localizations = CandidateLocalizations.of(context);
    if (localizations == null) return null;

    return await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialog(
        context: context,
        icon: icon ?? Icons.stars,
        iconColor: iconColor ?? Colors.amber,
        title: '${featureName} ${localizations.translate('premiumFeatureRequired') ?? 'Requires Premium Plan'}',
        message: description,
        features: features,
        upgradeButtonText: localizations.translate('upgradeNow') ?? 'Upgrade Now',
        cancelButtonText: localizations.translate('cancel') ?? 'Cancel',
      ),
    );
  }

  /// Check if user is on free plan
  static Future<bool> _isFreePlan() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return true;

    final plan = await PlanService.getUserPlan(currentUser.uid);
    return plan == null || plan.dashboardTabs?.manifesto.enabled != true;
  }

  /// Main dialog builder with consistent styling and behavior
  static AlertDialog _buildDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required List<String> features,
    required String upgradeButtonText,
    required String cancelButtonText,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Features list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'With Gold Plan:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: iconColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Plan info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gold Plan starts at competitive rates with flexible payment options',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            cancelButtonText,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        // Upgrade button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            // Navigate to monetization screen
            Get.toNamed(AppRouteNames.monetization);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Text(
            upgradeButtonText,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience methods for common upgrade scenarios
class PlanUpgradeHelper {
  /// Check and show appropriate upgrade dialog for promises
  static Future<bool> checkAndShowPromiseUpgrade({
    required BuildContext context,
    required int currentPromises,
    required int maxPromises,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final plan = await PlanService.getUserPlan(currentUser.uid);
    
    if (plan != null && plan.dashboardTabs?.manifesto.enabled == true) {
      // Has paid plan - check if limit exceeded
      if (currentPromises >= maxPromises) {
        final result = await UpgradePlanDialog.showPromiseLimitExceeded(
          context: context,
          currentPromises: currentPromises,
          maxPromises: maxPromises,
        );
        return result == true;
      }
      return false; // Can add more promises
    } else {
      // Free plan - restrict to 2 promises
      if (currentPromises >= 2) {
        final result = await UpgradePlanDialog.showPromiseLimitExceeded(
          context: context,
          currentPromises: currentPromises,
          maxPromises: 2,
        );
        return result == true;
      }
      return false; // Can add more promises (within 2 limit)
    }
  }

  /// Check and show upgrade dialog for media upload
  static Future<bool> checkAndShowMediaUpgrade({
    required BuildContext context,
    required String mediaType, // 'image', 'video', 'pdf'
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final plan = await PlanService.getUserPlan(currentUser.uid);
    
    if (plan == null || plan.dashboardTabs?.manifesto.enabled != true) {
      // Free plan - show appropriate dialog
      switch (mediaType.toLowerCase()) {
        case 'image':
          final result = await UpgradePlanDialog.showImageUploadRestricted(
            context: context,
          );
          return result == true;
        case 'video':
          final result = await UpgradePlanDialog.showVideoUploadRestricted(
            context: context,
          );
          return result == true;
        case 'pdf':
          final result = await UpgradePlanDialog.showPdfUploadRestricted(
            context: context,
          );
          return result == true;
        default:
          return false;
      }
    } else {
      // Paid plan - check specific permissions
      if (mediaType.toLowerCase() == 'video') {
        final canUploadVideo = plan.dashboardTabs!.manifesto.features.videoUpload;
        if (!canUploadVideo) {
          final result = await UpgradePlanDialog.showVideoUploadRestricted(
            context: context,
          );
          return result == true;
        }
      }
      return false; // Can upload media
    }
  }
}
