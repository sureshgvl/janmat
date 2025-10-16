import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../../../features/candidate/repositories/candidate_repository.dart';
import '../../../features/candidate/models/candidate_model.dart';
import '../../../utils/symbol_utils.dart';
import '../models/highlight_banner_model.dart';
import '../repositories/highlight_banner_repository.dart';

class HighlightBannerController extends GetxController {
  final HighlightBannerRepository _repository = HighlightBannerRepository();
  final CandidateRepository _candidateRepository = CandidateRepository();

  // Reactive state
  final Rx<HighlightBannerState> bannerState = HighlightBannerState().obs;

  // Location data
  String? _districtId;
  String? _bodyId;
  String? _wardId;

  @override
  void onInit() {
    super.onInit();
    AppLogger.common('🏷️ HighlightBannerController: Initialized');
  }

  /// Load banner data for specific location
  Future<void> loadBanner({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    // Update location
    _districtId = districtId;
    _bodyId = bodyId;
    _wardId = wardId;

    try {
      bannerState.value = bannerState.value.copyWith(isLoading: true, error: null);

      AppLogger.common('🏷️ HighlightBannerController: Loading banner for $districtId/$bodyId/$wardId');

      // Fetch banner data
      final bannerData = await _repository.getPlatinumBanner(
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      if (bannerData == null) {
        bannerState.value = bannerState.value.copyWith(isLoading: false);
        AppLogger.common('🏷️ HighlightBannerController: No banner found');
        return;
      }

      // Fetch candidate data if banner exists
      final candidateData = await _fetchCandidateData(bannerData.candidateId);
      if (candidateData == null) {
        // Candidate doesn't exist, deactivate banner
        await _repository.deactivateBanner(
          highlightId: bannerData.highlightId,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
        );
        bannerState.value = bannerState.value.copyWith(isLoading: false);
        return;
      }

      // Create enriched banner data
      final enrichedBannerData = HighlightBannerData(
        highlightId: bannerData.highlightId,
        candidateId: bannerData.candidateId,
        candidateName: candidateData.name,
        candidateParty: _resolvePartyName(candidateData.party),
        candidateProfileImageUrl: candidateData.photo,
        bannerStyle: bannerData.bannerStyle,
        callToAction: bannerData.callToAction,
        customMessage: bannerData.customMessage,
        priorityLevel: bannerData.priorityLevel,
        createdAt: bannerData.createdAt,
      );

      bannerState.value = bannerState.value.copyWith(
        isLoading: false,
        bannerData: enrichedBannerData,
      );

      AppLogger.common('🏷️ HighlightBannerController: Banner loaded successfully for ${enrichedBannerData.candidateName}');

    } catch (e) {
      AppLogger.commonError('❌ HighlightBannerController: Error loading banner', error: e);
      bannerState.value = bannerState.value.copyWith(
        isLoading: false,
        error: 'Failed to load banner: $e',
      );
    }
  }

  /// Handle banner tap
  Future<void> onBannerTap() async {
    final bannerData = bannerState.value.bannerData;
    if (bannerData == null || _districtId == null || _bodyId == null || _wardId == null) {
      return;
    }

    try {
      // Track click
      await _repository.trackBannerClick(
        highlightId: bannerData.highlightId,
        districtId: _districtId!,
        bodyId: _bodyId!,
        wardId: _wardId!,
      );

      // Track view analytics
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _repository.trackBannerView(
          highlightId: bannerData.highlightId,
          districtId: _districtId!,
          bodyId: _bodyId!,
          wardId: _wardId!,
          userId: userId,
        );
      }

      // Navigate to candidate profile
      final candidate = await _candidateRepository.getCandidateDataById(bannerData.candidateId);
      if (candidate != null) {
        Get.toNamed('/candidate-profile', arguments: candidate);
      }

    } catch (e) {
      AppLogger.commonError('❌ HighlightBannerController: Error handling banner tap', error: e);
    }
  }

  /// Refresh banner data
  Future<void> refreshBanner() async {
    if (_districtId != null && _bodyId != null && _wardId != null) {
      await loadBanner(
        districtId: _districtId!,
        bodyId: _bodyId!,
        wardId: _wardId!,
      );
    }
  }

  /// Clear error state
  void clearError() {
    bannerState.value = bannerState.value.copyWith(error: null);
  }

  /// Get banner gradient colors based on style
  static List<Color> getBannerGradient(String? bannerStyle) {
    switch (bannerStyle) {
      case 'premium':
        return [Colors.blue.shade600, Colors.blue.shade800];
      case 'elegant':
        return [Colors.purple.shade600, Colors.purple.shade800];
      case 'bold':
        return [Colors.red.shade600, Colors.red.shade800];
      case 'minimal':
        return [Colors.grey.shade600, Colors.grey.shade800];
      default:
        return [Colors.blue.shade600, Colors.blue.shade800];
    }
  }

  /// Get call to action text
  static String getCallToAction(String? callToAction) {
    return callToAction ?? 'View Profile';
  }

  /// Private method to fetch candidate data
  Future<Candidate?> _fetchCandidateData(String candidateId) async {
    try {
      return await _candidateRepository.getCandidateDataById(candidateId);
    } catch (e) {
      AppLogger.commonError('❌ HighlightBannerController: Error fetching candidate data', error: e);
      return null;
    }
  }

  /// Private method to resolve party name
  String _resolvePartyName(String? party) {
    if (party == null) return 'independent';

    // Check if party is already a key
    if (party.length <= 20 &&
        party.isNotEmpty &&
        RegExp(r'^[a-z]').hasMatch(party) &&
        !party.contains(' ') &&
        !party.contains('Nationalist') &&
        !party.contains('Congress') &&
        !party.contains('Party')) {
      return party;
    }

    // Convert old full names to keys
    return SymbolUtils.convertOldPartyNameToKey(party) ?? party;
  }
}