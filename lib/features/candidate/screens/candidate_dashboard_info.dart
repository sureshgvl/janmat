import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/basic_info_controller.dart';
import '../controllers/candidate_user_controller.dart';
import '../models/basic_info_model.dart';
import '../../../utils/symbol_utils.dart';
import '../widgets/view/basic_info/basic_info_tab_view.dart';
import '../widgets/edit/basic_info/basic_info_edit.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/local_database_service.dart';
import '../repositories/candidate_repository.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../models/ward_model.dart';
import '../../../utils/app_logger.dart';

class CandidateDashboardBasicInfo extends StatefulWidget {
  const CandidateDashboardBasicInfo({super.key});

  @override
  State<CandidateDashboardBasicInfo> createState() =>
      _CandidateDashboardBasicInfoState();
}

class _CandidateDashboardBasicInfoState
    extends State<CandidateDashboardBasicInfo> {
  final BasicInfoController basicInfoController = Get.put(
    BasicInfoController(),
  );
  final CandidateUserController candidateUserController =
      CandidateUserController.to;
  final LocalDatabaseService _locationDatabase = LocalDatabaseService();
  final CandidateRepository candidateRepository = CandidateRepository();
  bool isEditing = false;
  bool isSaving = false;

  // Location data variables
  String? _wardName;
  String? _districtName;
  String? _bodyName;

  @override
  void initState() {
    super.initState();
    // Load location data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocationData();
    });
  }

  // Load location data
  Future<void> _loadLocationData() async {
    final candidate = candidateUserController.candidateData.value;
    if (candidate == null) return;

    AppLogger.candidate(
      'Loading location data for candidate ${candidate.candidateId}',
      tag: 'DASHBOARD_INFO',
    );
    AppLogger.candidate(
      'IDs: district=${candidate.location.districtId}, body=${candidate.location.bodyId}, ward=${candidate.location.wardId}',
      tag: 'DASHBOARD_INFO',
    );

    try {
      // Load location data from SQLite cache
      final locationData = await _locationDatabase.getCandidateLocationData(
        candidate.location.districtId ?? '',
        candidate.location.bodyId ?? '',
        candidate.location.wardId ?? '',
        candidate.location.stateId ?? '',
      );

      // Check if ward data is missing (most likely to be missing)
      if (locationData['wardName'] == null) {
        AppLogger.candidate(
          'Ward data not found in cache, triggering sync...',
          tag: 'DASHBOARD_INFO',
        );

        // Trigger background sync for missing location data
        await _syncMissingLocationData();

        // Try loading again after sync
        final updatedLocationData = await _locationDatabase
            .getCandidateLocationData(
              candidate.location.districtId ?? '',
              candidate.location.bodyId ?? '',
              candidate.location.wardId ?? '',
              candidate.location.stateId,
            );

        if (mounted) {
          setState(() {
            _districtName = updatedLocationData['districtName'];
            _bodyName = updatedLocationData['bodyName'];
            _wardName = updatedLocationData['wardName'];
          });
        }

        // AppLogger.candidate(
        //   'Location data loaded after sync:',
        //   tag: 'DASHBOARD_INFO',
        // );
        // AppLogger.candidate(
        //   '  District: $_districtName',
        //   tag: 'DASHBOARD_INFO',
        // );
        // AppLogger.candidate('  Body: $_bodyName', tag: 'DASHBOARD_INFO');
        // AppLogger.candidate('  Ward: $_wardName', tag: 'DASHBOARD_INFO');
      } else {
        if (mounted) {
          setState(() {
            _districtName = locationData['districtName'];
            _bodyName = locationData['bodyName'];
            _wardName = locationData['wardName'];
          });
        }

        // AppLogger.candidate(
        //   'Location data loaded successfully from SQLite:',
        //   tag: 'DASHBOARD_INFO',
        // );
        // AppLogger.candidate(
        //   '  District: $_districtName',
        //   tag: 'DASHBOARD_INFO',
        // );
        // AppLogger.candidate('  Body: $_bodyName', tag: 'DASHBOARD_INFO');
        // AppLogger.candidate('  Ward: $_wardName', tag: 'DASHBOARD_INFO');
      }
    } catch (e) {
      AppLogger.candidateError(
        'Error loading location data',
        tag: 'DASHBOARD_INFO',
        error: e,
      );

      // Fallback to ID-based display if sync fails
      if (mounted) {
        setState(() {
          _districtName = candidate.location.districtId;
          _bodyName = candidate.location.bodyId;
          _wardName = 'Ward ${candidate.location.wardId}';
        });
      }
    }
  }

  // Sync missing location data from Firebase to SQLite
  Future<void> _syncMissingLocationData() async {
    final candidate = candidateUserController.candidateData.value;
    if (candidate == null) return;

    try {
      AppLogger.candidate(
        'Syncing missing location data from Firebase...',
        tag: 'DASHBOARD_INFO',
      );

      // Sync district data if missing
      if (_districtName == null) {
        AppLogger.candidate(
          'Fetching district data for ${candidate.location.districtId}',
          tag: 'DASHBOARD_INFO',
        );
        final districts = await candidateRepository.getAllDistricts();
        final district = districts.firstWhere(
          (d) => d.id == candidate.location.districtId,
          orElse: () => District(
            id: candidate.location.districtId ?? '',
            name: candidate.location.districtId ?? '',
            stateId: candidate.location.stateId ?? 'maharashtra',
          ),
        );
        await _locationDatabase.insertDistricts([district]);
        AppLogger.candidate('District data synced', tag: 'DASHBOARD_INFO');
      }

      // Sync body data if missing
      if (_bodyName == null) {
        AppLogger.candidate(
          'Fetching body data for ${candidate.location.bodyId}',
          tag: 'DASHBOARD_INFO',
        );
        final bodies = await candidateRepository.getWardsByDistrictAndBody(
          candidate.location.districtId ?? '',
          candidate.location.bodyId ?? '',
        );
        if (bodies.isNotEmpty) {
          final body = Body(
            id: candidate.location.bodyId ?? '',
            name: candidate.location.bodyId ?? '',
            type: BodyType.municipal_corporation,
            districtId: candidate.location.districtId ?? '',
            stateId: candidate.location.stateId ?? 'maharashtra',
          );
          await _locationDatabase.insertBodies([body]);
          AppLogger.candidate('Body data synced', tag: 'DASHBOARD_INFO');
        }
      }

      // Sync ward data (most critical)
      if (_wardName == null) {
        AppLogger.candidate(
          'Fetching ward data for ${candidate.location.wardId}',
          tag: 'DASHBOARD_INFO',
        );
        final wards = await candidateRepository.getWardsByDistrictAndBody(
          candidate.location.districtId ?? '',
          candidate.location.bodyId ?? '',
        );
        final ward = wards.firstWhere(
          (w) => w.id == candidate.location.wardId,
          orElse: () => Ward(
            id: candidate.location.wardId ?? '',
            name: 'Ward ${candidate.location.wardId ?? ''}',
            districtId: candidate.location.districtId ?? '',
            bodyId: candidate.location.bodyId ?? '',
            stateId: candidate.location.stateId ?? 'maharashtra',
          ),
        );
        await _locationDatabase.insertWards([ward]);
        AppLogger.candidate('Ward data synced', tag: 'DASHBOARD_INFO');
      }

      AppLogger.candidate(
        'Location data sync completed',
        tag: 'DASHBOARD_INFO',
      );
    } catch (e) {
      AppLogger.candidateError(
        'Error syncing location data',
        tag: 'DASHBOARD_INFO',
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (candidateUserController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (candidateUserController.candidateData.value == null) {
        return const Center(child: Text('No candidate data found'));
      }

      return Scaffold(
        body: SingleChildScrollView(
          child: isEditing
              ? BasicInfoEdit(
                  candidateData: candidateUserController.candidateData.value!,
                  editedData: candidateUserController.editedData.value,
                  getPartySymbolPath: (party) => SymbolUtils.getPartySymbolPath(
                    party,
                    candidate: candidateUserController.candidateData.value,
                  ),
                  onNameChange: (value) =>
                      candidateUserController.updateBasicInfo('name', value),
                  onCityChange: (value) => candidateUserController
                      .updateBasicInfo('districtId', value),
                  onWardChange: (value) =>
                      candidateUserController.updateBasicInfo('wardId', value),
                  onPartyChange: (value) =>
                      candidateUserController.updateBasicInfo('party', value),
                  onPhotoChange: (value) =>
                      candidateUserController.updatePhoto(value),
                  onBasicInfoChange: (field, value) =>
                      candidateUserController.updateBasicInfo(field, value),
                )
                : Builder(
                  builder: (context) {
                  return BasicInfoTabView(
                    candidate: candidateUserController.candidateData.value!,
                    getPartySymbolPath: (party) =>
                        SymbolUtils.getPartySymbolPath(
                          party,
                          candidate:
                              candidateUserController.candidateData.value,
                        ),
                    formatDate: (date) => '${date.day}/${date.month}/${date.year}',
                    districtName: _districtName,
                    wardName: _wardName,
                    bodyName: _bodyName,
                    // Remove displayName to let it use candidate.basicInfo?.fullName ?? candidate.name
                  );
                  },
                ),
        ),
        floatingActionButton: isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_info',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add(
                          'Preparing to save basic info...',
                        );

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save basic info...',
                          messageStream: messageController.stream,
                        );

                        try {
                          AppLogger.candidate(
                            '🔄 [BASIC_INFO_SAVE] Starting basic info save operation',
                            tag: 'DASHBOARD_SAVE',
                          );

                          // Get the edited basicInfo object directly - all edited values are already in the edited object
                          BasicInfoModel basicInfo =
                              candidateUserController
                                  .editedData
                                  .value
                                  ?.basicInfo ??
                              candidateUserController
                                  .candidateData
                                  .value!
                                  .basicInfo!;

                          // DEBUG: Log values before save
                          // AppLogger.candidate('🔍 [BASIC_INFO_SAVE] ORIGINAL VALUES:', tag: 'DASHBOARD_SAVE');
                          // if (candidateUserController.candidateData.value?.basicInfo != null) {
                          //   final original = candidateUserController.candidateData.value!.basicInfo!;
                          //   AppLogger.candidate('  📚 Original Education: "${original.education}"', tag: 'DASHBOARD_SAVE');
                          //   AppLogger.candidate('  💼 Original Profession: "${original.profession}"', tag: 'DASHBOARD_SAVE');
                          //   AppLogger.candidate('  🌐 Original Languages: ${original.languages}', tag: 'DASHBOARD_SAVE');
                          // }

                          // AppLogger.candidate('✅ [BASIC_INFO_SAVE] EDITED VALUES:', tag: 'DASHBOARD_SAVE');
                          // AppLogger.candidate('  📚 Edited Education: "${basicInfo.education}"', tag: 'DASHBOARD_SAVE');
                          // AppLogger.candidate('  💼 Edited Profession: "${basicInfo.profession}"', tag: 'DASHBOARD_SAVE');
                          // AppLogger.candidate('  🌐 Edited Languages: ${basicInfo.languages}', tag: 'DASHBOARD_SAVE');
                          // AppLogger.candidate('  📍 Edited Address: "${candidateUserController.editedData.value?.contact.address}"', tag: 'DASHBOARD_SAVE');
                          // AppLogger.candidate('📦 [BASIC_INFO_SAVE] Complete basicInfo object: ${basicInfo.toJson()}', tag: 'DASHBOARD_SAVE');

                          // // FINAL DEBUG: Log the exact BasicInfoModel being saved
                          // AppLogger.candidate('🎯 FINAL SAVE - BasicInfoModel fields:', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   📧 fullName: "${basicInfo.fullName}"', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   📅 dateOfBirth: ${basicInfo.dateOfBirth}', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   🔢 age: ${basicInfo.age}', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   👥 gender: "${basicInfo.gender}"', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   🎓 education: "${basicInfo.education}"', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   💼 profession: "${basicInfo.profession}"', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   🌍 languages: ${basicInfo.languages}', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('   📸 photo: "${basicInfo.photo}"', tag: 'BASIC_INFO_SAVE');
                          // AppLogger.candidate('🧬 Raw BasicInfoModel.toJson(): ${basicInfo.toJson()}', tag: 'BASIC_INFO_SAVE');

                          // Pass candidate object directly (cleaner architecture)
                          // Use editedData if available (contains photo updates), otherwise fallback to candidateData
                          final candidate =
                              candidateUserController.editedData.value ??
                              candidateUserController.candidateData.value!;

                          final success = await basicInfoController
                              .saveBasicInfoTabWithCandidate(
                                candidateId: candidate.candidateId,
                                basicInfo: basicInfo,
                                candidate: candidate,
                                onProgress: (message) =>
                                    messageController.add(message),
                              );

                          if (success) {
                            AppLogger.candidate(
                              '🎉 [BASIC_INFO_SAVE] Save operation successful!',
                              tag: 'DASHBOARD_SAVE',
                            );
                            // Update progress: Success
                            messageController.add(
                              'Basic info saved successfully!',
                            );

                            // Wait a moment to show success message
                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );

                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              setState(() => isEditing = false);
                              Get.snackbar(
                                AppLocalizations.of(context)!.success,
                                AppLocalizations.of(
                                  context,
                                )!.basicInfoUpdatedSuccessfully,
                                backgroundColor: Colors.green.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          } else {
                            AppLogger.candidate(
                              '❌ [BASIC_INFO_SAVE] Save operation failed',
                              tag: 'DASHBOARD_SAVE',
                            );

                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              Get.snackbar(
                                AppLocalizations.of(context)!.error,
                                'Failed to update basic info',
                                backgroundColor: Colors.red.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            Get.snackbar(
                              AppLocalizations.of(context)!.error,
                              'An error occurred: $e',
                              backgroundColor: Colors.red.shade600,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                            );
                          }
                        } finally {
                          // Clean up the stream controller
                          await messageController.close();
                        }
                      },
                      backgroundColor: Colors.green,
                      tooltip: 'Save Changes',
                      child: const Icon(Icons.save, size: 28),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'cancel_info',
                      onPressed: () {
                        candidateUserController.resetEditedData();
                        setState(() => isEditing = false);
                      },
                      backgroundColor: Colors.red,
                      tooltip: 'Cancel',
                      child: const Icon(Icons.cancel, size: 28),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: FloatingActionButton(
                  heroTag: 'edit_info',
                  onPressed: () {
                    setState(() => isEditing = true);
                    candidateUserController.editedData.value =
                        candidateUserController.candidateData.value;
                  },
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Basic Info',
                  child: const Icon(Icons.edit, size: 28),
                ),
              ),
      );
    });
  }
}
