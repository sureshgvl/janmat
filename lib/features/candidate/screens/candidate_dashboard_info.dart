import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_data_controller.dart';
import '../../../utils/symbol_utils.dart';
import '../widgets/view/basic_info/basic_info_view.dart';
import '../widgets/edit/basic_info/basic_info_edit.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/local_database_service.dart';
import '../repositories/candidate_repository.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../models/ward_model.dart';
import '../../../utils/app_logger.dart';

class CandidateDashboardInfo extends StatefulWidget {
  const CandidateDashboardInfo({super.key});

  @override
  State<CandidateDashboardInfo> createState() => _CandidateDashboardInfoState();
}

class _CandidateDashboardInfoState extends State<CandidateDashboardInfo> {
  final CandidateDataController controller = Get.put(CandidateDataController());
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
    final candidate = controller.candidateData.value;
    if (candidate == null) return;

    AppLogger.candidate('Loading location data for candidate ${candidate.candidateId}', tag: 'DASHBOARD_INFO');
    AppLogger.candidate('IDs: district=${candidate.districtId}, body=${candidate.bodyId}, ward=${candidate.wardId}', tag: 'DASHBOARD_INFO');

    try {
      // Load location data from SQLite cache
      final locationData = await _locationDatabase.getCandidateLocationData(
        candidate.districtId,
        candidate.bodyId,
        candidate.wardId,
        candidate.stateId,
      );

      // Check if ward data is missing (most likely to be missing)
      if (locationData['wardName'] == null) {
        AppLogger.candidate('Ward data not found in cache, triggering sync...', tag: 'DASHBOARD_INFO');

        // Trigger background sync for missing location data
        await _syncMissingLocationData();

        // Try loading again after sync
        final updatedLocationData = await _locationDatabase.getCandidateLocationData(
          candidate.districtId,
          candidate.bodyId,
          candidate.wardId,
          candidate.stateId,
        );

        if (mounted) {
          setState(() {
            _districtName = updatedLocationData['districtName'];
            _bodyName = updatedLocationData['bodyName'];
            _wardName = updatedLocationData['wardName'];
          });
        }

        AppLogger.candidate('Location data loaded after sync:', tag: 'DASHBOARD_INFO');
        AppLogger.candidate('  District: $_districtName', tag: 'DASHBOARD_INFO');
        AppLogger.candidate('  Body: $_bodyName', tag: 'DASHBOARD_INFO');
        AppLogger.candidate('  Ward: $_wardName', tag: 'DASHBOARD_INFO');
      } else {
        if (mounted) {
          setState(() {
            _districtName = locationData['districtName'];
            _bodyName = locationData['bodyName'];
            _wardName = locationData['wardName'];
          });
        }

        AppLogger.candidate('Location data loaded successfully from SQLite:', tag: 'DASHBOARD_INFO');
        AppLogger.candidate('  District: $_districtName', tag: 'DASHBOARD_INFO');
        AppLogger.candidate('  Body: $_bodyName', tag: 'DASHBOARD_INFO');
        AppLogger.candidate('  Ward: $_wardName', tag: 'DASHBOARD_INFO');
      }
    } catch (e) {
      AppLogger.candidateError('Error loading location data', tag: 'DASHBOARD_INFO', error: e);

      // Fallback to ID-based display if sync fails
      if (mounted) {
        setState(() {
          _districtName = candidate.districtId;
          _bodyName = candidate.bodyId;
          _wardName = 'Ward ${candidate.wardId}';
        });
      }
    }
  }

  // Sync missing location data from Firebase to SQLite
  Future<void> _syncMissingLocationData() async {
    final candidate = controller.candidateData.value;
    if (candidate == null) return;

    try {
      AppLogger.candidate('Syncing missing location data from Firebase...', tag: 'DASHBOARD_INFO');

      // Sync district data if missing
      if (_districtName == null) {
        AppLogger.candidate('Fetching district data for ${candidate.districtId}', tag: 'DASHBOARD_INFO');
        final districts = await candidateRepository.getAllDistricts();
        final district = districts.firstWhere(
          (d) => d.id == candidate.districtId,
          orElse: () => District(
            id: candidate.districtId,
            name: candidate.districtId,
            stateId: candidate.stateId ?? 'maharashtra',
          ),
        );
        await _locationDatabase.insertDistricts([district]);
        AppLogger.candidate('District data synced', tag: 'DASHBOARD_INFO');
      }

      // Sync body data if missing
      if (_bodyName == null) {
        AppLogger.candidate('Fetching body data for ${candidate.bodyId}', tag: 'DASHBOARD_INFO');
        final bodies = await candidateRepository.getWardsByDistrictAndBody(
          candidate.districtId,
          candidate.bodyId,
        );
        if (bodies.isNotEmpty) {
          final body = Body(
            id: candidate.bodyId,
            name: candidate.bodyId,
            type: BodyType.municipal_corporation,
            districtId: candidate.districtId,
            stateId: candidate.stateId ?? 'maharashtra',
          );
          await _locationDatabase.insertBodies([body]);
          AppLogger.candidate('Body data synced', tag: 'DASHBOARD_INFO');
        }
      }

      // Sync ward data (most critical)
      if (_wardName == null) {
        AppLogger.candidate('Fetching ward data for ${candidate.wardId}', tag: 'DASHBOARD_INFO');
        final wards = await candidateRepository.getWardsByDistrictAndBody(
          candidate.districtId,
          candidate.bodyId,
        );
        final ward = wards.firstWhere(
          (w) => w.id == candidate.wardId,
          orElse: () => Ward(
            id: candidate.wardId,
            name: 'Ward ${candidate.wardId}',
            districtId: candidate.districtId,
            bodyId: candidate.bodyId,
            stateId: candidate.stateId ?? 'maharashtra',
          ),
        );
        await _locationDatabase.insertWards([ward]);
        AppLogger.candidate('Ward data synced', tag: 'DASHBOARD_INFO');
      }

      AppLogger.candidate('Location data sync completed', tag: 'DASHBOARD_INFO');
    } catch (e) {
      AppLogger.candidateError('Error syncing location data', tag: 'DASHBOARD_INFO', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.candidateData.value == null) {
        return const Center(child: Text('No candidate data found'));
      }

      return Scaffold(
        body: SingleChildScrollView(
          child: isEditing
              ? BasicInfoEdit(
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  getPartySymbolPath: (party) => SymbolUtils.getPartySymbolPath(
                    party,
                    candidate: controller.candidateData.value,
                  ),
                  onNameChange: (value) => controller.updateBasicInfo('name', value),
                  onCityChange: (value) =>
                      controller.updateBasicInfo('districtId', value),
                  onWardChange: (value) =>
                      controller.updateBasicInfo('wardId', value),
                  onPartyChange: (value) =>
                      controller.updateBasicInfo('party', value),
                  onPhotoChange: (value) => controller.updatePhoto(value),
                  onBasicInfoChange: (field, value) =>
                      controller.updateBasicInfo(field, value),
                )
              : Builder(
                  builder: (context) {
                    AppLogger.ui('Dashboard building BasicInfoView', tag: 'DASHBOARD_INFO');
                    AppLogger.ui('  candidateData exists: ${controller.candidateData.value != null}', tag: 'DASHBOARD_INFO');
                    AppLogger.ui('  candidate name: ${controller.candidateData.value?.name}', tag: 'DASHBOARD_INFO');
                    AppLogger.ui('  profession: ${controller.candidateData.value?.extraInfo?.basicInfo?.profession}', tag: 'DASHBOARD_INFO');
                    AppLogger.ui('  wardName passed to BasicInfoView: $_wardName', tag: 'DASHBOARD_INFO');
                    AppLogger.ui('  districtName passed to BasicInfoView: $_districtName', tag: 'DASHBOARD_INFO');
                    return BasicInfoView(
                      candidate: controller.candidateData.value!,
                      getPartySymbolPath: (party) => SymbolUtils.getPartySymbolPath(
                        party,
                        candidate: controller.candidateData.value,
                      ),
                      districtName: _districtName,
                      wardName: _wardName,
                      bodyName: _bodyName,
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
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) =>
                                messageController.add(message),
                          );

                          if (success) {
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
                        controller.resetEditedData();
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
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Basic Info',
                  child: const Icon(Icons.edit, size: 28),
                ),
              ),
      );
    });
  }
}

