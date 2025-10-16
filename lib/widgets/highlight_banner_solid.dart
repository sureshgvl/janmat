import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../features/home/controllers/highlight_banner_controller.dart';
import '../features/home/models/highlight_banner_model.dart';
import '../utils/symbol_utils.dart';

class HighlightBannerSolid extends StatefulWidget {
  final String districtId;
  final String bodyId;
  final String wardId;
  final bool showViewMoreButton;

  const HighlightBannerSolid({
    super.key,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
    this.showViewMoreButton = false,
  });

  @override
  State<HighlightBannerSolid> createState() => _HighlightBannerSolidState();
}

class _HighlightBannerSolidState extends State<HighlightBannerSolid> {
  late final HighlightBannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      HighlightBannerController(),
      tag: '${widget.districtId}_${widget.bodyId}_${widget.wardId}_banner',
    );
    _loadBanner();
  }

  @override
  void didUpdateWidget(HighlightBannerSolid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.districtId != widget.districtId ||
        oldWidget.bodyId != widget.bodyId ||
        oldWidget.wardId != widget.wardId) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    _controller.loadBanner(
      districtId: widget.districtId,
      bodyId: widget.bodyId,
      wardId: widget.wardId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.bannerState.value;

      if (state.isLoading) {
        return Column(
          children: [
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 24),
          ],
        );
      }

      if (state.bannerData == null) {
        return const SizedBox.shrink();
      }

      return _buildBanner(context, state.bannerData!);
    });
  }

  Widget _buildBanner(BuildContext context, HighlightBannerData bannerData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: GestureDetector(
        onTap: _controller.onBannerTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      Colors.blue.shade900.withValues(alpha: 0.3),
                      Colors.green.shade900.withValues(alpha: 0.3),
                    ]
                  : [
                      Colors.blue.shade100.withValues(alpha: 0.7),
                      Colors.green.shade100.withValues(alpha: 0.7),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Stack(
            children: [
              // Main content (image only)
              SizedBox(
                width: double.infinity,
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCandidateImage(bannerData),
                ),
              ),

              // Floating party symbol (upper left)
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
                  child: ClipOval(
                    child: Image.asset(
                      SymbolUtils.getPartySymbolPath(bannerData.candidateParty ?? 'independent'),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.star,
                          size: 25,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Floating arrow button (right side)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateImage(HighlightBannerData bannerData) {
    return bannerData.candidateProfileImageUrl != null
        ? Image.network(
            bannerData.candidateProfileImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.grey,
                ),
              );
            },
          )
        : Container(
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.person,
              size: 48,
              color: Colors.grey,
            ),
          );
  }
}