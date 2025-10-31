import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../highlight/models/highlight_model.dart';
import 'image_handler.dart';

class HighlightBannerSection extends StatelessWidget {
  final Highlight? currentHighlight;
  final bool isBannerActive;
  final int availableSeats;
  final String? localBannerImagePath;
  final bool isUploadingImage;
  final VoidCallback onPickImage;
  final Widget currentSymbol;

  const HighlightBannerSection({
    super.key,
    required this.currentHighlight,
    required this.isBannerActive,
    required this.availableSeats,
    required this.localBannerImagePath,
    required this.isUploadingImage,
    required this.onPickImage,
    required this.currentSymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with light gray background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Highlight Banner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
                // Available Seats Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: availableSeats > 0 ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: availableSeats > 0 ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        availableSeats > 0 ? Icons.event_available : Icons.event_busy,
                        size: 14,
                        color: availableSeats > 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${availableSeats} seats left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: availableSeats > 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Status Toggle (from actual highlight document) - Always visible
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isBannerActive ? Icons.visibility : Icons.visibility_off,
                      color: isBannerActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBannerActive ? 'Active - Visible on home screen' : 'Inactive - Hidden from home screen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isBannerActive ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isBannerActive && currentHighlight != null) ...[
            const SizedBox(height: 24),

            // End Date Display (from actual highlight document)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          '${currentHighlight!.endDate.day}/${currentHighlight!.endDate.month}/${currentHighlight!.endDate.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Image Display (from actual highlight document)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image, color: Colors.purple.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Current Banner Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ImageHandler.getBannerImageWidget(
                      localBannerImagePath: localBannerImagePath,
                      firebaseImageUrl: currentHighlight!.imageUrl,
                      isUploadingImage: isUploadingImage,
                      onPickImage: onPickImage,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actual Banner View (from home screen)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.view_carousel, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Banner View (Home Screen)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Actual banner widget from home screen
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade100.withValues(alpha: 0.7),
                          Colors.green.shade100.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background image - Priority: Local > Firebase
                        if (localBannerImagePath != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(localBannerImagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(),
                              ),
                            ),
                          )
                        else if (currentHighlight!.imageUrl != null && currentHighlight!.imageUrl!.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                currentHighlight!.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(),
                              ),
                            ),
                          ),

                        // Party symbol overlay
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: currentSymbol,
                          ),
                        ),

                        // Arrow button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF1976D2),
                              size: 20,
                            ),
                          ),
                        ),

                        // Candidate name and party
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentHighlight!.candidateName ?? 'Candidate Name',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currentHighlight!.party ?? 'Party',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
