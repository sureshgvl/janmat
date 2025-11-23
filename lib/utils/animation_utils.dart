import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom page transitions for smooth navigation
class AppPageTransitions {
  /// Fade transition for modal dialogs
  static Route<T> fadeTransition<T>(Widget page, RouteSettings? settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide transition for main screens
  static Route<T> slideTransition<T>({
    required Widget page,
    RouteSettings? settings,
    bool fromLeft = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutQuart;

        final tween = Tween(begin: fromLeft ? -begin : begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Scale transition for modals
  static Route<T> scaleTransition<T>(Widget page, RouteSettings? settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

/// Custom scroll physics for smoother scrolling
class SmoothScrollPhysics extends ScrollPhysics {
  const SmoothScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset * 0.8; // Smoother scrolling
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (velocity.abs() < 100) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.pixels,
        0,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

/// Animated container with smooth transitions
class SmoothContainer extends StatefulWidget {
  const SmoothContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.fade,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;

  @override
  State<SmoothContainer> createState() => _SmoothContainerState();
}

enum AnimationType {
  fade,
  scale,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
}

class _SmoothContainerState extends State<SmoothContainer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = _getSlideAnimation().animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _controller.forward();
  }

  Tween<Offset> _getSlideAnimation() {
    switch (widget.animationType) {
      case AnimationType.slideUp:
        return Tween(begin: const Offset(0, 0.2), end: Offset.zero);
      case AnimationType.slideDown:
        return Tween(begin: const Offset(0, -0.2), end: Offset.zero);
      case AnimationType.slideLeft:
        return Tween(begin: const Offset(0.2, 0), end: Offset.zero);
      case AnimationType.slideRight:
        return Tween(begin: const Offset(-0.2, 0), end: Offset.zero);
      default:
        return Tween(begin: Offset.zero, end: Offset.zero);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        switch (widget.animationType) {
          case AnimationType.fade:
            return Opacity(
              opacity: _fadeAnimation.value,
              child: widget.child,
            );
          case AnimationType.scale:
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: widget.child,
              ),
            );
          case AnimationType.slideUp:
          case AnimationType.slideDown:
          case AnimationType.slideLeft:
          case AnimationType.slideRight:
            return SlideTransition(
              position: _slideAnimation,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: widget.child,
              ),
            );
          default:
            return Opacity(
              opacity: _fadeAnimation.value,
              child: widget.child,
            );
        }
      },
    );
  }
}

/// Smooth button animations
class SmoothButton extends StatefulWidget {
  const SmoothButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 0.95,
    this.curve = Curves.easeInOut,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Duration duration;
  final double scale;
  final Curve curve;

  @override
  State<SmoothButton> createState() => _SmoothButtonState();
}

class _SmoothButtonState extends State<SmoothButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// Animated counter for statistics
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOutCubic,
    this.style,
    this.formatter,
  });

  final int value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String Function(int)? formatter;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation =
        IntTween(begin: 0, end: widget.value).animate(_controller);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation =
          IntTween(begin: oldWidget.value, end: widget.value).animate(_controller);
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displayValue = widget.formatter?.call(_animation.value) ?? _animation.value.toString();
        return Text(
          displayValue,
          style: widget.style,
        );
      },
    );
  }
}

/// Smooth expanding content
class ExpandableContent extends StatefulWidget {
  const ExpandableContent({
    super.key,
    required this.header,
    required this.content,
    this.expanded = false,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final Widget header;
  final Widget content;
  final bool expanded;
  final Duration duration;
  final Curve curve;

  @override
  State<ExpandableContent> createState() => _ExpandableContentState();
}

class _ExpandableContentState extends State<ExpandableContent>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.expanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ExpandableContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.header,
        SizeTransition(
          sizeFactor: _animation,
          axis: Axis.vertical,
          child: widget.content,
        ),
      ],
    );
  }
}

/// Shake animation for error states
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakes = 3,
  });

  final Widget child;
  final Duration duration;
  final int shakes;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = TweenSequence<double>(
      List.generate(widget.shakes, (index) {
        return TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 10 * (index % 2 == 0 ? 1 : -1)),
          weight: 1,
        );
      }),
    ).animate(_controller);

    // Auto-start shake when widget loads
    _controller.forward();

    // Reset after animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse animation for highlights
class PulseAnimation extends StatefulWidget {
  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.minScale = 0.95,
    this.maxScale = 1.1,
    this.repeat = true,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Custom GetX navigation with smooth transitions
class SmoothNavigation {
  static void to(
    dynamic page, {
    Transition? transition,
    Duration? duration,
    Curve? curve,
  }) {
    transition ??= Transition.rightToLeft;
    duration ??= const Duration(milliseconds: 400);
    curve ??= Curves.easeInOutQuart;

    Get.to(
      page,
      transition: transition,
      duration: duration,
      curve: curve,
    );
  }

  static void back() {
    Get.back();
  }

  static void off(dynamic page) {
    Get.off(
      page,
      transition: Transition.fade,
      duration: const Duration(milliseconds: 300),
    );
  }

  static void offAll(dynamic page) {
    Get.offAll(
      page,
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 500),
    );
  }
}

/// Smooth animated list for dynamic content
class AnimatedListBuilder extends StatefulWidget {
  const AnimatedListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.initialItemCount = 0,
    this.duration = const Duration(milliseconds: 300),
  });

  final int itemCount;
  final int initialItemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Duration duration;

  @override
  State<AnimatedListBuilder> createState() => _AnimatedListBuilderState();
}

class _AnimatedListBuilderState extends State<AnimatedListBuilder> {
  late int _previousItemCount;

  @override
  void initState() {
    super.initState();
    _previousItemCount = widget.initialItemCount;
  }

  @override
  void didUpdateWidget(AnimatedListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _previousItemCount = oldWidget.itemCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const SmoothScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        final shouldAnimate = index >= _previousItemCount;
        return SmoothContainer(
          key: ValueKey(index),
          animationType: shouldAnimate ? AnimationType.slideUp : AnimationType.fade,
          duration: widget.duration,
          child: widget.itemBuilder(context, index),
        );
      },
    );
  }
}
