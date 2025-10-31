import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:janmat/features/highlight/models/highlight_display_model.dart';


class HighlightCarouselController {
  final List<HomeHighlight> highlights;
  final Duration rotationInterval;
  final VoidCallback onIndexChanged;
  final void Function(HomeHighlight) onHighlightViewed;

  late Timer _timer;
  int _currentIndex = 0;

  HighlightCarouselController({
    required this.highlights,
    this.rotationInterval = const Duration(seconds: 4),
    required this.onIndexChanged,
    required this.onHighlightViewed,
  }) {
    if (highlights.isNotEmpty) {
      onHighlightViewed(highlights[_currentIndex]);
      _startRotation();
    }
  }

  int get currentIndex => _currentIndex;

  void _startRotation() {
    _timer = Timer.periodic(rotationInterval, (timer) {
      if (highlights.isEmpty) return;

      _currentIndex = (_currentIndex + 1) % highlights.length;
      onIndexChanged();
      onHighlightViewed(highlights[_currentIndex]);
    });
  }

  void next() {
    if (highlights.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % highlights.length;
    onIndexChanged();
    onHighlightViewed(highlights[_currentIndex]);
  }

  void previous() {
    if (highlights.isEmpty) return;
    _currentIndex = _currentIndex == 0 ? highlights.length - 1 : _currentIndex - 1;
    onIndexChanged();
    onHighlightViewed(highlights[_currentIndex]);
  }

  void goToIndex(int index) {
    if (index < 0 || index >= highlights.length) return;
    _currentIndex = index;
    onIndexChanged();
    onHighlightViewed(highlights[_currentIndex]);
  }

  void dispose() {
    _timer.cancel();
  }
}
