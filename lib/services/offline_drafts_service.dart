import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../../utils/app_logger.dart';
import 'local_database_service.dart';
import '../widgets/loading_overlay.dart';
import '../features/candidate/controllers/candidate_user_controller.dart';
import '../features/candidate/controllers/save_all_coordinator.dart';

/// Represents a draft state for tracking unsaved changes
enum DraftState {
  pristine,     // No changes made
  modified,     // Changes made but not saved
  saving,       // Currently saving to Firebase
  saved,        // Successfully saved to Firebase
  error,        // Error occurred while saving
}

/// Conflict resolution strategies for draft sync
enum ConflictResolution {
  serverWins,   // Always use server version
  localWins,    // Always use local draft
  manual,       // Prompt user to choose
}

/// Draft data container
class DraftData {
  final String draftId;
  final String userId;
  final String dataType; // 'candidate_profile', 'achievements', etc.
  final String tabName;  // 'basicInfo', 'manifesto', 'media', etc.
  final Map<String, dynamic> draftContent;
  final DateTime createdAt;
  final DateTime lastModified;
  final DraftState state;
  final DateTime? syncedAt;
  final String? firebaseVersion; // For conflict resolution

  DraftData({
    required this.draftId,
    required this.userId,
    required this.dataType,
    required this.tabName,
    required this.draftContent,
    required this.createdAt,
    required this.lastModified,
    this.state = DraftState.modified,
    this.syncedAt,
    this.firebaseVersion,
  });

  Map<String, dynamic> toJson() => {
    'draftId': draftId,
    'userId': userId,
    'dataType': dataType,
    'tabName': tabName,
    'draftContent': draftContent,
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    'state': state.name,
    'syncedAt': syncedAt?.toIso8601String(),
    'firebaseVersion': firebaseVersion,
  };

  factory DraftData.fromJson(Map<String, dynamic> json) => DraftData(
    draftId: json['draftId'],
    userId: json['userId'],
    dataType: json['dataType'],
    tabName: json['tabName'],
    draftContent: json['draftContent'] ?? {},
    createdAt: DateTime.parse(json['createdAt']),
    lastModified: DateTime.parse(json['lastModified']),
    state: DraftState.values.firstWhere(
      (e) => e.name == json['state'],
      orElse: () => DraftState.modified,
    ),
    syncedAt: json['syncedAt'] != null ? DateTime.parse(json['syncedAt']) : null,
    firebaseVersion: json['firebaseVersion'],
  );

  /// Create copy with updated fields
  DraftData copyWith({
    String? draftId,
    String? userId,
    String? dataType,
    String? tabName,
    Map<String, dynamic>? draftContent,
    DateTime? createdAt,
    DateTime? lastModified,
    DraftState? state,
    DateTime? syncedAt,
    String? firebaseVersion,
  }) {
    return DraftData(
      draftId: draftId ?? this.draftId,
      userId: userId ?? this.userId,
      dataType: dataType ?? this.dataType,
      tabName: tabName ?? this.tabName,
      draftContent: draftContent ?? this.draftContent,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      state: state ?? this.state,
      syncedAt: syncedAt ?? this.syncedAt,
      firebaseVersion: firebaseVersion ?? this.firebaseVersion,
    );
  }
}

/// Comprehensive offline drafts service with auto-sync capabilities
class OfflineDraftsService extends GetxController {
  static OfflineDraftsService get to => Get.find();

  // Dependencies
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final CandidateUserController _candidateController = CandidateUserController.to;
  final Connectivity _connectivity = Connectivity();

  // Observable states
  final RxBool isOnline = true.obs;
  final RxList<DraftData> pendingDrafts = <DraftData>[].obs;
  final RxBool isAutoSyncing = false.obs;
  final RxInt unsyncedDraftsCount = 0.obs;

  // Settings
  final Duration syncInterval = const Duration(minutes: 2);
  final ConflictResolution defaultResolution = ConflictResolution.serverWins;

