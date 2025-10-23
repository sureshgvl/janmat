import 'package:get/get.dart';
import '../../../utils/app_logger.dart';

/// Base class for all tab controllers in candidate dashboard
abstract class BaseTabController extends GetxController {
  final String tabName;

  BaseTabController(this.tabName);

  // Observable for loading state
  var isLoading = false.obs;

  // Observable for data changes
  var hasUnsavedChanges = false.obs;

  // Track changed fields for this tab
  final Map<String, dynamic> _changedFields = {};

  @override
  void onInit() {
    super.onInit();
    AppLogger.database('TabController [$tabName] initialized', tag: 'TAB_CONTROLLER');
  }

  @override
  void onClose() {
    _changedFields.clear();
    AppLogger.database('TabController [$tabName] disposed', tag: 'TAB_CONTROLLER');
    super.onClose();
  }

  /// Load data for this specific tab
  Future<void> loadTabData();

  /// Update a field in this tab
  void updateField(String field, dynamic value);

  /// Save data for this tab
  Future<bool> saveTabData({Function(String)? onProgress});

  /// Validate data for this tab
  String? validateTabData();

  /// Reset changes for this tab
  void resetChanges();

  /// Check if tab has unsaved changes
  bool get hasChanges => _changedFields.isNotEmpty;

  /// Get changed fields
  Map<String, dynamic> get changedFields => Map.from(_changedFields);

  /// Track field change
  void trackFieldChange(String field, dynamic value) {
    _changedFields[field] = value;
    hasUnsavedChanges.value = true;
    AppLogger.database('TabController [$tabName] field changed: $field = $value', tag: 'TAB_CONTROLLER');
  }

  /// Clear change tracking
  void clearChangeTracking() {
    _changedFields.clear();
    hasUnsavedChanges.value = false;
    AppLogger.database('TabController [$tabName] changes cleared', tag: 'TAB_CONTROLLER');
  }

  /// Get field value from changed fields or default
  dynamic getFieldValue(String field, {dynamic defaultValue}) {
    return _changedFields[field] ?? defaultValue;
  }
}
