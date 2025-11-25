import 'package:flutter/material.dart';
import '../../../models/plan_model.dart';

class PlanBenefitsShowcase extends StatefulWidget {
  final SubscriptionPlan plan;
  final int validityDays;
  final VoidCallback? onGetStarted;

  const PlanBenefitsShowcase({
    super.key,
    required this.plan,
    required this.validityDays,
    this.onGetStarted,
  });

  @override
  State<PlanBenefitsShowcase> createState() => _PlanBenefitsShowcaseState();
}

class _PlanBenefitsShowcaseState extends State<PlanBenefitsShowcase>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _benefitAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create staggered animations for benefits
    final benefits = _getBenefits();
    _benefitAnimations = List.generate(
      benefits.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            (index * 0.1) + 0.6,
            curve: Curves.elasticOut,
          ),
        ),
      ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[600]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.plan.name} Plan Benefits',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildBenefitsList(),
            _buildNextSteps(),
            _buildGetStartedButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getPlanGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPlanIcon(),
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.plan.name} Plan Activated!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Valid for ${widget.validityDays} days',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = _getBenefits();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What You Can Do Now',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          ...benefits.asMap().entries.map((entry) {
            final index = entry.key;
            final benefit = entry.value;
            if (index < _benefitAnimations.length) {
              return AnimatedBuilder(
                animation: _benefitAnimations[index],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _benefitAnimations[index].value) * 50),
                    child: Opacity(
                      opacity: _benefitAnimations[index].value.clamp(0.0, 1.0),
                      child: _buildBenefitCard(benefit),
                    ),
                  );
                },
              );
            } else {
              return _buildBenefitCard(benefit);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(BenefitItem benefit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: benefit.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              benefit.icon,
              color: benefit.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  benefit.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    final nextSteps = _getNextSteps();

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Next Steps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...nextSteps.map((step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${nextSteps.indexOf(step) + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: widget.onGetStarted ?? () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: _getPlanColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          'Get Started',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<BenefitItem> _getBenefits() {
    switch (widget.plan.type) {
      case 'candidate':
        if (widget.plan.planId == 'gold_plan') {
          return [
            BenefitItem(
              title: 'Enhanced Dashboard',
              description: 'Access advanced analytics, unlimited media uploads, and priority support.',
              icon: Icons.dashboard,
              color: Colors.amber,
            ),
            BenefitItem(
              title: 'Carousel Highlights',
              description: 'Get featured placement in the main carousel for maximum visibility.',
              icon: Icons.view_carousel,
              color: Colors.blue,
            ),
            BenefitItem(
              title: 'Push Notifications',
              description: 'Send targeted notifications to your supporters and followers.',
              icon: Icons.notifications_active,
              color: Colors.green,
            ),
            BenefitItem(
              title: 'Advanced Analytics',
              description: 'Track engagement, views, and interaction metrics in detail.',
              icon: Icons.analytics,
              color: Colors.purple,
            ),
          ];
        } else if (widget.plan.planId == 'platinum_plan') {
          return [
            BenefitItem(
              title: 'Platinum Highlight Banner',
              description: 'Exclusive top banner placement with premium styling and maximum visibility.',
              icon: Icons.diamond,
              color: Colors.purple,
            ),
            BenefitItem(
              title: 'Multiple Highlights',
              description: 'Create and manage multiple highlight banners simultaneously.',
              icon: Icons.flag,
              color: Colors.red,
            ),
            BenefitItem(
              title: 'Real-time Analytics',
              description: 'Monitor your campaign performance with live data and insights.',
              icon: Icons.show_chart,
              color: Colors.blue,
            ),
            BenefitItem(
              title: 'Admin Support',
              description: 'Direct access to our support team for personalized assistance.',
              icon: Icons.support_agent,
              color: Colors.green,
            ),
            BenefitItem(
              title: 'Custom Branding',
              description: 'Personalize your profile with custom colors and branding options.',
              icon: Icons.palette,
              color: Colors.orange,
            ),
          ];
        }
        break;
      case 'highlight':
        return [
          BenefitItem(
            title: 'Premium Banner Placement',
            description: 'Your banner appears in high-visibility positions across the platform.',
            icon: Icons.flag,
            color: Colors.blue,
          ),
          BenefitItem(
            title: 'Analytics Dashboard',
            description: 'Track banner performance, views, and engagement metrics.',
            icon: Icons.analytics,
            color: Colors.purple,
          ),
          BenefitItem(
            title: 'Custom Styling',
            description: 'Design your banner with custom colors, fonts, and layouts.',
            icon: Icons.palette,
            color: Colors.orange,
          ),
        ];
      case 'carousel':
        return [
          BenefitItem(
            title: 'Carousel Slots',
            description: 'Dedicated slots in the rotating carousel for consistent visibility.',
            icon: Icons.view_carousel,
            color: Colors.green,
          ),
          BenefitItem(
            title: 'Auto-rotation',
            description: 'Your content automatically rotates through the carousel cycle.',
            icon: Icons.refresh,
            color: Colors.blue,
          ),
          BenefitItem(
            title: 'Timing Controls',
            description: 'Customize when your content appears in the rotation.',
            icon: Icons.schedule,
            color: Colors.purple,
          ),
        ];
    }
    return [];
  }

  List<String> _getNextSteps() {
    switch (widget.plan.type) {
      case 'candidate':
        if (widget.plan.planId == 'gold_plan') {
          return [
            'Complete your candidate profile with photos and basic information',
            'Create your manifesto with detailed policies and promises',
            'Upload media content (photos, videos, documents)',
            'Set up your first highlight banner for visibility',
            'Check your analytics dashboard to track engagement',
          ];
        } else if (widget.plan.planId == 'platinum_plan') {
          return [
            'Your Platinum highlight banner is already live!',
            'Customize your profile branding and colors',
            'Create additional highlight banners for different messages',
            'Set up events and connect with supporters',
            'Monitor real-time analytics for campaign insights',
          ];
        }
        break;
      case 'highlight':
        return [
          'Design your highlight banner with compelling content',
          'Choose your target audience and placement preferences',
          'Set up analytics tracking for performance monitoring',
          'Monitor engagement and adjust your strategy',
        ];
      case 'carousel':
        return [
          'Configure your carousel content and timing preferences',
          'Set up analytics tracking for visibility metrics',
          'Monitor rotation performance and engagement',
          'Optimize content based on analytics insights',
        ];
    }
    return [];
  }

  Color _getPlanColor() {
    switch (widget.plan.planId) {
      case 'gold_plan':
        return Colors.amber;
      case 'platinum_plan':
        return Colors.purple;
      case 'highlight_plan':
        return Colors.blue;
      case 'carousel_plan':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Color> _getPlanGradientColors() {
    switch (widget.plan.planId) {
      case 'gold_plan':
        return [Colors.amber[400]!, Colors.amber[600]!];
      case 'platinum_plan':
        return [Colors.purple[400]!, Colors.purple[600]!];
      case 'highlight_plan':
        return [Colors.blue[400]!, Colors.blue[600]!];
      case 'carousel_plan':
        return [Colors.green[400]!, Colors.green[600]!];
      default:
        return [Colors.grey[400]!, Colors.grey[600]!];
    }
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
}

class BenefitItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  BenefitItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
