import 'package:flutter/material.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../models/candidate_model.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../common/whatsapp_image_viewer.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Candidate candidate;
  final bool hasSponsoredBanner;
  final bool hasPremiumBadge;
  final bool isUploadingPhoto;
  final String Function() getCurrentLocale;
  final String? wardName;
  final String? districtName;
  final String? bodyName;

  const ProfileHeaderWidget({
    super.key,
    required this.candidate,
    required this.hasSponsoredBanner,
    required this.hasPremiumBadge,
    required this.isUploadingPhoto,
    required this.getCurrentLocale,
    this.wardName,
    this.districtName,
    this.bodyName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sponsored Ad Banner
        if (hasSponsoredBanner)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                CandidateTranslations.tr('sponsored'),
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Profile Header Section
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: () {
                  if (candidate.photo != null && candidate.photo!.isNotEmpty) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black,
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return WhatsAppImageViewer(
                            imageUrl: candidate.photo!,
                            title: candidate.basicInfo!.fullName!,
                          );
                        },
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: candidate.photo != null &&
                                candidate.photo!.isNotEmpty
                            ? Image.network(
                                candidate.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      candidate.basicInfo!.fullName![0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  candidate.basicInfo!.fullName![0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (isUploadingPhoto)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Blue Tick Badge for Premium Candidates
                    if (hasPremiumBadge)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.basicInfo!.fullName!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      SymbolUtils.getPartyFullNameWithLocale(
                        candidate.party,
                        getCurrentLocale(),
                      ),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final locale = Localizations.localeOf(context).languageCode;

                        String displayWard;
                          if (wardName?.isNotEmpty == true &&
                              wardName != candidate.location.wardId) {
                            // Use cleaned SQLite data if available and different from raw wardId
                            displayWard = wardName!;
                          } else {
                            // Fallback to wardId
                            displayWard = candidate.location.wardId ?? '';
                          }

                          // Use MaharashtraUtils for district name translation
                          final translatedDistrict =
                              MaharashtraUtils.getDistrictDisplayNameWithLocale(
                                candidate.location.districtId ?? '',
                                locale,
                              );
                          final displayDistrict =
                              translatedDistrict !=
                                  candidate.location.districtId
                              ? translatedDistrict
                              : (districtName ?? candidate.location.districtId);

                          // Construct final text: "Ward name, District name"
                          final finalText = '$displayWard, $displayDistrict';

                        return Text(
                          finalText,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
