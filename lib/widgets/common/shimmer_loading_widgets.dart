import 'package:flutter/material.dart';

/// Loading widget for candidate profile - uses pulsing animation
class CandidateProfileSkeletonLoader extends StatefulWidget {
  const CandidateProfileSkeletonLoader({super.key});

  @override
  State<CandidateProfileSkeletonLoader> createState() => _CandidateProfileSkeletonLoaderState();
}

class _CandidateProfileSkeletonLoaderState extends State<CandidateProfileSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Column(
          children: [
            // Profile header area
            Container(
              height: 220,
              color: Colors.grey[200],
            ),

            // Stats section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatSkeleton(),
                  _buildStatSkeleton(),
                  _buildStatSkeleton(),
                ],
              ),
            ),

            // Tab bar
            Container(
              height: 50,
              color: Colors.grey[200],
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
            ),

            const SizedBox(height: 16),

            // Content area
            Expanded(
              child: ListView(
                children: [
                  _buildInfoTileSkeleton(),
                  _buildInfoTileSkeleton(),
                  _buildInfoTileSkeleton(),
                  _buildInfoTileSkeleton(),
                  _buildInfoTileSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildInfoTileSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// Loading widget for candidate cards - uses pulsing animation
class CandidateCardSkeletonLoader extends StatefulWidget {
  const CandidateCardSkeletonLoader({super.key});

  @override
  State<CandidateCardSkeletonLoader> createState() => _CandidateCardSkeletonLoaderState();
}

class _CandidateCardSkeletonLoaderState extends State<CandidateCardSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey[200],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.grey[200],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey[200],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic skeleton rectangle with pulsing animation
class PulsingSkeleton extends StatefulWidget {
  const PulsingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4.0,
    this.color = const Color(0xFFE0E0E0),
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color color;

  @override
  State<PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<PulsingSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

/// Skeleton text lines with pulsing animation
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    required this.width,
    this.height = 14.0,
    this.lines = 1,
    this.lineSpacing = 8.0,
  });

  final double width;
  final double height;
  final int lines;
  final double lineSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Container(
          margin: EdgeInsets.only(bottom: index < lines - 1 ? lineSpacing : 0),
          child: PulsingSkeleton(
            width: index == lines - 1 ? width * 0.7 : width, // Last line shorter
            height: height,
          ),
        ),
      ),
    );
  }
}
