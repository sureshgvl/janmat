import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/highlight_banner_model.dart';

class HighlightBannerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch platinum banner data for a specific location
  Future<HighlightBannerData?> getPlatinumBanner({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      AppLogger.common('🏷️ HighlightBannerRepository: Fetching platinum banner for $districtId/$bodyId/$wardId');

      final snapshot = await _firestore
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .where('active', isEqualTo: true)
          .where('placement', arrayContains: 'top_banner')
          .orderBy('priority', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final bannerData = HighlightBannerData.fromFirestore(snapshot.docs.first);
        AppLogger.common('🏷️ HighlightBannerRepository: Found banner for candidate: ${bannerData.candidateName}');
        return bannerData;
      }

      AppLogger.common('🏷️ HighlightBannerRepository: No platinum banner found');
      return null;
    } catch (e) {
      AppLogger.commonError('❌ HighlightBannerRepository: Error fetching platinum banner', error: e);
      return null;
    }
  }

  /// Track banner click analytics
  Future<void> trackBannerClick({
    required String highlightId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      await _firestore
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .doc(highlightId)
          .update({'clicks': FieldValue.increment(1)});

      AppLogger.common('✅ HighlightBannerRepository: Tracked click for banner $highlightId');
    } catch (e) {
      AppLogger.commonError('❌ HighlightBannerRepository: Error tracking banner click', error: e);
    }
  }

  /// Track banner view analytics
  Future<void> trackBannerView({
    required String highlightId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('section_views').add({
        'sectionType': 'banner',
        'contentId': highlightId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {'platform': 'mobile', 'appVersion': '1.0.0'},
        'location': {
          'districtId': districtId,
          'bodyId': bodyId,
          'wardId': wardId,
        },
      });

      AppLogger.common('✅ HighlightBannerRepository: Tracked view for banner $highlightId');
    } catch (e) {
      AppLogger.commonError('❌ HighlightBannerRepository: Error tracking banner view', error: e);
    }
  }

  /// Deactivate banner if candidate doesn't exist
  Future<void> deactivateBanner({
    required String highlightId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      await _firestore
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .doc(highlightId)
          .update({'active': false});

      AppLogger.common('✅ HighlightBannerRepository: Deactivated banner $highlightId');
    } catch (e) {
      AppLogger.commonError('❌ HighlightBannerRepository: Error deactivating banner', error: e);
    }
  }
}