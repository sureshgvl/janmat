import 'package:flutter/material.dart';
import '../../../models/plan_model.dart';

class FeatureUnlockAnimation extends StatefulWidget {
  final SubscriptionPlan plan;
  final List<String> unlockedFeatures;
  final VoidCallback? onAnimationComplete;

  const FeatureUnlockAnimation({
    super.key,
    required this.plan,
    required this.unlockedFeatures,
    this.onAnimationComplete,
  });

  @override
  State<FeatureUnlockAnimation> createState() => _FeatureUnlockAnimationState();
}

class _FeatureUnlockAnimationState extends State<FeatureUnlockAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _featureControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _featureControllers = List.generate(
      widget.unlockedFeatures.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    _scaleAnimations = _featureControllers.map((controller) {
      return Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _opacityAnimations = _featureControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
    }).toList();

    _slideAnimations = _featureControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    // Start animations with staggered timing
    for (int i = 0; i < _featureControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted) {
          _featureControllers[i].forward();
        }
      });
    }

    // Call completion callback after all animations finish
    Future.delayed(
      Duration(milliseconds: widget.unlockedFeatures.length * 300 + 1000),
      () {
        widget.onAnimationComplete?.call();
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _featureControllers) {
      controller.dispose();
    }
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
          'Features Unlocked!',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildFeaturesGrid(),
              const SizedBox(height: 32),
              _buildCelebrationMessage(),
            ],
          ),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPlanIcon(),
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.plan.name} Plan Features',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Now Available in Your Dashboard',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: widget.unlockedFeatures.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _featureControllers[index],
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: ScaleTransition(
                scale: _scaleAnimations[index],
                child: FadeTransition(
                  opacity: _opacityAnimations[index],
                  child: _buildFeatureCard(widget.unlockedFeatures[index], index),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(String featureName, int index) {
    final featureData = _getFeatureData(featureName);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: featureData.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              featureData.icon,
              color: featureData.color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            featureData.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            featureData.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration,
            color: Colors.amber[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '🎉 Congratulations!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All these features are now unlocked and ready to use. Start engaging with voters and building your campaign presence!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  FeatureData _getFeatureData(String featureName) {
    // Map feature names to display data
    switch (featureName.toLowerCase()) {
      case 'manifesto':
        return FeatureData(
          title: 'Manifesto',
          description: 'Create detailed policies and promises',
          icon: Icons.description,
          color: Colors.blue,
        );
      case 'media':
        return FeatureData(
          title: 'Media Upload',
          description: 'Share photos, videos, and documents',
          icon: Icons.photo_library,
          color: Colors.green,
        );
      case 'analytics':
        return FeatureData(
          title: 'Analytics',
          description: 'Track engagement and performance',
          icon: Icons.analytics,
          color: Colors.purple,
        );
      case 'events':
        return FeatureData(
          title: 'Events',
          description: 'Schedule and promote campaign events',
          icon: Icons.event,
          color: Colors.orange,
        );
      case 'achievements':
        return FeatureData(
          title: 'Achievements',
          description: 'Showcase your accomplishments',
          icon: Icons.emoji_events,
          color: Colors.amber,
        );
      case 'contact':
        return FeatureData(
          title: 'Contact Info',
          description: 'Enhanced contact and social links',
          icon: Icons.contact_phone,
          color: Colors.teal,
        );
      case 'highlight':
        return FeatureData(
          title: 'Highlight Banner',
          description: 'Premium banner placement',
          icon: Icons.flag,
          color: Colors.red,
        );
      case 'carousel':
        return FeatureData(
          title: 'Carousel',
          description: 'Featured carousel placement',
          icon: Icons.view_carousel,
          color: Colors.indigo,
        );
      case 'branding':
        return FeatureData(
          title: 'Custom Branding',
          description: 'Personalized colors and logo',
          icon: Icons.palette,
          color: Colors.pink,
        );
      case 'support':
        return FeatureData(
          title: 'Priority Support',
          description: 'Direct access to support team',
          icon: Icons.support_agent,
          color: Colors.cyan,
        );
      default:
        return FeatureData(
          title: featureName,
          description: 'New feature unlocked',
          icon: Icons.star,
          color: Colors.grey,
        );
    }
  }

  List<String> _getDefaultFeatures() {
    switch (widget.plan.type) {
      case 'candidate':
        if (widget.plan.planId == 'gold_plan') {
          return ['manifesto', 'media', 'analytics', 'events', 'achievements', 'contact', 'carousel'];
        } else if (widget.plan.planId == 'platinum_plan') {
          return ['highlight', 'branding', 'support', 'analytics'];
        }
        break;
      case 'highlight':
        return ['highlight', 'analytics'];
      case 'carousel':
        return ['carousel', 'analytics'];
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

class FeatureData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  FeatureData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
