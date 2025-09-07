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
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
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
      final wardsSnapshot = await _firestore
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .get();

      List<Candidate> allCandidates = [];

      for (var wardDoc in wardsSnapshot.docs) {
        final candidatesSnapshot = await wardDoc.reference.collection('candidates').get();
        final candidates = candidatesSnapshot.docs
            .map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final candidateData = Map<String, dynamic>.from(data);
              candidateData['candidateId'] = doc.id;
              return Candidate.fromJson(candidateData);
            })
            .toList();
        allCandidates.addAll(candidates);
      }

      return allCandidates;
    } catch (e) {
      throw Exception('Failed to fetch candidates: $e');
    }
  }

  // Get wards for a city
  Future<List<Ward>> getWardsByCity(String cityId) async {
    try {
      final snapshot = await _firestore
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final wardData = Map<String, dynamic>.from(data);
            wardData['wardId'] = doc.id;
            wardData['cityId'] = cityId;
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
      List<Candidate> candidates = [];

      if (cityId != null && wardId != null) {
        // Search in specific ward
        final snapshot = await _firestore
            .collection('cities')
            .doc(cityId)
            .collection('wards')
            .doc(wardId)
            .collection('candidates')
            .get();

        candidates = snapshot.docs
            .map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final candidateData = Map<String, dynamic>.from(data);
              candidateData['candidateId'] = doc.id;
              return Candidate.fromJson(candidateData);
            })
            .toList();
      } else if (cityId != null) {
        // Search in all wards of a city
        final wardsSnapshot = await _firestore
            .collection('cities')
            .doc(cityId)
            .collection('wards')
            .get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidatesSnapshot = await wardDoc.reference.collection('candidates').get();
          final wardCandidates = candidatesSnapshot.docs
              .map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                final candidateData = Map<String, dynamic>.from(data);
                candidateData['candidateId'] = doc.id;
                return Candidate.fromJson(candidateData);
              })
              .toList();
          candidates.addAll(wardCandidates);
        }
      } else {
        // Search across all cities and wards (expensive operation)
        final citiesSnapshot = await _firestore.collection('cities').get();

        for (var cityDoc in citiesSnapshot.docs) {
          final wardsSnapshot = await cityDoc.reference.collection('wards').get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidatesSnapshot = await wardDoc.reference.collection('candidates').get();
            final wardCandidates = candidatesSnapshot.docs
                .map((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  final candidateData = Map<String, dynamic>.from(data);
                  candidateData['candidateId'] = doc.id;
                  return Candidate.fromJson(candidateData);
                })
                .toList();
            candidates.addAll(wardCandidates);
          }
        }
      }

      return candidates
          .where((candidate) => candidate.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search candidates: $e');
    }
  }

  // Get candidate data by user ID
  Future<Candidate?> getCandidateData(String userId) async {
    try {
      // First, find the candidate by searching through all cities and wards
      // This is not optimal but necessary given the nested structure
      final citiesSnapshot = await _firestore.collection('cities').get();

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidatesSnapshot = await wardDoc.reference
              .collection('candidates')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (candidatesSnapshot.docs.isNotEmpty) {
            final doc = candidatesSnapshot.docs.first;
            final data = doc.data()! as Map<String, dynamic>;
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = doc.id;
            return Candidate.fromJson(candidateData);
          }
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

  // Update candidate extra info
  Future<bool> updateCandidateExtraInfo(Candidate candidate) async {
    try {
      // Find the candidate's location in the nested structure
      final citiesSnapshot = await _firestore.collection('cities').get();

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateDoc = await wardDoc.reference
              .collection('candidates')
              .doc(candidate.candidateId)
              .get();

          if (candidateDoc.exists) {
            // Found the candidate, update it
            await wardDoc.reference
                .collection('candidates')
                .doc(candidate.candidateId)
                .update({
                  'extra_info': candidate.extraInfo?.toJson(),
                  'photo': candidate.photo,
                  'manifesto': candidate.manifesto,
                  'contact': candidate.contact.toJson(),
                });
            return true;
          }
        }
      }

      throw Exception('Candidate not found');
    } catch (e) {
      throw Exception('Failed to update candidate extra info: $e');
    }
  }
}