import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/candidate_model.dart';
import '../../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../../utils/symbol_utils.dart';
import '../../../../utils/maharashtra_utils.dart';

class InfoTab extends StatelessWidget {
  final Candidate candidate;
  final String Function(String) getPartySymbolPath;
  final String Function(DateTime) formatDate;
  final String? wardName;
  final String? districtName;
  final String? bodyName;

  const InfoTab({
    super.key,
    required this.candidate,
    required this.getPartySymbolPath,
    required this.formatDate,
    this.wardName,
    this.districtName,
    this.bodyName,
  });

  // Helper method to translate gender values
  String _translateGender(String? gender, BuildContext context) {
    if (gender == null) return CandidateLocalizations.of(context)!.notSpecified;

    switch (gender.toLowerCase()) {
      case 'male':
      case 'पुरुष':
        return CandidateLocalizations.of(context)!.male;
      case 'female':
      case 'स्त्री':
        return CandidateLocalizations.of(context)!.female;
      case 'other':
      case 'इतर':
        return CandidateLocalizations.of(context)!.other;
      default:
        return gender;
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Party Information with Symbol
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 64, // 80% of profile picture size (80 * 0.8 = 64)
                        height: 64, // 80% of profile picture size (80 * 0.8 = 64)
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: SymbolUtils.getSymbolImageProvider(
                              getPartySymbolPath(candidate.party),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        (candidate.party.toLowerCase().contains('independent') ||
                                candidate.party.trim().isEmpty) &&
                            candidate.symbolName?.isNotEmpty == true
                            ? candidate.symbolName!
                            : SymbolUtils.getPartySymbolNameWithLocale(
                                candidate.party,
                                Localizations.localeOf(context).languageCode,
                              ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1f2937),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SymbolUtils.getPartyFullNameWithLocale(
                          candidate.party,
                          Localizations.localeOf(context).languageCode,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
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

                          // Use MaharashtraUtils for district name translation
                          final translatedDistrict = MaharashtraUtils.getDistrictDisplayNameWithLocale(
                            candidate.districtId,
                            locale,
                          );
                          final displayDistrict = translatedDistrict != candidate.districtId
                            ? translatedDistrict
                            : (districtName ?? candidate.districtId);

                          // Construct final text: "Ward name, District name"
                          final finalText = '$displayWard, $displayDistrict';

                          // Debug logs
                          debugPrint('🔍 [InfoTab] Location Display Debug:');
                          debugPrint('   Locale: $locale');
                          debugPrint('   Ward Display: "$displayWard" (translated: ${translatedWard != candidate.wardId ? "YES" : "NO"}, from SQLite: ${wardName != null ? "YES" : "NO"})');
                          debugPrint('   District Display: "$displayDistrict" (translated: ${translatedDistrict != candidate.districtId ? "YES" : "NO"})');
                          debugPrint('   Final Text: "$finalText"');

                          return Text(
                            finalText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                          );
                        },
                      ),
                      //const SizedBox(height: 4),
                      // Text(
                      //   CandidateLocalizations.of(context)!.translate(
                      //     'joinedDate',
                      //     args: {
                      //       'date': candidate.formatDate(
                      //         candidate.createdAt,
                      //       ),
                      //     },
                      //   ),
                      //   style: const TextStyle(
                      //     fontSize: 12,
                      //     color: Color(0xFF9ca3af),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          // Events (if available)
          if (candidate.extraInfo?.events != null &&
              candidate.extraInfo!.events!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event_available_outlined,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'upcomingEvents'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...candidate.extraInfo!.events!.map(
                    (event) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1f2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (event.date.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        event.date,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6b7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (event.description != null &&
                                    event.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    event.description!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Personal Information (Age, Gender, Education, Address)
          if ((candidate.extraInfo?.basicInfo?.age != null) ||
              (candidate.extraInfo?.basicInfo?.gender != null) ||
              (candidate.extraInfo?.basicInfo?.education != null) ||
              (candidate.extraInfo?.contact?.address != null)) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person_pin_outlined,
                            color: Colors.purple.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          CandidateLocalizations.of(context)!.personalInformation,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              CandidateLocalizations.of(context)!.fullName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          candidate.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Age and Gender Row
                  if (candidate.extraInfo?.basicInfo?.age != null ||
                      candidate.extraInfo?.basicInfo?.gender !=
                          null) ...[
                    Row(
                      children: [
                        if (candidate.extraInfo?.basicInfo?.age !=
                            null) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CandidateLocalizations.of(context)!.age,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${candidate.extraInfo!.basicInfo!.age}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1f2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (candidate.extraInfo?.basicInfo?.gender !=
                              null)
                            const SizedBox(width: 12),
                        ],
                        if (candidate.extraInfo?.basicInfo?.gender !=
                            null) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CandidateLocalizations.of(context)!.gender,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _translateGender(candidate.extraInfo!.basicInfo!.gender, context),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1f2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Education
                  if (candidate.extraInfo?.basicInfo?.education !=
                      null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CandidateLocalizations.of(context)!.education,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            candidate.extraInfo!.basicInfo!.education!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Address
                  if (candidate.extraInfo?.contact?.address != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CandidateLocalizations.of(context)!.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            candidate.extraInfo!.contact!.address!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1f2937),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

