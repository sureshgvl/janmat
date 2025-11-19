import 'package:flutter/material.dart';

/// Forces portrait layout on web/desktop by constraining width to mobile dimensions
class PortraitWrapper extends StatelessWidget {
  final Widget child;

  const PortraitWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On desktop/web browsers (width > 600), force mobile width
        if (constraints.maxWidth > 600) {
          return Center(
            child: Container(
              width: 430, // Mobile portrait width (increased from 390 for better touch targets)
              constraints: const BoxConstraints(
                minHeight: 932, // iPhone 14 Pro height for reference
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: child,
              ),
            ),
          );
        } else {
          // Mobile devices - use full screen
          return child;
        }
      },
    );
  }
}
