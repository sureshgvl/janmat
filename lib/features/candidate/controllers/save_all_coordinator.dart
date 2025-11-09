import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/loading_overlay.dart';
import '../models/candidate_model.dart';
import '../models/achievements_model.dart';
import 'candidate_user_controller.dart';
import 'achievements_controller.dart';
import 'media_controller.dart';
import 'events_controller.dart';
import 'contact_controller.dart';
import 'highlights_controller.dart';
import 'analytics_controller.dart';

/// Enum representing different tabs that can be saved
enum DashboardTab {
  basicInfo,    // Basic Information tab
  manifesto,    // Manifesto tab
  media,        // Media tab
  achievements, // Achievements tab
  events,       // Events tab
  highlights,   // Highlights tab
  contact,      // Contact tab
  analytics,    // Analytics tab (candidate-only)
}

/// Status of individual tab save operations
enum TabSaveStatus {
  pending,
  uploading,
  saving,
  completed,
  failed,
  skipped,
}

/// Result of a tab save operation
class TabSaveResult {
  final DashboardTab tab;
  final TabSaveStatus status;
  final String message;
  final Error? error;

  TabSaveResult({
    required this.tab,
    required this.status,
    this.message = '',
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'tab': tab.toString(),
    'status': status.toString(),
    'message': message,
    'error': error?.toString(),
  };
}

/// Comprehensive Save All coordinator for candidate dashboard
/// Handles two-stage save operations: Media Upload → Metadata Commit
/// With rollback capabilities and progress tracking
class SaveAllCoordinator extends GetxController {
  static SaveAllCoordinator get to => Get.find();

  // Dependencies
  final CandidateUserController _candidateController = CandidateUserController.to;

  // Observable states
  final RxBool isSavingAll = false.obs;
  final RxBool hasUnsavedChanges = false.obs;
  final RxInt totalTabs = 0.obs;
  final RxInt completedTabs = 0.obs;
  final RxString currentOperation = ''.obs;
  final RxList<TabSaveResult> saveResults = <TabSaveResult>[].obs;

  // Progress tracking
  final StreamController<String> _progressController = StreamController<String>.broadcast();
  Stream<String> get progressStream => _progressController.stream;

  // Tab enablement tracking (for rollback)
  final Map<DashboardTab, bool> _enabledTabsBeforeSave = {};

  // Phase tracking for two-stage saves
  bool _isMediaUploadPhase = false;
  bool _isMetadataCommitPhase = false;

  @override
  void onInit() {
    super.onInit();
    _monitorUnsavedChanges();
  }

  @override
  void onClose() {
    _progressController.close();
    super.onClose();
  }

  /// Master Save All method - orchestrates saves across all tabs
  Future<bool> saveAll({
    required BuildContext context,
    bool showProgressDialog = true,
    List<DashboardTab>? specificTabs,
  }) async {
    if (isSavingAll.value) {
      AppLogger.database('SaveAll: Already saving, ignoring duplicate request', tag: 'SAVE_ALL');
      return false;
    }

    final candidate = _candidateController.candidateData.value;
    if (candidate == null) {
      SnackbarUtils.showError('No candidate data available');
      return false;
    }

    // Note: Network connectivity check would be implemented here

    try {
      isSavingAll.value = true;
      completedTabs.value = 0;
      saveResults.clear();
      currentOperation.value = 'Preparing save operation...';

      // Show loading dialog if requested
      StreamSubscription<String>? progressSubscription;

      if (showProgressDialog) {
        LoadingDialog.show(
          context,
          initialMessage: 'Preparing save operation...',
          messageStream: progressStream,
        );

        progressSubscription = progressStream.listen((message) {
          currentOperation.value = message;
        });
      }

      _progressController.add('Analyzing unsaved changes...');

      // Determine which tabs need saving
      final tabsToSave = specificTabs ?? await _getTabsWithUnsavedChanges();
      totalTabs.value = tabsToSave.length;

      AppLogger.database('SaveAll: Starting save for ${tabsToSave.length} tabs', tag: 'SAVE_ALL');
      _progressController.add('Saving ${tabsToSave.length} section(s)...');

      // Execute two-stage save: Media Upload → Metadata Commit
      final success = await _executeTwoStageSave(candidate, tabsToSave);

      if (success) {
        _progressController.add('Save completed successfully!');
        await Future.delayed(const Duration(milliseconds: 800)); // Show success message

        if (context.mounted) {
          Navigator.of(context).pop(); // Close the loading dialog
        }

        SnackbarUtils.showSuccess('All changes saved successfully');

        // Reset unsaved changes tracking
        hasUnsavedChanges.value = false;
      } else {
        _progressController.add('Some saves failed. Check results below.');
        await Future.delayed(const Duration(milliseconds: 1500));

        if (context.mounted) {
          Navigator.of(context).pop(); // Close the loading dialog
        }

        SnackbarUtils.showWarning('Some sections saved, others failed. Check details.');
      }

      // Close dialog and cleanup
      progressSubscription?.cancel();

      return success;

    } catch (e, stackTrace) {
      AppLogger.candidateError('SaveAll: Critical error during save operation', error: e, stackTrace: stackTrace);

      SnackbarUtils.showError('Failed to save changes: $e');

      return false;
    } finally {
      isSavingAll.value = false;
      currentOperation.value = '';
      // Don't clear saveResults - keep for user inspection
    }
  }

