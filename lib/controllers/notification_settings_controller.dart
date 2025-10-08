import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_settings_model.dart';
import '../utils/app_logger.dart';

/// Centralized controller for managing notification settings across the entire app.
/// Eliminates redundant settings fetches by caching notification preferences.
/// Follows the GetX controller pattern for consistency with the app architecture.
class NotificationSettingsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive notification settings
  final Rx<NotificationSettingsModel?> settings = Rx<NotificationSettingsModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _settingsDocSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  // Cache timestamps for data freshness
  DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 15);

  // Getters for commonly accessed settings
  String? get userId => settings.value?.userId;
  bool get pushEnabled => settings.value?.pushEnabled ?? true;
  bool get chatEnabled => settings.value?.chatEnabled ?? true;
  bool get candidateEnabled => settings.value?.candidateEnabled ?? true;
  bool get pollEnabled => settings.value?.pollEnabled ?? true;
  bool get systemEnabled => settings.value?.systemEnabled ?? true;
  bool get quietHoursEnabled => settings.value?.quietHoursEnabled ?? false;
  bool get doNotDisturbEnabled => settings.value?.doNotDisturbEnabled ?? false;
  String? get quietHoursStart => settings.value?.quietHoursStart;
  String? get quietHoursEnd => settings.value?.quietHoursEnd;
  List<String> get mutedUsers => settings.value?.mutedUsers ?? [];
  List<String> get mutedChats => settings.value?.mutedChats ?? [];

  // Reactive streams for components that need to react to settings changes
  Stream<NotificationSettingsModel?> get settingsStream => settings.stream;
  Stream<bool> get loadingStream => isLoading.stream;

  @override
  void onInit() {
    super.onInit();
    AppLogger.core('🔔 NotificationSettingsController initialized');
    _setupAuthStateListener();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  /// Setup Firebase Auth state listener to automatically load settings on login
  void _setupAuthStateListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadNotificationSettings(user.uid);
      } else {
        clearSettings();
      }
    });
  }

  /// Load notification settings from Firestore with caching
  Future<void> loadNotificationSettings(String userId) async {
    try {
      isLoading.value = true;

      // Check if we have valid cached data
      if (_hasValidCache() && settings.value?.userId == userId) {
        AppLogger.core('✅ Using cached notification settings for $userId');
        isInitialized.value = true;
        isLoading.value = false;
        return;
      }

      AppLogger.core('🔍 Loading notification settings from Firestore for $userId');

      // Set up real-time listener for notification settings
      _settingsDocSubscription?.cancel();
      _settingsDocSubscription = _firestore
          .collection('notification_settings')
          .doc(userId)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          final settingsData = docSnapshot.data() as Map<String, dynamic>;
          settings.value = NotificationSettingsModel.fromJson(settingsData);
          _lastFetchTime = DateTime.now();
          isInitialized.value = true;
          AppLogger.core('📡 Notification settings updated via real-time listener for $userId');
        } else {
          // Create default settings for new users
          final defaultSettings = NotificationSettingsModel.createDefault(userId);
          settings.value = defaultSettings;
          _lastFetchTime = DateTime.now();
          isInitialized.value = true;
          // Save default settings to Firestore
          _saveSettingsToFirestore(defaultSettings);
          AppLogger.core('📝 Created default notification settings for $userId');
        }
      });

      // Wait for initial data load
      await Future.delayed(const Duration(milliseconds: 100));

    } catch (e) {
      AppLogger.coreError('❌ Failed to load notification settings', error: e);
      // Create fallback default settings
      settings.value = NotificationSettingsModel.createDefault(userId);
      isInitialized.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update notification settings
  Future<void> updateSettings(NotificationSettingsModel newSettings) async {
    try {
      settings.value = newSettings.copyWith(lastUpdated: DateTime.now());
      await _saveSettingsToFirestore(newSettings);
      AppLogger.core('✅ Notification settings updated for ${newSettings.userId}');
    } catch (e) {
      AppLogger.coreError('❌ Failed to update notification settings', error: e);
      throw e;
    }
  }

  /// Update specific settings using a map
  Future<void> updateSettingsPartial(Map<String, dynamic> updates) async {
    if (settings.value == null) return;

    try {
      final currentSettings = settings.value!;
      final updatedJson = currentSettings.toJson()..addAll(updates);
      updatedJson['lastUpdated'] = DateTime.now().toIso8601String();

      final updatedSettings = NotificationSettingsModel.fromJson(updatedJson);
      await updateSettings(updatedSettings);
    } catch (e) {
      AppLogger.coreError('❌ Failed to update partial settings', error: e);
      throw e;
    }
  }

  /// Toggle push notifications
  Future<void> togglePushNotifications(bool enabled) async {
    await updateSettingsPartial({'pushEnabled': enabled});
  }

  /// Toggle chat notifications
  Future<void> toggleChatNotifications(bool enabled) async {
    await updateSettingsPartial({'chatEnabled': enabled});
  }

  /// Toggle candidate notifications
  Future<void> toggleCandidateNotifications(bool enabled) async {
    await updateSettingsPartial({'candidateEnabled': enabled});
  }

  /// Toggle poll notifications
  Future<void> togglePollNotifications(bool enabled) async {
    await updateSettingsPartial({'pollEnabled': enabled});
  }

  /// Toggle system notifications
  Future<void> toggleSystemNotifications(bool enabled) async {
    await updateSettingsPartial({'systemEnabled': enabled});
  }

  /// Set quiet hours
  Future<void> setQuietHours({required bool enabled, String? startTime, String? endTime}) async {
    await updateSettingsPartial({
      'quietHoursEnabled': enabled,
      'quietHoursStart': startTime,
      'quietHoursEnd': endTime,
    });
  }

  /// Toggle do not disturb mode
  Future<void> toggleDoNotDisturb(bool enabled) async {
    await updateSettingsPartial({'doNotDisturbEnabled': enabled});
  }

  /// Toggle quiet hours
  Future<void> toggleQuietHours(bool enabled) async {
    await updateSettingsPartial({'quietHoursEnabled': enabled});
  }

  /// Set quiet hours with time values
  Future<void> setQuietHoursTimes({String? startTime, String? endTime}) async {
    await updateSettingsPartial({
      'quietHoursStart': startTime,
      'quietHoursEnd': endTime,
    });
  }

  /// Mute/unmute a user
  Future<void> toggleUserMute(String targetUserId, bool mute) async {
    if (settings.value == null) return;

    final currentMuted = List<String>.from(settings.value!.mutedUsers);
    if (mute) {
      if (!currentMuted.contains(targetUserId)) {
        currentMuted.add(targetUserId);
      }
    } else {
      currentMuted.remove(targetUserId);
    }

    await updateSettingsPartial({'mutedUsers': currentMuted});
  }

  /// Mute/unmute a chat
  Future<void> toggleChatMute(String chatId, bool mute) async {
    if (settings.value == null) return;

    final currentMuted = List<String>.from(settings.value!.mutedChats);
    if (mute) {
      if (!currentMuted.contains(chatId)) {
        currentMuted.add(chatId);
      }
    } else {
      currentMuted.remove(chatId);
    }

    await updateSettingsPartial({'mutedChats': currentMuted});
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    if (settings.value == null) return;

    final defaultSettings = NotificationSettingsModel.createDefault(settings.value!.userId);
    await updateSettings(defaultSettings);
  }

  /// Clear settings (on logout)
  void clearSettings() {
    settings.value = null;
    isInitialized.value = false;
    _lastFetchTime = null;
    _settingsDocSubscription?.cancel();
    _settingsDocSubscription = null;
    AppLogger.core('🧹 Notification settings cleared');
  }

  /// Save settings to Firestore
  Future<void> _saveSettingsToFirestore(NotificationSettingsModel settingsModel) async {
    await _firestore
        .collection('notification_settings')
        .doc(settingsModel.userId)
        .set(settingsModel.toJson());
  }

  /// Check if notifications are allowed based on current settings and time
  bool areNotificationsAllowed() {
    return settings.value?.areNotificationsAllowed() ?? true;
  }

  /// Check if a specific user is muted
  bool isUserMuted(String userId) {
    return settings.value?.isUserMuted(userId) ?? false;
  }

  /// Check if a specific chat is muted
  bool isChatMuted(String chatId) {
    return settings.value?.isChatMuted(chatId) ?? false;
  }

  /// Get notification settings summary
  Map<String, dynamic> getSettingsSummary() {
    if (settings.value == null) return {};

    final s = settings.value!;
    return {
      'pushEnabled': s.pushEnabled,
      'chatEnabled': s.chatEnabled,
      'candidateEnabled': s.candidateEnabled,
      'pollEnabled': s.pollEnabled,
      'systemEnabled': s.systemEnabled,
      'quietHoursEnabled': s.quietHoursEnabled,
      'doNotDisturbEnabled': s.doNotDisturbEnabled,
      'mutedUsersCount': s.mutedUsers.length,
      'mutedChatsCount': s.mutedChats.length,
      'lastUpdated': s.lastUpdated,
    };
  }

  /// Check if cache is valid
  bool _hasValidCache() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  /// Cleanup resources
  void _cleanup() {
    _settingsDocSubscription?.cancel();
    _authStateSubscription?.cancel();
    clearSettings();
    AppLogger.core('🧹 NotificationSettingsController cleaned up');
  }


  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isLoading': isLoading.value,
      'isInitialized': isInitialized.value,
      'hasSettings': settings.value != null,
      'userId': userId,
      'pushEnabled': pushEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'mutedUsersCount': mutedUsers.length,
      'mutedChatsCount': mutedChats.length,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'cacheValid': _hasValidCache(),
    };
  }
}