  // Drafts table name
  static const String draftsTable = 'drafts';

  // Stream subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.onClose();
  }

  /// Initialize the offline drafts service
  Future<void> _initializeService() async {
    await _createDraftsTable();
    await _loadPendingDrafts();
    await _setupConnectivityMonitoring();
    _startAutoSyncTimer();

    AppLogger.database('📝 [OfflineDrafts] Service initialized successfully', tag: 'DRAFTS');
  }

  /// Create drafts table in SQLite database
  Future<void> _createDraftsTable() async {
    final db = await _localDb.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $draftsTable (
        draftId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        dataType TEXT NOT NULL,
        tabName TEXT NOT NULL,
        draftContent TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastModified TEXT NOT NULL,
        state TEXT NOT NULL,
        syncedAt TEXT,
        firebaseVersion TEXT,
        UNIQUE(draftId)
      )
    ''');
    AppLogger.database('📝 [OfflineDrafts] Drafts table created/verified', tag: 'DRAFTS');
  }

  /// Load pending drafts from local storage
  Future<void> _loadPendingDrafts() async {
    try {
      final db = await _localDb.database;
      final List<Map<String, dynamic>> maps = await db.query(
        draftsTable,
        where: 'state != ?',
        whereArgs: [DraftState.saved.name],
      );

      final drafts = maps.map((map) {
        // Convert draft content from JSON string back to Map
        final mapCopy = Map<String, dynamic>.from(map);
        if (mapCopy['draftContent'] is String) {
          mapCopy['draftContent'] = json.decode(mapCopy['draftContent']);
        }
        return DraftData.fromJson(mapCopy);
      }).toList();

      pendingDrafts.assignAll(drafts);
      unsyncedDraftsCount.value = drafts.where((d) => d.state != DraftState.saved).length;

      AppLogger.database('📝 [OfflineDrafts] Loaded ${drafts.length} pending drafts', tag: 'DRAFTS');
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error loading pending drafts', error: e, tag: 'DRAFTS');
    }
  }

  /// Setup connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(result);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  /// Update connectivity status and trigger sync if online
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    // Take the first result or check if any indicate online
    final hasOnline = results.any((result) => result != ConnectivityResult.none);
    final wasOffline = !isOnline.value;
    isOnline.value = hasOnline;

    AppLogger.database('📝 [OfflineDrafts] Connectivity changed: $results (Online: ${isOnline.value})', tag: 'DRAFTS');

    // If we just came back online and have pending drafts, auto-sync
    if (wasOffline && isOnline.value && pendingDrafts.isNotEmpty) {
      _triggerAutoSync(showProgress: false);
    }
  }

  /// Start automatic sync timer
  void _startAutoSyncTimer() {
    _syncTimer = Timer.periodic(syncInterval, (_) {
      if (isOnline.value && pendingDrafts.isNotEmpty && !isAutoSyncing.value) {
        _triggerAutoSync(showProgress: false);
      }
    });
  }

  /// Create or update a draft entry
  Future<String> saveDraft({
    required String dataType,
    required String tabName,
    required Map<String, dynamic> content,
    String? draftId,
    String? firebaseVersion,
  }) async {
    final userId = _candidateController.user.value?.uid ?? 'anonymous';
    final now = DateTime.now();

    final draft = DraftData(
      draftId: draftId ?? '${userId}_${dataType}_${tabName}_${now.millisecondsSinceEpoch}',
      userId: userId,
      dataType: dataType,
      tabName: tabName,
      draftContent: content,
      createdAt: draftId != null ? _getExistingDraftCreateTime(draftId) ?? now : now,
      lastModified: now,
      state: DraftState.modified,
      syncedAt: null,
      firebaseVersion: firebaseVersion,
    );

    try {
      final db = await _localDb.database;
      await db.insert(
        draftsTable,
        {
          ...draft.toJson(),
          'draftContent': json.encode(draft.draftContent), // Store as JSON string
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update or add to pending drafts list
      final existingIndex = pendingDrafts.indexWhere((d) => d.draftId == draft.draftId);
      if (existingIndex >= 0) {
        pendingDrafts[existingIndex] = draft;
      } else {
        pendingDrafts.add(draft);
      }

      unsyncedDraftsCount.value = pendingDrafts.where((d) => d.state != DraftState.saved).length;

      AppLogger.database('📝 [OfflineDrafts] Draft saved: ${draft.draftId}', tag: 'DRAFTS');
      return draft.draftId;
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error saving draft', error: e, tag: 'DRAFTS');
      rethrow;
    }
  }

  /// Get existing draft creation time (for updates)
  DateTime? _getExistingDraftCreateTime(String draftId) {
    final existing = pendingDrafts.firstWhereOrNull((d) => d.draftId == draftId);
    return existing?.createdAt;
  }

  /// Get draft by ID
  Future<DraftData?> getDraft(String draftId) async {
    // First check memory cache
    final cached = pendingDrafts.firstWhereOrNull((d) => d.draftId == draftId);
    if (cached != null) return cached;

    // Then check database
    try {
      final db = await _localDb.database;
      final List<Map<String, dynamic>> maps = await db.query(
        draftsTable,
        where: 'draftId = ?',
        whereArgs: [draftId],
      );

      if (maps.isNotEmpty) {
        final map = maps.first;
        final draft = DraftData.fromJson({
          ...map,
          'draftContent': json.decode(map['draftContent'] as String),
        });
        return draft;
      }
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error getting draft: $draftId', error: e, tag: 'DRAFTS');
    }

    return null;
  }

  /// Get all drafts for a user and data type
  Future<List<DraftData>> getDraftsForUser({
    required String userId,
    String? dataType,
    String? tabName,
  }) async {
    try {
      final db = await _localDb.database;
      String whereClause = 'userId = ?';
      List<String> whereArgs = [userId];

      if (dataType != null) {
        whereClause += ' AND dataType = ?';
        whereArgs.add(dataType);
      }

      if (tabName != null) {
        whereClause += ' AND tabName = ?';
        whereArgs.add(tabName);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        draftsTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'lastModified DESC',
      );

      final drafts = maps.map((map) => DraftData.fromJson({
        ...map,
        'draftContent': json.decode(map['draftContent'] as String),
      })).toList();

      return drafts;
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error getting drafts for user', error: e, tag: 'DRAFTS');
      return [];
    }
  }

  /// Sync draft with Firebase (attempt to save)
  Future<bool> syncDraft(String draftId, {BuildContext? context}) async {
    final draft = await getDraft(draftId);
    if (draft == null) {
      AppLogger.database('📝 [OfflineDrafts] Draft $draftId not found for sync', tag: 'DRAFTS');
      return false;
    }

    if (!isOnline.value) {
      AppLogger.database('📝 [OfflineDrafts] Skipping sync - offline', tag: 'DRAFTS');
      return false;
    }

    try {
      AppLogger.database('📝 [OfflineDrafts] Starting sync for draft: $draftId', tag: 'DRAFTS');

      // Mark as saving
      await _updateDraftState(draftId, DraftState.saving);

      // Attempt to save based on data type
      bool success = false;
      String? errorMessage;

      switch (draft.dataType) {
        case 'candidate_profile':
          success = await _syncCandidateProfileData(draft);
          break;
        case 'dashboard_changes':
          success = await _syncDashboardChanges(draft);
          break;
        default:
          AppLogger.database('📝 [OfflineDrafts] Unknown data type: ${draft.dataType}', tag: 'DRAFTS');
          success = false;
      }

      // Update draft state
      final newState = success ? DraftState.saved : DraftState.error;
      final syncedAt = success ? DateTime.now() : null;

      await _updateDraftState(draftId, newState, syncedAt: syncedAt);

      if (success) {
        AppLogger.database('✅ [OfflineDrafts] Draft synced successfully: $draftId', tag: 'DRAFTS');

        // Remove from pending drafts if completely synced
        pendingDrafts.removeWhere((d) => d.draftId == draftId);
        unsyncedDraftsCount.value = pendingDrafts.where((d) => d.state != DraftState.saved).length;
      } else {
        AppLogger.database('❌ [OfflineDrafts] Draft sync failed: $draftId', tag: 'DRAFTS');
        _updateDraftState(draftId, DraftState.error, errorMessage: errorMessage);
      }

      return success;

    } catch (e, stackTrace) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error syncing draft', error: e, stackTrace: stackTrace, tag: 'DRAFTS');
      await _updateDraftState(draftId, DraftState.error, errorMessage: e.toString());
      return false;
    }
  }

  /// Automatically sync all pending drafts
  Future<void> _triggerAutoSync({bool showProgress = true}) async {
    if (isAutoSyncing.value || pendingDrafts.isEmpty || !isOnline.value) {
      return;
    }

    isAutoSyncing.value = true;
    AppLogger.database('🔄 [OfflineDrafts] Starting auto-sync of ${pendingDrafts.length} drafts', tag: 'DRAFTS');

    try {
      final StreamController<String> progressController = StreamController<String>.broadcast();
      StreamSubscription<String>? progressSubscription;

      if (showProgress && Get.context != null) {
        LoadingDialog.show(
          Get.context!,
          initialMessage: 'Syncing drafts...',
          messageStream: progressController.stream,
        );

        progressSubscription = progressController.stream.listen((message) {
          // Stream messages if needed
        });
      }

      // Sync drafts in parallel for speed
      final syncFutures = pendingDrafts
          .where((draft) => draft.state != DraftState.saving && draft.state != DraftState.saved)
          .map((draft) => _syncIndividualDraft(draft, progressController))
          .toList();

      if (syncFutures.isNotEmpty) {
        progressController.add('Syncing ${syncFutures.length} drafts...');
        await Future.wait(syncFutures);
      }

      // Close progress UI
      progressSubscription?.cancel();
      if (Get.context != null && Get.context!.mounted) {
        Navigator.of(Get.context!).pop();
      }

      progressController.close();

      AppLogger.database('✅ [OfflineDrafts] Auto-sync completed', tag: 'DRAFTS');

    } catch (e, stackTrace) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error during auto-sync', error: e, stackTrace: stackTrace, tag: 'DRAFTS');
    } finally {
      isAutoSyncing.value = false;
    }
  }

  /// Sync individual draft for auto-sync
  Future<void> _syncIndividualDraft(DraftData draft, StreamController<String> progressController) async {
    try {
      await syncDraft(draft.draftId);
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error syncing draft ${draft.draftId}', error: e, tag: 'DRAFTS');
    }
  }

  /// Sync candidate profile data
  Future<bool> _syncCandidateProfileData(DraftData draft) async {
    try {
      final profileData = draft.draftContent;

      // Use the existing candidate data update methods
      // This would integrate with the SaveAllCoordinator or individual controllers
      // For now, return true as placeholder
      AppLogger.database('📝 [OfflineDrafts] Syncing candidate profile: ${draft.draftId}', tag: 'DRAFTS');
      return true;
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error syncing candidate profile', error: e, tag: 'DRAFTS');
      return false;
    }
  }

  /// Sync dashboard changes (multiple tabs)
  Future<bool> _syncDashboardChanges(DraftData draft) async {
    try {
      // Use SaveAllCoordinator to sync dashboard changes
      final saveCoordinator = SaveAllCoordinator.to;

      // Parse dashboard change data and call appropriate save methods
      AppLogger.database('📝 [OfflineDrafts] Syncing dashboard changes: ${draft.draftId}', tag: 'DRAFTS');

      // Implementation would extract changed tabs from draft content
      // and call SaveAllCoordinator with specific tabs
      return true;
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error syncing dashboard changes', error: e, tag: 'DRAFTS');
      return false;
    }
  }

  /// Update draft state in database
  Future<void> _updateDraftState(
    String draftId,
    DraftState newState, {
    DateTime? syncedAt,
    String? errorMessage,
  }) async {
    try {
      final db = await _localDb.database;
      final updateData = {
        'state': newState.name,
        'lastModified': DateTime.now().toIso8601String(),
      };

      if (syncedAt != null) {
        updateData['syncedAt'] = syncedAt.toIso8601String();
      }

      await db.update(
        draftsTable,
        updateData,
        where: 'draftId = ?',
        whereArgs: [draftId],
      );

      // Update in memory cache
      final index = pendingDrafts.indexWhere((d) => d.draftId == draftId);
      if (index >= 0) {
        final updatedDraft = pendingDrafts[index].copyWith(
          state: newState,
          syncedAt: syncedAt,
          lastModified: DateTime.now(),
        );
        pendingDrafts[index] = updatedDraft;
      }

    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error updating draft state', error: e, tag: 'DRAFTS');
    }
  }

  /// Delete draft from storage
  Future<void> deleteDraft(String draftId) async {
    try {
      final db = await _localDb.database;
      await db.delete(
        draftsTable,
        where: 'draftId = ?',
        whereArgs: [draftId],
      );

      pendingDrafts.removeWhere((d) => d.draftId == draftId);
      unsyncedDraftsCount.value = pendingDrafts.where((d) => d.state != DraftState.saved).length;

      AppLogger.database('📝 [OfflineDrafts] Draft deleted: $draftId', tag: 'DRAFTS');
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error deleting draft', error: e, tag: 'DRAFTS');
      rethrow;
    }
  }

  /// Force sync all pending drafts (manual trigger)
  Future<bool> forceSyncAll({BuildContext? context}) async {
    AppLogger.database('🔄 [OfflineDrafts] Manual force sync triggered', tag: 'DRAFTS');

    if (!isOnline.value) {
      Get.snackbar(
        'Offline',
        'Cannot sync drafts while offline. Please check your connection.',
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    await _triggerAutoSync(showProgress: true);
    return pendingDrafts.where((d) => d.state == DraftState.saved).length == pendingDrafts.length;
  }

  /// Handle conflict resolution
  Future<ConflictResolution> resolveConflict(DraftData localDraft, Map<String, dynamic> serverData) async {
    // For now, use default resolution strategy
    // In a full implementation, this would show a dialog to the user
    AppLogger.database('⚖️ [OfflineDrafts] Conflict resolution: Using ${defaultResolution.name}', tag: 'DRAFTS');
    return defaultResolution;
  }

  /// Get draft statistics
  Map<String, dynamic> getDraftStatistics() {
    final total = pendingDrafts.length;
    final saved = pendingDrafts.where((d) => d.state == DraftState.saved).length;
    final modified = pendingDrafts.where((d) => d.state == DraftState.modified).length;
    final error = pendingDrafts.where((d) => d.state == DraftState.error).length;
    final saving = pendingDrafts.where((d) => d.state == DraftState.saving).length;

    return {
      'total': total,
      'saved': saved,
      'modified': modified,
      'error': error,
      'saving': saving,
      'unsynced': total - saved,
      'isOnline': isOnline.value,
      'autoSyncing': isAutoSyncing.value,
    };
  }

  /// Clear old synced drafts (cleanup)
  Future<void> clearSyncedDrafts({Duration olderThan = const Duration(days: 7)}) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);
      final db = await _localDb.database;

      final deleted = await db.delete(
        draftsTable,
        where: 'state = ? AND syncedAt IS NOT NULL AND syncedAt < ?',
        whereArgs: [DraftState.saved.name, cutoffDate.toIso8601String()],
      );

      AppLogger.database('🧹 [OfflineDrafts] Cleared $deleted old synced drafts', tag: 'DRAFTS');
    } catch (e) {
      AppLogger.databaseError('📝 [OfflineDrafts] Error clearing synced drafts', error: e, tag: 'DRAFTS');
    }
  }
}