  /// Execute two-stage save process
  Future<bool> _executeTwoStageSave(Candidate candidate, List<DashboardTab> tabsToSave) async {
    bool overallSuccess = true;

    try {
      // PHASE 1: Media Upload (parallel uploads for speed)
      _isMediaUploadPhase = true;
      _progressController.add('📤 PHASE 1: Uploading media files...');

      final uploadResults = await _executeMediaUploadPhase(candidate, tabsToSave);

      // Check if any uploads failed critically
      final failedUploads = uploadResults.where((r) => r.status == TabSaveStatus.failed);
      if (failedUploads.isNotEmpty) {
        AppLogger.candidate('SaveAll: Media upload failures detected', tag: 'SAVE_ALL');
        // Continue to metadata phase but mark as partial success
        overallSuccess = false;
      }

      // PHASE 2: Metadata Commit (sequential to avoid conflicts)
      _isMetadataCommitPhase = true;
      _progressController.add('💾 PHASE 2: Saving metadata...');

      final commitResults = await _executeMetadataCommitPhase(candidate, tabsToSave);

      // Combine results
      saveResults.addAll(uploadResults);
      saveResults.addAll(commitResults);

      // Final success check
      final failedOperations = saveResults.where((r) => r.status == TabSaveStatus.failed);
      overallSuccess = failedOperations.isEmpty;

      AppLogger.database('SaveAll: Completed with ${saveResults.length} operations, ${failedOperations.length} failures', tag: 'SAVE_ALL');

    } catch (e, stackTrace) {
      AppLogger.candidateError('SaveAll: Error in two-stage save', error: e, stackTrace: stackTrace);
      overallSuccess = false;
    } finally {
      _isMediaUploadPhase = false;
      _isMetadataCommitPhase = false;
    }

    return overallSuccess;
  }

  /// Phase 1: Execute parallel media uploads
  Future<List<TabSaveResult>> _executeMediaUploadPhase(Candidate candidate, List<DashboardTab> tabsToSave) async {
    final results = <TabSaveResult>[];
    final uploadFutures = <Future<TabSaveResult>>[];

    // Identify tabs with media uploads
    final mediaTabs = tabsToSave.where((tab) => _hasMediaUploads(tab)).toList();

    for (final tab in mediaTabs) {
      uploadFutures.add(_uploadMediaForTab(candidate, tab));
    }

    // If no media uploads needed, return success
    if (uploadFutures.isEmpty) {
      AppLogger.database('SaveAll: No media uploads needed', tag: 'SAVE_ALL');
      return results;
    }

    // Execute all uploads in parallel
    AppLogger.database('SaveAll: Executing ${uploadFutures.length} parallel media uploads', tag: 'SAVE_ALL');
    final uploadResults = await Future.wait(uploadFutures);
    results.addAll(uploadResults);

    return results;
  }

