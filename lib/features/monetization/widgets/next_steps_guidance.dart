import 'package:flutter/material.dart';
import '../../../models/plan_model.dart';

class NextStepsGuidance extends StatefulWidget {
  final SubscriptionPlan plan;
  final int validityDays;
  final VoidCallback? onCompleteProfile;
  final VoidCallback? onCreateManifesto;
  final VoidCallback? onUploadMedia;
  final VoidCallback? onCreateHighlight;
  final VoidCallback? onViewAnalytics;

  const NextStepsGuidance({
    super.key,
    required this.plan,
    required this.validityDays,
    this.onCompleteProfile,
    this.onCreateManifesto,
    this.onUploadMedia,
    this.onCreateHighlight,
    this.onViewAnalytics,
  });

  @override
  State<NextStepsGuidance> createState() => _NextStepsGuidanceState();
}

class _NextStepsGuidanceState extends State<NextStepsGuidance>
    with TickerProviderStateMixin {
  late List<AnimationController> _stepControllers;
  late List<Animation<double>> _stepAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final steps = _getSteps();
    _stepControllers = List.generate(
      steps.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _stepAnimations = _stepControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    // Start animations with staggered delay
    for (int i = 0; i < _stepControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _stepControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return AnimatedBuilder(
              animation: _stepAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _stepAnimations[index].value) * 30),
                  child: Opacity(
                    opacity: _stepAnimations[index].value,
                    child: _buildStepCard(step, index),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 24),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flag_outlined,
              color: _getPlanColor(),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Your Next Steps',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Follow these steps to maximize your ${widget.plan.name} plan benefits',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(StepItem step, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: step.isCompleted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.isCompleted ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: step.isCompleted ? Colors.green : step.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: step.isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                if (step.buttonText != null && !step.isCompleted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: step.onPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: step.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        step.buttonText!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (step.isCompleted)
            Icon(
              Icons.verified,
              color: Colors.green[600],
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = _getSteps();
    final completedSteps = steps.where((step) => step.isCompleted).length;
    final progress = completedSteps / steps.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Setup Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$completedSteps of ${steps.length} completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getPlanColor()),
        ),
        const SizedBox(height: 8),
        Text(
          progress == 1.0
              ? '🎉 All set! You\'re ready to engage with voters.'
              : 'Complete these steps to get the most out of your plan.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<StepItem> _getSteps() {
    switch (widget.plan.type) {
      case 'candidate':
        if (widget.plan.planId == 'gold_plan') {
          return [
            StepItem(
              title: 'Complete Your Profile',
              description: 'Add your photo, contact details, and basic information to build trust with voters.',
              color: Colors.blue,
              buttonText: 'Complete Profile',
              onPressed: widget.onCompleteProfile,
              isCompleted: false, // This would be determined by actual profile completion status
            ),
            StepItem(
              title: 'Create Your Manifesto',
              description: 'Write your policies, promises, and vision for the constituency.',
              color: Colors.green,
              buttonText: 'Create Manifesto',
              onPressed: widget.onCreateManifesto,
              isCompleted: false,
            ),
            StepItem(
              title: 'Upload Media Content',
              description: 'Add photos, videos, and documents to showcase your work and achievements.',
              color: Colors.orange,
              buttonText: 'Upload Media',
              onPressed: widget.onUploadMedia,
              isCompleted: false,
            ),
            StepItem(
              title: 'Create Highlight Banner',
              description: 'Design an eye-catching banner to appear in the main carousel.',
              color: Colors.purple,
              buttonText: 'Create Highlight',
              onPressed: widget.onCreateHighlight,
              isCompleted: false,
            ),
            StepItem(
              title: 'Monitor Analytics',
              description: 'Track your profile views, engagement, and campaign performance.',
              color: Colors.teal,
              buttonText: 'View Analytics',
              onPressed: widget.onViewAnalytics,
              isCompleted: false,
            ),
          ];
        } else if (widget.plan.planId == 'platinum_plan') {
          return [
            StepItem(
              title: 'Your Platinum Banner is Live!',
              description: 'Your premium highlight banner is already active with maximum visibility.',
              color: Colors.purple,
              isCompleted: true,
            ),
            StepItem(
              title: 'Customize Profile Branding',
              description: 'Set up your custom colors, logo, and branding elements.',
              color: Colors.blue,
              buttonText: 'Customize Branding',
              onPressed: widget.onCompleteProfile,
              isCompleted: false,
            ),
            StepItem(
              title: 'Create Additional Highlights',
              description: 'Design multiple highlight banners for different campaign messages.',
              color: Colors.green,
              buttonText: 'Create Highlights',
              onPressed: widget.onCreateHighlight,
              isCompleted: false,
            ),
            StepItem(
              title: 'Set Up Events',
              description: 'Schedule and promote your campaign events and rallies.',
              color: Colors.orange,
              buttonText: 'Create Events',
              onPressed: () {}, // Would navigate to events section
              isCompleted: false,
            ),
            StepItem(
              title: 'Monitor Real-time Analytics',
              description: 'Access live data and insights about your campaign performance.',
              color: Colors.teal,
              buttonText: 'View Analytics',
              onPressed: widget.onViewAnalytics,
              isCompleted: false,
            ),
          ];
        }
        break;
      case 'highlight':
        return [
          StepItem(
            title: 'Design Your Banner',
            description: 'Create an eye-catching banner with your message and branding.',
            color: Colors.blue,
            buttonText: 'Design Banner',
            onPressed: widget.onCreateHighlight,
            isCompleted: false,
          ),
          StepItem(
            title: 'Set Target Audience',
            description: 'Choose which voters and areas will see your banner.',
            color: Colors.green,
            buttonText: 'Configure Targeting',
            onPressed: () {},
            isCompleted: false,
          ),
          StepItem(
            title: 'Monitor Performance',
            description: 'Track views, clicks, and engagement on your banner.',
            color: Colors.purple,
            buttonText: 'View Analytics',
            onPressed: widget.onViewAnalytics,
            isCompleted: false,
          ),
        ];
      case 'carousel':
        return [
          StepItem(
            title: 'Prepare Content',
            description: 'Create or select the content for your carousel placement.',
            color: Colors.blue,
            buttonText: 'Prepare Content',
            onPressed: widget.onUploadMedia,
            isCompleted: false,
          ),
          StepItem(
            title: 'Configure Timing',
            description: 'Set when your content appears in the carousel rotation.',
            color: Colors.green,
            buttonText: 'Set Timing',
            onPressed: () {},
            isCompleted: false,
          ),
          StepItem(
            title: 'Track Performance',
            description: 'Monitor how your carousel content performs over time.',
            color: Colors.purple,
            buttonText: 'View Analytics',
            onPressed: widget.onViewAnalytics,
            isCompleted: false,
          ),
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
}

class StepItem {
  final String title;
  final String description;
  final Color color;
  final String? buttonText;
  final VoidCallback? onPressed;
  final bool isCompleted;

  StepItem({
    required this.title,
    required this.description,
    required this.color,
    this.buttonText,
    this.onPressed,
    this.isCompleted = false,
  });
}
