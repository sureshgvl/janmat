import 'package:flutter/material.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../models/candidate_model.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../common/whatsapp_image_viewer.dart';
import '../../../utils/app_logger.dart';

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
                            title: '${candidate.name} - Profile Photo',
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
                                      candidate.name[0].toUpperCase(),
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
                                  candidate.name[0].toUpperCase(),
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
                      candidate.name,
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

                        // Use MaharashtraUtils for ward name translation (same as BasicInfoView)
                        final translatedWard = MaharashtraUtils.getWardDisplayNameWithLocale(
                          candidate.wardId,
                          locale,
                        );

                        // Use translated ward if translation succeeded, otherwise use SQLite data or fallback
                        String displayWard;
                        if (translatedWard != candidate.wardId) {
                          // Translation succeeded
                          displayWard = translatedWard;
                        } else if (wardName?.isNotEmpty == true && wardName != candidate.wardId) {
                          // Use cleaned SQLite data if available and different from raw wardId
                          displayWard = wardName!;
                        } else {
                          // Fallback to wardId
                          displayWard = candidate.wardId;
                        }

                        AppLogger.candidate('🏛️ [ProfileHeader] Ward name resolution:');
                        AppLogger.candidate('   wardId: ${candidate.wardId}');
                        AppLogger.candidate('   locale: $locale');
                        AppLogger.candidate('   translatedWard: $translatedWard');
                        AppLogger.candidate('   wardName param: $wardName');
                        AppLogger.candidate('   displayWard: $displayWard');

                        // Use MaharashtraUtils for district name translation
                        final translatedDistrict = MaharashtraUtils.getDistrictDisplayNameWithLocale(
                          candidate.districtId,
                          locale,
                        );
                        final displayDistrict = translatedDistrict != candidate.districtId
                          ? translatedDistrict
                          : (districtName ?? candidate.districtId);


                        // Construct final text
                        final finalText = '$displayWard • $displayDistrict';

                        // Debug logs
                        AppLogger.candidate('🔍 [ProfileHeader] Location Display Debug:');
                        AppLogger.candidate('   Locale: $locale');
                        AppLogger.candidate('   Ward Display: "$displayWard" (translated: ${translatedWard != candidate.wardId ? "YES" : "NO"}, from SQLite: ${wardName != null ? "YES" : "NO"})');
                        AppLogger.candidate('   District Display: "$displayDistrict" (translated: ${translatedDistrict != candidate.districtId ? "YES" : "NO"})');
                        AppLogger.candidate('   Final Text: "$finalText"');

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

