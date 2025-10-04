import 'package:flutter/material.dart';
import '../../../models/candidate_model.dart';
import '../../../../../../utils/symbol_utils.dart';
import '../../../../../../utils/maharashtra_utils.dart';
import '../../../../../../utils/number_localization_utils.dart';
import '../../../../../../features/common/whatsapp_image_viewer.dart';
import '../../../../../../l10n/features/candidate/candidate_localizations.dart';

/// BasicInfoView - Displays candidate basic information in read-only mode
/// Follows Single Responsibility Principle: Only responsible for displaying data
class BasicInfoView extends StatelessWidget {
  final Candidate candidate;
  final String Function(String) getPartySymbolPath;
  final String? wardName;
  final String? districtName;
  final String? bodyName;

  const BasicInfoView({
    super.key,
    required this.candidate,
    required this.getPartySymbolPath,
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
    // Debug log the candidate data being displayed
    debugPrint('📄 BasicInfoView - Displaying candidate: ${candidate.name}');
    debugPrint('   extraInfo exists: ${candidate.extraInfo != null}');
    debugPrint('   basicInfo exists: ${candidate.extraInfo?.basicInfo != null}');
    debugPrint('   profession: ${candidate.extraInfo?.basicInfo?.profession}');
    debugPrint('   languages: ${candidate.extraInfo?.basicInfo?.languages}');
    debugPrint('   experienceYears: ${candidate.extraInfo?.basicInfo?.experienceYears}');
    debugPrint('   previousPositions: ${candidate.extraInfo?.basicInfo?.previousPositions}');
    debugPrint('   address: ${candidate.extraInfo?.contact?.address}');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CandidateLocalizations.of(context)!.personalInformation,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Photo and Name Section
            Row(
              children: [
                // Profile Photo
                GestureDetector(
                  onTap: candidate.photo != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WhatsAppImageViewer(
                                imageUrl: candidate.photo!,
                                title: '${candidate.name}\'s Profile Photo',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: candidate.photo != null
                        ? NetworkImage(candidate.photo!)
                        : null,
                    child: candidate.photo == null
                        ? Text(
                            candidate.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidate.party.toLowerCase().contains('independent') ||
                                          candidate.party.trim().isEmpty
                                      ? CandidateLocalizations.of(context)!.independentCandidate
                                            : candidate.party,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: candidate.party.toLowerCase().contains('independent') ||
                                            candidate.party.trim().isEmpty
                                        ? Colors.grey.shade700
                                        : Colors.blue,
                                    fontWeight: candidate.party.toLowerCase().contains('independent') ||
                                            candidate.party.trim().isEmpty
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  CandidateLocalizations.of(context)!.symbolLabel(
                                    symbol: candidate.party.toLowerCase().contains('independent') || candidate.party.trim().isEmpty
                                      ? (candidate.symbolName ?? CandidateLocalizations.of(context)!.notSpecified)
                                      : SymbolUtils.getPartySymbolNameWithLocale(candidate.party, Localizations.localeOf(context).languageCode)
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
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
              ],
            ),
            const SizedBox(height: 16),

            // Display additional info fields
            if (candidate.extraInfo != null) ...[
              if (candidate.extraInfo!.basicInfo?.age != null ||
                  candidate.extraInfo!.basicInfo?.gender != null) ...[
                Row(
                  children: [
                    if (candidate.extraInfo!.basicInfo?.age != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CandidateLocalizations.of(context)!.age,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              candidate.extraInfo!.basicInfo!.age?.toLocalizedString(context) ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (candidate.extraInfo!.basicInfo?.age != null &&
                        candidate.extraInfo!.basicInfo?.gender != null)
                      const SizedBox(width: 16),
                    if (candidate.extraInfo!.basicInfo?.gender != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CandidateLocalizations.of(context)!.gender,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _translateGender(candidate.extraInfo!.basicInfo!.gender, context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (candidate.extraInfo!.basicInfo?.education != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.education,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      candidate.extraInfo!.basicInfo!.education!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (candidate.extraInfo!.basicInfo?.profession != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.profession,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      candidate.extraInfo!.basicInfo!.profession!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (candidate.extraInfo!.basicInfo?.languages != null &&
                  candidate.extraInfo!.basicInfo!.languages!.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.languages,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      candidate.extraInfo!.basicInfo!.languages!.join(', '),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (candidate.extraInfo!.basicInfo?.experienceYears != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.experienceYears,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      candidate.extraInfo!.basicInfo!.experienceYears?.toLocalizedString(context) ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (candidate.extraInfo!.basicInfo?.previousPositions != null &&
                  candidate.extraInfo!.basicInfo!.previousPositions!.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.previousPositions,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      candidate.extraInfo!.basicInfo!.previousPositions!.join(', '),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (candidate.extraInfo!.contact?.address != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.address,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      candidate.extraInfo!.contact!.address!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],

            // City and Ward
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CandidateLocalizations.of(context)!.city,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Builder(
                        builder: (context) {
                          final locale = Localizations.localeOf(context).languageCode;
                          final translatedDistrict = MaharashtraUtils.getDistrictDisplayNameWithLocale(
                            candidate.districtId,
                            locale,
                          );
                          debugPrint('🗺️ BasicInfoView - District translation:');
                          debugPrint('   districtId: ${candidate.districtId}');
                          debugPrint('   locale: $locale');
                          debugPrint('   districtName from SQLite: $districtName');
                          debugPrint('   translatedDistrict: $translatedDistrict');

                          // Use translated district, fallback to SQLite cache, then raw ID
                          final displayDistrict = translatedDistrict != candidate.districtId
                            ? translatedDistrict
                            : (districtName ?? candidate.districtId);

                          return Text(
                            displayDistrict,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CandidateLocalizations.of(context)!.ward,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Builder(
                        builder: (context) {
                          final locale = Localizations.localeOf(context).languageCode;
                          final translatedWard = MaharashtraUtils.getWardDisplayNameWithLocale(
                            candidate.wardId,
                            locale,
                          );
                          debugPrint('🏛️ BasicInfoView - Ward translation:');
                          debugPrint('   wardId: ${candidate.wardId}');
                          debugPrint('   locale: $locale');
                          debugPrint('   wardName from SQLite: $wardName');
                          debugPrint('   translatedWard: $translatedWard');

                          // Use translated ward, fallback to SQLite cache, then raw ID
                          final displayWard = translatedWard != candidate.wardId
                            ? translatedWard
                            : (wardName ?? candidate.wardId);

                          return Text(
                            displayWard,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