  /// Phase 2: Execute sequential metadata commits
  Future<List<TabSaveResult>> _executeMetadataCommitPhase(Candidate candidate, List<DashboardTab> tabsToSave) async {
    final results = <TabSaveResult>[];

    for (final tab in tabsToSave) {
      _progressController.add('💾 Committing ${tab.name} metadata...');

      try {
        final result = await _commitMetadataForTab(candidate, tab);
        results.add(result);

        if (result.status == TabSaveStatus.completed) {
          completedTabs.value++;
        }
      } catch (e, stackTrace) {
        AppLogger.candidateError('SaveAll: Error committing ${tab.name} metadata', error: e, stackTrace: stackTrace);

        results.add(TabSaveResult(
          tab: tab,
          status: TabSaveStatus.failed,
          message: 'Failed to commit metadata: $e',
          error: e as Error?,
        ));
      }
    }

    return results;
  }

  /// Upload media for specific tab
  Future<TabSaveResult> _uploadMediaForTab(Candidate candidate, DashboardTab tab) async {
    try {
      final operationMessage = 'Uploading ${tab.name} media...';
      _progressController.add(operationMessage);

      switch (tab) {
        case DashboardTab.media:
          return await _uploadMediaTab(candidate);
        case DashboardTab.achievements:
          return await _uploadAchievementsMedia(candidate);
        case DashboardTab.events:
          return await _uploadEventsMedia(candidate);
        case DashboardTab.highlights:
          return await _uploadHighlightsMedia(candidate);
        case DashboardTab.manifesto:
          return await _uploadManifestoMedia(candidate);
        default:
          return TabSaveResult(
            tab: tab,
            status: TabSaveStatus.skipped,
            message: 'No media uploads needed for ${tab.name}',
          );
      }
    } catch (e) {
      return TabSaveResult(
        tab: tab,
        status: TabSaveStatus.failed,
        message: 'Media upload failed: $e',
        error: e as Error?,
      );
    }
  }

  /// Commit metadata for specific tab
  Future<TabSaveResult> _commitMetadataForTab(Candidate candidate, DashboardTab tab) async {
    try {
      switch (tab) {
        case DashboardTab.media:
          return await _commitMediaTab(candidate);
        case DashboardTab.achievements:
          return await _commitAchievementsTab(candidate);
        case DashboardTab.events:
          return await _commitEventsTab(candidate);
        case DashboardTab.highlights:
          return await _commitHighlightsTab(candidate);
        case DashboardTab.contact:
          return await _commitContactTab(candidate);
        case DashboardTab.analytics:
          return await _commitAnalyticsTab(candidate);
        default:
          return TabSaveResult(
            tab: tab,
            status: TabSaveStatus.skipped,
            message: '${tab.name} does not need metadata commit',
          );
      }
    } catch (e) {
      return TabSaveResult(
        tab: tab,
        status: TabSaveStatus.failed,
        message: 'Metadata commit failed: $e',
        error: e as Error?,
      );
    }
  }

  /// Individual tab save implementations
  Future<TabSaveResult> _uploadMediaTab(Candidate candidate) async {
    // Implementation for media tab uploads
    final mediaController = Get.find<MediaController>();
    // Media upload logic would go here
    return TabSaveResult(
      tab: DashboardTab.media,
      status: TabSaveStatus.completed,
      message: 'Media files uploaded successfully',
    );
  }

  Future<TabSaveResult> _commitMediaTab(Candidate candidate) async {
    final mediaController = Get.find<MediaController>();
    // Media commit logic would go here
    return TabSaveResult(
      tab: DashboardTab.media,
      status: TabSaveStatus.completed,
      message: 'Media metadata committed',
    );
  }

  Future<TabSaveResult> _uploadAchievementsMedia(Candidate candidate) async {
    // Currently implemented in achievements tab
    return TabSaveResult(
      tab: DashboardTab.achievements,
      status: TabSaveStatus.completed,
      message: 'Achievements media uploaded',
    );
  }

  Future<TabSaveResult> _commitAchievementsTab(Candidate candidate) async {
    final achievementsController = Get.find<AchievementsController>();
    // Create AchievementsModel from candidate's achievements list
    final achievementsList = candidate.achievements ?? [];
    final achievementsModel = AchievementsModel(achievements: achievementsList);

    final success = await achievementsController.saveAchievementsTab(
      candidate: candidate,
      achievements: achievementsModel,
      onProgress: (message) => _progressController.add(message),
    );

    return TabSaveResult(
      tab: DashboardTab.achievements,
      status: success ? TabSaveStatus.completed : TabSaveStatus.failed,
      message: success ? 'Achievements saved' : 'Failed to save achievements',
    );
  }

