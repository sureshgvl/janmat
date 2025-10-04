import 'package:flutter/material.dart';
import '../../../models/candidate_model.dart';
import '../highlight_config.dart';

// Preview Section Widget
// Follows Single Responsibility Principle - handles only banner preview display
// Matches the exact appearance of HighlightBanner from home screen

class PreviewSection extends StatelessWidget {
  final HighlightConfig config;
  final Candidate candidate;

  const PreviewSection({
    super.key,
    required this.config,
    required this.candidate,
  });

  // Helper method to get gradient colors based on banner style
  static List<Color> _getBannerGradient(String? bannerStyle) {
    switch (bannerStyle) {
      case 'premium':
        return [Colors.blue.shade600, Colors.blue.shade800];
      case 'elegant':
        return [Colors.purple.shade600, Colors.purple.shade800];
      case 'bold':
        return [Colors.red.shade600, Colors.red.shade800];
      case 'minimal':
        return [Colors.grey.shade600, Colors.grey.shade800];
      default:
        return [Colors.blue.shade600, Colors.blue.shade800];
    }
  }

  // Helper method to get call to action text
  static String _getCallToAction(String? callToAction) {
    return callToAction ?? 'View Profile';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.preview, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  'Banner Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main banner section - matches HighlightBanner exactly
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Background with gradient - matches HighlightBanner
                    Container(
                      height: 192, // Same height as home screen banner
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getBannerGradient(config.bannerStyle),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      // Placeholder for background image (would be loaded from config)
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getBannerGradient(config.bannerStyle),
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),

                    // Highlight Badge - top left like home screen
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9933), // Saffron color
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '⭐ HIGHLIGHT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom gradient overlay - matches home screen
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content at bottom - matches home screen layout
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Row(
                        children: [
                          // Candidate info on left
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  candidate.name ?? 'Candidate Name',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Show custom message or party name
                                Text(
                                  config.customMessage.isNotEmpty
                                      ? '"${config.customMessage}"'
                                      : candidate.party ?? 'Political Party',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    fontStyle: config.customMessage.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Party symbol on right - matches home screen
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Impression tracking overlay (invisible)
                    Positioned.fill(child: Container(color: Colors.transparent)),
                  ],
                ),
              ),
            ),

            // View Profile button below banner - matches home screen
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {}, // Preview only - no action
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976d2), // Primary blue
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _getCallToAction(config.callToAction),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              'This is exactly how your banner will appear on the home screen',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

