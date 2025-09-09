import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/basic_info_section.dart';
import '../../widgets/candidate/profile_section.dart';
import '../../widgets/candidate/achievements_section.dart';
import '../../widgets/candidate/manifesto_section.dart';
import '../../widgets/candidate/contact_section.dart';
import '../../widgets/candidate/media_section.dart';
import '../../widgets/candidate/events_section.dart';
import '../../widgets/candidate/highlight_section.dart';
import '../../widgets/candidate/followers_analytics_section.dart';

class CandidateDashboardScreen extends StatefulWidget {
  const CandidateDashboardScreen({super.key});

  @override
  State<CandidateDashboardScreen> createState() => _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;

  // Get party symbol path
  String getPartySymbolPath(String party, {String? candidateSymbol}) {
    debugPrint('🔍 [Mapping Party Symbol] For party: $party');

    // Handle independent candidates - use their custom symbol if available
    if (party.toLowerCase().contains('independent') || party.trim().isEmpty) {
      if (candidateSymbol != null && candidateSymbol.isNotEmpty) {
        return candidateSymbol; // Use uploaded symbol URL
      }
      return 'assets/symbols/independent.png';
    }

    // For party-affiliated candidates, use the default symbol mapping
    // This will be replaced with Firebase data in the future
    final partySymbols = {
      'Indian National Congress': 'assets/symbols/inc.png',
      'Bharatiya Janata Party': 'assets/symbols/bjp.png',
      'Nationalist Congress Party (Ajit Pawar faction)': 'assets/symbols/ncp_ajit.png',
      'Nationalist Congress Party – Sharadchandra Pawar': 'assets/symbols/ncp_sp.png',
      'Shiv Sena (Eknath Shinde faction)': 'assets/symbols/shiv_sena_shinde.png',
      'Shiv Sena (Uddhav Balasaheb Thackeray – UBT)': 'assets/symbols/shiv_sena_ubt.jpeg',
      'Maharashtra Navnirman Sena': 'assets/symbols/mns.png',
      'Communist Party of India': 'assets/symbols/cpi.png',
      'Communist Party of India (Marxist)': 'assets/symbols/cpi_m.png',
      'Bahujan Samaj Party': 'assets/symbols/bsp.png',
      'Samajwadi Party': 'assets/symbols/sp.png',
      'All India Majlis-e-Ittehad-ul-Muslimeen': 'assets/symbols/aimim.png',
      'National Peoples Party': 'assets/symbols/npp.png',
      'Peasants and Workers Party of India': 'assets/symbols/pwp.jpg',
      'Vanchit Bahujan Aaghadi': 'assets/symbols/vba.png',
      'Rashtriya Samaj Paksha': 'assets/symbols/default.png',
    };

    // First try exact match
    if (partySymbols.containsKey(party)) {
      return partySymbols[party]!;
    }

    // Try case-insensitive match
    final upperParty = party.toUpperCase();
    for (var entry in partySymbols.entries) {
      if (entry.key.toUpperCase() == upperParty) {
        return entry.value;
      }
    }

    // Try partial matches for common variations
    final partialMatches = {
      'INDIAN NATIONAL CONGRESS': 'assets/symbols/inc.png',
      'INDIA NATIONAL CONGRESS': 'assets/symbols/inc.png',
      'BHARATIYA JANATA PARTY': 'assets/symbols/bjp.png',
      'NATIONALIST CONGRESS PARTY': 'assets/symbols/ncp_ajit.png',
      'NATIONALIST CONGRESS PARTY AJIT': 'assets/symbols/ncp_ajit.png',
      'NATIONALIST CONGRESS PARTY SP': 'assets/symbols/ncp_sp.png',
      'SHIV SENA': 'assets/symbols/shiv_sena_ubt.jpeg',
      'SHIV SENA UBT': 'assets/symbols/shiv_sena_ubt.jpeg',
      'SHIV SENA SHINDE': 'assets/symbols/shiv_sena_shinde.png',
      'MAHARASHTRA NAVNIRMAN SENA': 'assets/symbols/mns.png',
      'COMMUNIST PARTY OF INDIA': 'assets/symbols/cpi.png',
      'COMMUNIST PARTY OF INDIA MARXIST': 'assets/symbols/cpi_m.png',
      'BAHUJAN SAMAJ PARTY': 'assets/symbols/bsp.png',
      'SAMAJWADI PARTY': 'assets/symbols/sp.png',
      'ALL INDIA MAJLIS E ITTEHADUL MUSLIMEEN': 'assets/symbols/aimim.png',
      'ALL INDIA MAJLIS-E-ITTEHADUL MUSLIMEEN': 'assets/symbols/aimim.png',
      'NATIONAL PEOPLES PARTY': 'assets/symbols/npp.png',
      'PEASANT AND WORKERS PARTY': 'assets/symbols/pwp.jpg',
      'VANCHIT BAHUJAN AGHADI': 'assets/symbols/vba.png',
      'REVOLUTIONARY SOCIALIST PARTY': 'assets/symbols/default.png',
    };

    for (var entry in partialMatches.entries) {
      if (upperParty.contains(entry.key.toUpperCase().replaceAll(' ', '')) ||
          entry.key.toUpperCase().contains(upperParty.replaceAll(' ', ''))) {
        return entry.value;
      }
    }

    return 'assets/symbols/default.png';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    // Refresh data when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshCandidateData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Profile'),
            Tab(text: 'Achievements'),
            Tab(text: 'Manifesto'),
            Tab(text: 'Contact'),
            Tab(text: 'Media'),
            Tab(text: 'Events'),
            Tab(text: 'Highlight'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.isPaid.value) {
              return Row(
                children: [
                  if (!isEditing)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => setState(() => isEditing = true),
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () async {
                            final success = await controller.saveExtraInfo();
                            if (success) {
                              setState(() => isEditing = false);
                              Get.snackbar('Success', 'Changes saved successfully');
                            } else {
                              Get.snackbar('Error', 'Failed to save changes');
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            controller.resetEditedData();
                            setState(() => isEditing = false);
                          },
                        ),
                      ],
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.candidateData.value == null) {
          return const Center(child: Text('No candidate data found'));
        }

        return TabBarView(
          controller: _tabController,
          children: [
            BasicInfoSection(
              candidateData: controller.candidateData.value!,
              getPartySymbolPath: (party) => getPartySymbolPath(party, candidateSymbol: controller.candidateData.value!.symbol),
            ),
            ProfileSection(
              candidateData: controller.candidateData.value!,
              editedData: controller.editedData.value,
              isEditing: isEditing,
              onBioChange: (bio) => controller.updateExtraInfo('bio', bio),
              onPhotoChange: (photo) => controller.updatePhoto(photo),
            ),
            AchievementsSection(
              candidateData: controller.candidateData.value!,
              editedData: controller.editedData.value,
              isEditing: isEditing,
              onAchievementsChange: (achievements) => controller.updateExtraInfo('achievements', achievements),
            ),
            ManifestoSection(
              candidateData: controller.candidateData.value!,
              editedData: controller.editedData.value,
              isEditing: isEditing,
              onManifestoChange: (manifesto) => controller.updateExtraInfo('manifesto', manifesto),
              onManifestoPdfChange: (pdf) => controller.updateExtraInfo('manifesto_pdf', pdf),
            ),
            ContactSection(
              candidateData: controller.candidateData.value!,
              editedData: controller.editedData.value,
              isEditing: isEditing,
              onContactChange: (field, value) => controller.updateContact(field, value),
              onSocialChange: (field, value) => controller.updateContact('social_$field', value),
            ),
            MediaSection(
              candidateData: controller.candidateData.value!,
              editedData: controller.editedData.value,
              isEditing: isEditing,
              onImagesChange: (images) => controller.updateExtraInfo('media', {'images': images}),
              onVideosChange: (videos) => controller.updateExtraInfo('media', {'videos': videos}),
            ),
            EventsSection(
              candidateData: controller.candidateData.value!,
              editedData: controller.editedData.value,
              isEditing: isEditing,
              onEventsChange: (events) => controller.updateExtraInfo('events', events),
            ),
            HighlightSection(
              candidateData: controller.candidateData.value!,
              editedData: controller.editedData.value,
              isEditing: isEditing,
              onHighlightChange: (highlight) => controller.updateExtraInfo('highlight', highlight),
            ),
            FollowersAnalyticsSection(
              candidateData: controller.candidateData.value!,
            ),
          ],
        );
      }),
    );
  }
}