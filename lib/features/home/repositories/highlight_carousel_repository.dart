import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/highlight_carousel_model.dart';

class HighlightCarouselRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch active highlights for carousel
  Future<List<HighlightCarouselItem>> getActiveHighlights({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      AppLogger.common('🎠 HighlightCarouselRepository: Fetching highlights for $districtId/$bodyId/$wardId');

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
          .orderBy('lastShown', descending: false)
          .orderBy('priority', descending: true)
          .limit(10)
          .get();

      final items = snapshot.docs
          .map((doc) => HighlightCarouselItem.fromFirestore(doc))
          .toList();

      AppLogger.common('🎠 HighlightCarouselRepository: Found ${items.length} carousel items');

      if (items.isNotEmpty) {
        AppLogger.common('🎠 HighlightCarouselRepository: First item - ${items.first.candidateName}');
      }

      return items;
    } catch (e) {
      AppLogger.commonError('❌ HighlightCarouselRepository: Error fetching highlights', error: e);
      return [];
    }
  }

  /// Track carousel item click
  Future<void> trackCarouselClick({
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

      AppLogger.common('✅ HighlightCarouselRepository: Tracked click for carousel item $highlightId');
    } catch (e) {
      AppLogger.commonError('❌ HighlightCarouselRepository: Error tracking carousel click', error: e);
    }
  }

  /// Track carousel view analytics
  Future<void> trackCarouselView({
    required String highlightId,
    required String userId,
    required String candidateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      await _firestore.collection('section_views').add({
        'sectionType': 'carousel',
        'contentId': highlightId,
        'userId': userId,
        'candidateId': candidateId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {'platform': 'mobile', 'appVersion': '1.0.0'},
        'location': {
          'districtId': districtId,
          'bodyId': bodyId,
          'wardId': wardId,
        },
      });

      AppLogger.common('✅ HighlightCarouselRepository: Tracked view for carousel item $highlightId');
    } catch (e) {
      AppLogger.commonError('❌ HighlightCarouselRepository: Error tracking carousel view', error: e);
    }
  }

  /// Update last shown timestamp for rotation logic
  Future<void> updateLastShown({
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
          .update({
            'lastShown': FieldValue.serverTimestamp(),
            'views': FieldValue.increment(1),
          });

      AppLogger.common('✅ HighlightCarouselRepository: Updated last shown for $highlightId');
    } catch (e) {
      AppLogger.commonError('❌ HighlightCarouselRepository: Error updating last shown', error: e);
    }
  }
}