import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../../../features/candidate/repositories/candidate_repository.dart';
import '../../../features/candidate/models/candidate_model.dart';
import '../models/highlight_carousel_model.dart';
import '../repositories/highlight_carousel_repository.dart';

class HighlightCarouselController extends GetxController {
  final HighlightCarouselRepository _repository = HighlightCarouselRepository();
  final CandidateRepository _candidateRepository = CandidateRepository();

  // Reactive state
  final Rx<HighlightCarouselState> carouselState = HighlightCarouselState().obs;

  // Auto-scroll timer
  Timer? _autoScrollTimer;
  final PageController pageController = PageController();

  // Location data
  String? _districtId;
  String? _bodyId;
  String? _wardId;

  @override
  void onInit() {
    super.onInit();
    AppLogger.common('🎠 HighlightCarouselController: Initialized');
  }

  @override
  void onClose() {
    _autoScrollTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }

  /// Load carousel items for specific location
  Future<void> loadCarouselItems({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    // Update location
    _districtId = districtId;
    _bodyId = bodyId;
    _wardId = wardId;

    try {
      carouselState.value = carouselState.value.copyWith(isLoading: true, error: null);

      AppLogger.common('🎠 HighlightCarouselController: Loading carousel for $districtId/$bodyId/$wardId');

      // Fetch carousel items
      final items = await _repository.getActiveHighlights(
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      carouselState.value = carouselState.value.copyWith(
        isLoading: false,
        items: items,
        currentPage: 0,
      );

      // Start auto-scroll if multiple items
      _startAutoScroll();

      AppLogger.common('🎠 HighlightCarouselController: Loaded ${items.length} carousel items');

    } catch (e) {
      AppLogger.commonError('❌ HighlightCarouselController: Error loading carousel', error: e);
      carouselState.value = carouselState.value.copyWith(
        isLoading: false,
        error: 'Failed to load carousel: $e',
      );
    }
  }

  /// Handle carousel item tap
  Future<void> onCarouselItemTap(HighlightCarouselItem item) async {
    if (_districtId == null || _bodyId == null || _wardId == null) {
      return;
    }

    try {
      // Track click
      await _repository.trackCarouselClick(
        highlightId: item.highlightId,
        districtId: _districtId!,
        bodyId: _bodyId!,
        wardId: _wardId!,
      );

      // Track view analytics
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _repository.trackCarouselView(
          highlightId: item.highlightId,
          userId: userId,
          candidateId: item.candidateId,
          districtId: _districtId!,
          bodyId: _bodyId!,
          wardId: _wardId!,
        );
      }

      // Navigate to candidate profile
      final candidate = await _candidateRepository.getCandidateDataById(item.candidateId);
      if (candidate != null) {
        Get.toNamed('/candidate-profile', arguments: candidate);
      }

    } catch (e) {
      AppLogger.commonError('❌ HighlightCarouselController: Error handling carousel tap', error: e);
    }
  }

  /// Handle page change from user interaction
  void onPageChanged(int page) {
    carouselState.value = carouselState.value.copyWith(currentPage: page);
    _resetAutoScroll();
  }

  /// Refresh carousel data
  Future<void> refreshCarousel() async {
    if (_districtId != null && _bodyId != null && _wardId != null) {
      await loadCarouselItems(
        districtId: _districtId!,
        bodyId: _bodyId!,
        wardId: _wardId!,
      );
    }
  }

  /// Clear error state
  void clearError() {
    carouselState.value = carouselState.value.copyWith(error: null);
  }

  /// Start auto-scroll timer
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();

    if (!carouselState.value.shouldAutoScroll) {
      return;
    }

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final currentState = carouselState.value;
      final nextPage = (currentState.currentPage + 1) % currentState.items.length;

      carouselState.value = currentState.copyWith(currentPage: nextPage);

      pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Reset auto-scroll timer when user interacts
  void _resetAutoScroll() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  /// Update location and reload if changed
  void updateLocation({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) {
    if (_districtId != districtId || _bodyId != bodyId || _wardId != wardId) {
      loadCarouselItems(
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );
    }
  }
}