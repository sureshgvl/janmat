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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
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