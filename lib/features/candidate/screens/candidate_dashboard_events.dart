import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/candidate_data_controller.dart';
import '../../../services/plan_service.dart';
import '../widgets/edit/candidate_events_tab_edit.dart';
import '../widgets/view/events_tab_view.dart';
import '../../../widgets/loading_overlay.dart';

class CandidateDashboardEvents extends StatefulWidget {
  const CandidateDashboardEvents({super.key});

  @override
  State<CandidateDashboardEvents> createState() =>
      _CandidateDashboardEventsState();
}

class _CandidateDashboardEventsState extends State<CandidateDashboardEvents> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;
  bool canManageEvents = false;

  // Global key to access events section for file uploads
  final GlobalKey<EventsTabEditState> _eventsSectionKey =
      GlobalKey<EventsTabEditState>();

  @override
  void initState() {
    super.initState();
    _loadPlanPermissions();
  }

  Future<void> _loadPlanPermissions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      canManageEvents = await PlanService.canManageEvents(currentUser.uid);
      if (mounted) setState(() {});
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
        body: isEditing
            ? SingleChildScrollView(
                child: EventsTabEdit(
                  key: _eventsSectionKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onEventsChange: (events) =>
                      controller.updateExtraInfo('events', events),
                ),
              )
            : EventsTabView(
                candidate: controller.candidateData.value!,
                isOwnProfile: true,
              ),
        floatingActionButton: canManageEvents ? (isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_events',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add('Preparing to save events...');

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save events...',
                          messageStream: messageController.stream,
                        );

                        try {
                          // First, upload any pending local files to Firebase
                          final eventsSectionState =
                              _eventsSectionKey.currentState;
                          if (eventsSectionState != null) {
                            messageController.add(
                              'Uploading files to cloud...',
                            );
                            await eventsSectionState.uploadPendingFiles();
                          }

                          // Then save the events data
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) =>
                                messageController.add(message),
                          );

                          if (success) {
                            // Update progress: Success
                            messageController.add('Events saved successfully!');

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
                                'Success',
                                'Events updated successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              Get.snackbar('Error', 'Failed to update events');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            Get.snackbar('Error', 'An error occurred: $e');
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
                      heroTag: 'cancel_events',
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
                  heroTag: 'edit_events',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Events',
                  child: const Icon(Icons.edit, size: 28),
                ),
              )) : null,
      );
    });
  }
}

