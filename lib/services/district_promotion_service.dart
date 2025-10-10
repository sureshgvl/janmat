import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/district_promotion_model.dart';
import '../utils/app_logger.dart';

class DistrictPromotionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active district promotions
  static Future<List<DistrictPromotion>> getActivePromotions() async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Fetching active district promotions...');

      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('district_promotions')
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      AppLogger.monetization('✅ FIRESTORE: Found ${snapshot.docs.length} active promotions');

      final promotions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DistrictPromotion.fromJson(data);
      }).toList();

      return promotions;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to fetch active promotions: $e');
      return [];
    }
  }

  /// Get promotions for a specific district
  static Future<List<DistrictPromotion>> getPromotionsForDistrict(String districtId) async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Fetching promotions for district: $districtId');

      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('district_promotions')
          .where('districtId', isEqualTo: districtId)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      final promotions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DistrictPromotion.fromJson(data);
      }).toList();

      AppLogger.monetization('✅ FIRESTORE: Found ${promotions.length} promotions for district $districtId');
      return promotions;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to fetch district promotions: $e');
      return [];
    }
  }

  /// Get promotions for a specific state
  static Future<List<DistrictPromotion>> getPromotionsForState(String stateId) async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Fetching promotions for state: $stateId');

      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('district_promotions')
          .where('stateId', isEqualTo: stateId)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      final promotions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DistrictPromotion.fromJson(data);
      }).toList();

      AppLogger.monetization('✅ FIRESTORE: Found ${promotions.length} promotions for state $stateId');
      return promotions;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to fetch state promotions: $e');
      return [];
    }
  }

  /// Get promotion by ID
  static Future<DistrictPromotion?> getPromotionById(String promotionId) async {
    try {
      final doc = await _firestore.collection('district_promotions').doc(promotionId).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return DistrictPromotion.fromJson(data);
      }
      return null;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to fetch promotion: $e');
      return null;
    }
  }

  /// Check if there's an active promotion for a specific district
  static Future<DistrictPromotion?> getActivePromotionForDistrict(String districtId) async {
    try {
      final promotions = await getPromotionsForDistrict(districtId);
      return promotions.isNotEmpty ? promotions.first : null;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to check active promotion for district: $e');
      return null;
    }
  }

  /// Create a new district promotion
  static Future<String> createPromotion(DistrictPromotion promotion) async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Creating district promotion for ${promotion.districtName}');

      final docRef = await _firestore.collection('district_promotions').add({
        ...promotion.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.monetization('✅ FIRESTORE: District promotion created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to create district promotion: $e');
      throw Exception('Failed to create district promotion: $e');
    }
  }

  /// Update an existing district promotion
  static Future<void> updatePromotion(String promotionId, DistrictPromotion promotion) async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Updating district promotion: $promotionId');

      await _firestore.collection('district_promotions').doc(promotionId).update({
        ...promotion.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.monetization('✅ FIRESTORE: District promotion updated successfully');
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to update district promotion: $e');
      throw Exception('Failed to update district promotion: $e');
    }
  }

  /// Delete a district promotion
  static Future<void> deletePromotion(String promotionId) async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Deleting district promotion: $promotionId');

      await _firestore.collection('district_promotions').doc(promotionId).delete();

      AppLogger.monetization('✅ FIRESTORE: District promotion deleted successfully');
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to delete district promotion: $e');
      throw Exception('Failed to delete district promotion: $e');
    }
  }

  /// Get all promotions (for admin purposes)
  static Future<List<DistrictPromotion>> getAllPromotions() async {
    try {
      final snapshot = await _firestore.collection('district_promotions').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DistrictPromotion.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to fetch all promotions: $e');
      return [];
    }
  }
}