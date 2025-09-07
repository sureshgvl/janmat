import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidate_model.dart';
import '../models/ward_model.dart';
import '../models/city_model.dart';

class CandidateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get candidates by ward
  Future<List<Candidate>> getCandidatesByWard(String cityId, String wardId) async {
    try {
      final snapshot = await _firestore
          .collection('candidates')
          .where('cityId', isEqualTo: cityId)
          .where('wardId', isEqualTo: wardId)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = doc.id;
            return Candidate.fromJson(candidateData);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch candidates: $e');
    }
  }

  // Get all candidates for a city
  Future<List<Candidate>> getCandidatesByCity(String cityId) async {
    try {
      final snapshot = await _firestore
          .collection('candidates')
          .where('cityId', isEqualTo: cityId)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = doc.id;
            return Candidate.fromJson(candidateData);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch candidates: $e');
    }
  }

  // Get wards for a city
  Future<List<Ward>> getWardsByCity(String cityId) async {
    try {
      final snapshot = await _firestore
          .collection('wards')
          .where('cityId', isEqualTo: cityId)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final wardData = Map<String, dynamic>.from(data);
            wardData['wardId'] = doc.id;
            return Ward.fromJson(wardData);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch wards: $e');
    }
  }

  // Get all cities
  Future<List<City>> getAllCities() async {
    try {
      final snapshot = await _firestore.collection('cities').get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final cityData = Map<String, dynamic>.from(data);
            cityData['cityId'] = doc.id;
            return City.fromJson(cityData);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cities: $e');
    }
  }

  // Search candidates by name (optional enhancement)
  Future<List<Candidate>> searchCandidates(String query, {String? cityId, String? wardId}) async {
    try {
      Query queryRef = _firestore.collection('candidates');

      if (cityId != null) {
        queryRef = queryRef.where('cityId', isEqualTo: cityId);
      }

      if (wardId != null) {
        queryRef = queryRef.where('wardId', isEqualTo: wardId);
      }

      final snapshot = await queryRef.get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = doc.id;
            return Candidate.fromJson(candidateData);
          })
          .where((candidate) => candidate.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search candidates: $e');
    }
  }
}