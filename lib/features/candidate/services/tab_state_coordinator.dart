import 'package:get/get.dart';

/// Service responsible for coordinating tab-specific edit states.
/// Follows Single Responsibility Principle - manages only tab edit states.
class TabStateCoordinator {
  // Tab-specific edit mode state management
  final RxBool _isBasicInfoEditing = false.obs;
  final RxBool _isManifestoEditing = false.obs;
  final RxBool _isContactEditing = false.obs;
  final RxBool _isAchievementsEditing = false.obs;
  final RxBool _isMediaEditing = false.obs;
  final RxBool _isEventsEditing = false.obs;
  final RxBool _isHighlightsEditing = false.obs;
  final RxBool _isAnalyticsEditing = false.obs;

  // Public getters for tab-specific edit states
  bool get isBasicInfoEditing => _isBasicInfoEditing.value;
  bool get isManifestoEditing => _isManifestoEditing.value;
  bool get isContactEditing => _isContactEditing.value;
  bool get isAchievementsEditing => _isAchievementsEditing.value;
  bool get isMediaEditing => _isMediaEditing.value;
  bool get isEventsEditing => _isEventsEditing.value;
  bool get isHighlightsEditing => _isHighlightsEditing.value;
  bool get isAnalyticsEditing => _isAnalyticsEditing.value;

  // Public setters for tab-specific edit states
  set isBasicInfoEditing(bool value) => _isBasicInfoEditing.value = value;
  set isManifestoEditing(bool value) => _isManifestoEditing.value = value;
  set isContactEditing(bool value) => _isContactEditing.value = value;
  set isAchievementsEditing(bool value) => _isAchievementsEditing.value = value;
  set isMediaEditing(bool value) => _isMediaEditing.value = value;
  set isEventsEditing(bool value) => _isEventsEditing.value = value;
  set isHighlightsEditing(bool value) => _isHighlightsEditing.value = value;
  set isAnalyticsEditing(bool value) => _isAnalyticsEditing.value = value;

  /// Start editing for a specific tab
  void startEditingTab(String tabName) {
    switch (tabName) {
      case 'basic_info':
        _isBasicInfoEditing.value = true;
        break;
      case 'manifesto':
        _isManifestoEditing.value = true;
        break;
      case 'contact':
        _isContactEditing.value = true;
        break;
      case 'achievements':
        _isAchievementsEditing.value = true;
        break;
      case 'media':
        _isMediaEditing.value = true;
        break;
      case 'events':
        _isEventsEditing.value = true;
        break;
      case 'highlights':
        _isHighlightsEditing.value = true;
        break;
      case 'analytics':
        _isAnalyticsEditing.value = true;
        break;
    }
  }

  /// Stop editing for a specific tab
  void stopEditingTab(String tabName) {
    switch (tabName) {
      case 'basic_info':
        _isBasicInfoEditing.value = false;
        break;
      case 'manifesto':
        _isManifestoEditing.value = false;
        break;
      case 'contact':
        _isContactEditing.value = false;
        break;
      case 'achievements':
        _isAchievementsEditing.value = false;
        break;
      case 'media':
        _isMediaEditing.value = false;
        break;
      case 'events':
        _isEventsEditing.value = false;
        break;
      case 'highlights':
        _isHighlightsEditing.value = false;
        break;
      case 'analytics':
        _isAnalyticsEditing.value = false;
        break;
    }
  }

  /// Check if a specific tab is in editing mode
  bool isTabEditing(String tabName) {
    switch (tabName) {
      case 'basic_info':
        return _isBasicInfoEditing.value;
      case 'manifesto':
        return _isManifestoEditing.value;
      case 'contact':
        return _isContactEditing.value;
      case 'achievements':
        return _isAchievementsEditing.value;
      case 'media':
        return _isMediaEditing.value;
      case 'events':
        return _isEventsEditing.value;
      case 'highlights':
        return _isHighlightsEditing.value;
      case 'analytics':
        return _isAnalyticsEditing.value;
      default:
        return false;
    }
  }

  /// Reset all tab edit states
  void resetAllTabStates() {
    _isBasicInfoEditing.value = false;
    _isManifestoEditing.value = false;
    _isContactEditing.value = false;
    _isAchievementsEditing.value = false;
    _isMediaEditing.value = false;
    _isEventsEditing.value = false;
    _isHighlightsEditing.value = false;
    _isAnalyticsEditing.value = false;
  }

  /// Get all tab states as a map (useful for debugging)
  Map<String, bool> getAllTabStates() {
    return {
      'basic_info': _isBasicInfoEditing.value,
      'manifesto': _isManifestoEditing.value,
      'contact': _isContactEditing.value,
      'achievements': _isAchievementsEditing.value,
      'media': _isMediaEditing.value,
      'events': _isEventsEditing.value,
      'highlights': _isHighlightsEditing.value,
      'analytics': _isAnalyticsEditing.value,
    };
  }
}
