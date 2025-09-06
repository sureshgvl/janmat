import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color backgroundColor;
  final double opacity;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.backgroundColor = Colors.black,
    this.opacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // Your screen content

        if (isLoading)
          Container(
            color: backgroundColor.withOpacity(opacity),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