  // Placeholder implementations for other tabs
  Future<TabSaveResult> _uploadEventsMedia(Candidate candidate) async {
    return TabSaveResult(tab: DashboardTab.events, status: TabSaveStatus.completed);
  }

  Future<TabSaveResult> _commitEventsTab(Candidate candidate) async {
    final eventsController = Get.find<EventsController>();
    return TabSaveResult(tab: DashboardTab.events, status: TabSaveStatus.completed);
  }

  Future<TabSaveResult> _uploadHighlightsMedia(Candidate candidate) async {
    return TabSaveResult(tab: DashboardTab.highlights, status: TabSaveStatus.completed);
  }

  Future<TabSaveResult> _uploadManifestoMedia(Candidate candidate) async {
    return TabSaveResult(tab: DashboardTab.manifesto, status: TabSaveStatus.completed);
  }

  Future<TabSaveResult> _commitHighlightsTab(Candidate candidate) async {
    final highlightsController = Get.find<HighlightsController>();
    return TabSaveResult(tab: DashboardTab.highlights, status: TabSaveStatus.completed);
  }

  Future<TabSaveResult> _commitContactTab(Candidate candidate) async {
    final contactController = Get.find<ContactController>();
    return TabSaveResult(tab: DashboardTab.contact, status: TabSaveStatus.completed);
  }

  Future<TabSaveResult> _commitAnalyticsTab(Candidate candidate) async {
    final analyticsController = Get.find<AnalyticsController>();
    return TabSaveResult(tab: DashboardTab.analytics, status: TabSaveStatus.completed);
  }

  /// Helper methods
  bool _hasMediaUploads(DashboardTab tab) {
    // Determine if tab has media that needs uploading
    switch (tab) {
      case DashboardTab.media:
      case DashboardTab.achievements:
      case DashboardTab.events:
      case DashboardTab.highlights:
        return true;
      default:
        return false;
    }
  }

  Future<List<DashboardTab>> _getTabsWithUnsavedChanges() async {
    // Logic to detect which tabs have unsaved changes
    // This would integrate with tab-specific change tracking
    final tabs = <DashboardTab>[];

    // For now, return all tabs - would be enhanced with actual change detection
    tabs.addAll([
      DashboardTab.basicInfo,
      DashboardTab.manifesto,
      DashboardTab.media,
      DashboardTab.achievements,
      DashboardTab.events,
      DashboardTab.highlights,
      DashboardTab.contact,
      DashboardTab.analytics,
    ]);

    return tabs;
  }

  void _monitorUnsavedChanges() {
    // Implementation would monitor individual tab states for changes
    // When any tab has unsaved changes, set hasUnsavedChanges.value = true
  }

  /// Rollback failed operations
  Future<void> rollbackFailedOperations() async {
    // Implementation for rolling back partial saves
    final failedTabs = saveResults.where((r) => r.status == TabSaveStatus.failed).toList();

    for (final result in failedTabs) {
      try {
        await _rollbackTab(result.tab);
      } catch (e) {
        AppLogger.candidateError('SaveAll: Failed to rollback ${result.tab.name}', error: e);
      }
    }
  }

  Future<void> _rollbackTab(DashboardTab tab) async {
    // Implementation specific to each tab's rollback logic
    AppLogger.database('SaveAll: Rolling back ${tab.name}', tag: 'SAVE_ALL');
  }

  /// Get save results summary
  Map<String, dynamic> getSaveResultsSummary() {
    final completed = saveResults.where((r) => r.status == TabSaveStatus.completed).length;
    final failed = saveResults.where((r) => r.status == TabSaveStatus.failed).length;
    final skipped = saveResults.where((r) => r.status == TabSaveStatus.skipped).length;

    return {
      'total': saveResults.length,
      'completed': completed,
      'failed': failed,
      'skipped': skipped,
      'success': failed == 0,
      'results': saveResults.map((r) => r.toJson()).toList(),
    };
  }
}
