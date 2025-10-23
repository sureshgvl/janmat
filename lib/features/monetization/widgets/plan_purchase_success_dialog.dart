import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/plan_model.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/theme_constants.dart';
import '../../../controllers/theme_controller.dart';

class PlanPurchaseSuccessDialog extends StatefulWidget {
  final SubscriptionPlan plan;
  final int validityDays;
  final int amountPaid;
  final String? electionType;
  final VoidCallback? onContinue;
  final VoidCallback? onViewBenefits;

  const PlanPurchaseSuccessDialog({
    Key? key,
    required this.plan,
    required this.validityDays,
    required this.amountPaid,
    this.electionType,
    this.onContinue,
    this.onViewBenefits,
  }) : super(key: key);

  @override
  State<PlanPurchaseSuccessDialog> createState() => _PlanPurchaseSuccessDialogState();
}

class _PlanPurchaseSuccessDialogState extends State<PlanPurchaseSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 450,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  boxShadow: [
                    AppShadows.medium,
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildContent(),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final themeController = Get.find<ThemeController>();
    final primaryColor = themeController.getThemePrimaryColor(themeController.currentThemeType.value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getPlanGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.xl),
          topRight: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Purchase Successful!',
                  style: AppTypography.heading4.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.plan.name} Plan Activated',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanDetails(),
          const SizedBox(height: 16),
          _buildBenefitsPreview(),
          if (widget.plan.type == 'candidate' && widget.plan.planId == 'platinum_plan') ...[
            const SizedBox(height: 16),
            _buildWelcomeContentNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan Details',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPlanColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.plan.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getPlanColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow('Validity', '${widget.validityDays} days'),
              ),
            ],
          ),
          if (widget.electionType != null)
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('Election Type', widget.electionType!.replaceAll('_', ' ').toUpperCase()),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow('Amount Paid', '₹${widget.amountPaid}'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow('Valid Until', _calculateExpiryDate()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsPreview() {
    final benefits = _getPlanBenefits();
    if (benefits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What You\'ve Unlocked',
          style: AppTypography.heading4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...benefits.take(3).map((benefit) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: _getPlanColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benefit,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (benefits.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${benefits.length - 3} more benefits',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWelcomeContentNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.amber[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Content Created!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
                Text(
                  'Your Platinum highlight banner is now live!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final themeController = Get.find<ThemeController>();
    final primaryColor = themeController.getThemePrimaryColor(themeController.currentThemeType.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppBorderRadius.xl),
          bottomRight: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onContinue?.call();
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(
          'Continue',
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<String> _getPlanBenefits() {
    switch (widget.plan.type) {
      case 'candidate':
        if (widget.plan.planId == 'gold_plan') {
          return [
            'Enhanced dashboard with advanced analytics',
            'Unlimited media uploads and storage',
            'Priority customer support',
            'Carousel highlight placement',
            'Push notifications for engagement',
          ];
        } else if (widget.plan.planId == 'platinum_plan') {
          return [
            'All Gold features plus exclusive benefits',
            'Platinum highlight banner placement',
            'Multiple highlights support',
            'Admin-level support access',
            'Custom branding options',
            'Real-time analytics dashboard',
          ];
        }
        break;
      case 'highlight':
        return [
          'Premium banner placement',
          'High visibility positioning',
          'Analytics tracking',
          'Custom banner styling',
        ];
      case 'carousel':
        return [
          'Carousel slot allocation',
          'Auto-rotation placement',
          'Analytics access',
          'Custom timing controls',
        ];
    }
    return [];
  }

  Color _getPlanColor() {
    final themeController = Get.find<ThemeController>();
    final primaryColor = themeController.getThemePrimaryColor(themeController.currentThemeType.value);

    // Use theme primary color for all plans to maintain consistency
    return primaryColor;
  }

  List<Color> _getPlanGradientColors() {
    final themeController = Get.find<ThemeController>();
    final primaryColor = themeController.getThemePrimaryColor(themeController.currentThemeType.value);
    final secondaryColor = themeController.getThemeSecondaryColor(themeController.currentThemeType.value);

    // Use theme colors for gradient
    return [primaryColor, secondaryColor != Colors.white ? secondaryColor : primaryColor.withOpacity(0.8)];
  }

  IconData _getPlanIcon() {
    switch (widget.plan.type) {
      case 'candidate':
        return widget.plan.planId == 'platinum_plan' ? Icons.diamond : Icons.star;
      case 'highlight':
        return Icons.flag;
      case 'carousel':
        return Icons.view_carousel;
      default:
        return Icons.check_circle;
    }
  }

  String _calculateExpiryDate() {
    final expiryDate = DateTime.now().add(Duration(days: widget.validityDays));
    return '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
  }
}
