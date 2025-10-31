import 'dart:async';
import 'package:get/get.dart';
import '../utils/app_logger.dart';

/// Service to track which screen is currently focused/active
class ScreenFocusService {
  static final ScreenFocusService _instance = ScreenFocusService._internal();
  factory ScreenFocusService() => _instance;

  ScreenFocusService._internal();

  final StreamController<String?> _focusController = StreamController<String?>.broadcast();
  Stream<String?> get focusStream => _focusController.stream;

  String? _currentFocusedScreen;

  /// Get the currently focused screen
  String? get currentFocusedScreen => _currentFocusedScreen;

  /// Check if home screen is currently focused
  bool get isHomeScreenFocused => _currentFocusedScreen == 'home';

  /// Set the currently focused screen
  void setFocusedScreen(String? screenName) {
    if (_currentFocusedScreen != screenName) {
      final previousScreen = _currentFocusedScreen;
      _currentFocusedScreen = screenName;

      _focusController.add(screenName);

      AppLogger.common('🎯 Screen focus changed: $previousScreen → $screenName');
    }
  }

  /// Clear focus (no screen is focused)
  void clearFocus() {
    setFocusedScreen(null);
  }

  /// Dispose resources
  void dispose() {
    _focusController.close();
  }
}

/// GetX controller for reactive screen focus tracking
class ScreenFocusController extends GetxController {
  final ScreenFocusService _focusService = ScreenFocusService();

  final Rx<String?> currentFocusedScreen = Rx<String?>(null);
  final RxBool isHomeScreenFocused = RxBool(false);

  StreamSubscription<String?>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _focusService.focusStream.listen((screen) {
      currentFocusedScreen.value = screen;
      isHomeScreenFocused.value = screen == 'home';
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void setFocusedScreen(String? screenName) {
    _focusService.setFocusedScreen(screenName);
  }

  void clearFocus() {
    _focusService.clearFocus();
  }
}
