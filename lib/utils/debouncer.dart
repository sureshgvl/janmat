import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class for debouncing function calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Debounce the function call
  void debounce(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel the pending function call
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose of the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// A utility class for debouncing search operations
class SearchDebouncer {
  final Duration delay;
  Timer? _timer;
  String? _lastSearchTerm;

  SearchDebouncer({this.delay = const Duration(milliseconds: 500)});

  /// Debounce search function with term validation
  void debounceSearch(String searchTerm, VoidCallback callback) {
    // Don't debounce if search term is the same
    if (_lastSearchTerm == searchTerm) return;

    _lastSearchTerm = searchTerm;
    _timer?.cancel();

    // Don't debounce for very short terms (likely still typing)
    if (searchTerm.length < 2) {
      callback();
      return;
    }

    _timer = Timer(delay, callback);
  }

  /// Cancel the pending search
  void cancel() {
    _timer?.cancel();
    _lastSearchTerm = null;
  }

  /// Dispose of the search debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// A utility class for debouncing API calls with loading states
class ApiDebouncer {
  final Duration delay;
  Timer? _timer;
  bool _isLoading = false;

  ApiDebouncer({required this.delay});

  /// Debounce API call with loading state management
  Future<void> debounceApiCall(Future<void> Function() apiCall) async {
    if (_isLoading) return;

    _timer?.cancel();
    _timer = Timer(delay, () async {
      _isLoading = true;
      try {
        await apiCall();
      } finally {
        _isLoading = false;
      }
    });
  }

  /// Check if currently loading
  bool get isLoading => _isLoading;

  /// Cancel the pending API call
  void cancel() {
    _timer?.cancel();
    _isLoading = false;
  }

  /// Dispose of the API debouncer
  void dispose() {
    _timer?.cancel();
    _isLoading = false;
  }
}
