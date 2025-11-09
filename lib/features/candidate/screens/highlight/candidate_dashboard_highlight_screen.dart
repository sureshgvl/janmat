import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:janmat/features/candidate/controllers/highlights_controller.dart';
import 'package:janmat/widgets/loading_overlay.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../controllers/candidate_user_controller.dart';
import 'highlight_tab_widget.dart';


class CandidateDashboardHighlight extends StatefulWidget {
  const CandidateDashboardHighlight({super.key});

  @override
  State<CandidateDashboardHighlight> createState() =>
      _CandidateDashboardHighlightState();
}

class _CandidateDashboardHighlightState
    extends State<CandidateDashboardHighlight> {
  final CandidateUserController controller = CandidateUserController.to;
  final GlobalKey<HighlightTabState> _highlightTabKey = GlobalKey<HighlightTabState>();

  // Track if there are changes to save
  bool _hasChanges = false;

  // Callback for when changes state changes
  void _onChangesStateChanged(bool hasChanges) {
    setState(() {
      _hasChanges = hasChanges;
    });
  }

  // Refresh banner widgets to show updated image instantly
  Future<void> _refreshBannerWidgets() async {
    try {
      // Since banners are used in home screen and may be in multiple locations,
      // we'll use a simple approach: trigger a rebuild by updating a reactive variable
      // or use GetX to find banner controllers

      // For now, we'll use a simple delay to allow Firestore to propagate
      // In a more sophisticated implementation, we could use streams or GetX controllers
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Error handling is done in the calling method
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
        appBar: AppBar(
          title: const Text('Highlight'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: HighlightTab(
          key: _highlightTabKey,
          candidateData: controller.candidateData.value!,
          editedData: controller.editedData.value,
          onHighlightChange: controller.updateHighlightsInfo,
          onChangesStateChanged: _onChangesStateChanged,
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20, right: 16),
          child: FloatingActionButton(
            heroTag: 'save_highlight',
            onPressed: _hasChanges ? () async {
              // Create a stream controller for progress updates
              final messageController = StreamController<String>();
              messageController.add('Preparing to save highlight...');

              // Show loading dialog with message stream
              LoadingDialog.show(
                context,
                initialMessage: 'Preparing to save highlight...',
                messageStream: messageController.stream,
              );

              try {
                // First, upload any pending local files to Firebase
                final highlightTabState = _highlightTabKey.currentState;
                if (highlightTabState != null) {
                  messageController.add('Uploading files to cloud...');
                  await highlightTabState.uploadPendingFiles();
                }

                // Then save the highlight data using highlights controller
                final highlightsController = Get.find<HighlightsController>();
                final highlightData = highlightsController.highlights.value?.highlights?.isNotEmpty == true
                    ? highlightsController.highlights.value!.highlights!.first
                    : null;
                final success = await highlightsController.saveHighlightsTabWithCandidate(
                  candidateId: controller.candidateData.value!.candidateId,
                  candidate: controller.candidateData.value,
                  highlight: highlightData,
                  onProgress: (message) => messageController.add(message),
                );

                if (success) {
                  messageController.add('Highlight saved successfully!');

                  // Refresh banner widgets to show updated image instantly
                  messageController.add('Updating banner display...');
                  await _refreshBannerWidgets();

                  await Future.delayed(const Duration(milliseconds: 800));

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    SnackbarUtils.showSuccess('Highlight updated successfully');
                  }
                } else {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    SnackbarUtils.showError('Failed to update highlight');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  SnackbarUtils.showError('An error occurred: $e');
                }
              } finally {
                await messageController.close();
              }
            } : null,
            backgroundColor: _hasChanges ? Colors.green : Colors.grey.shade400,
            tooltip: _hasChanges ? 'Save Changes' : 'No changes to save',
            child: const Icon(Icons.save, size: 28),
          ),
        ),
      );
    });
  }
}
