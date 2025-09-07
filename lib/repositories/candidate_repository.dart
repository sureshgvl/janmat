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

  // Follow/Unfollow System Methods

  // Follow a candidate
  Future<void> followCandidate(String userId, String candidateId, {bool notificationsEnabled = true}) async {
    try {
      // First find the candidate's location in the nested structure
      final citiesSnapshot = await _firestore.collection('cities').get();
      String? candidateCityId;
      String? candidateWardId;

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateDoc = await wardDoc.reference
              .collection('candidates')
              .doc(candidateId)
              .get();

          if (candidateDoc.exists) {
            candidateCityId = cityDoc.id;
            candidateWardId = wardDoc.id;
            break;
          }
        }
        if (candidateCityId != null) break;
      }

      if (candidateCityId == null || candidateWardId == null) {
        throw Exception('Candidate not found');
      }

      final batch = _firestore.batch();

      // Add to candidate's followers subcollection
      final candidateFollowersRef = _firestore
          .collection('cities')
          .doc(candidateCityId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .doc(userId);

      batch.set(candidateFollowersRef, {
        'followedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': notificationsEnabled,
      });

      // Add to user's following subcollection
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      batch.set(userFollowingRef, {
        'followedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': notificationsEnabled,
      });

      // Update candidate's followers count
      final candidateRef = _firestore
          .collection('cities')
          .doc(candidateCityId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId);

      batch.update(candidateRef, {
        'followersCount': FieldValue.increment(1),
      });

      // Update user's following count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'followingCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to follow candidate: $e');
    }
  }

  // Unfollow a candidate
  Future<void> unfollowCandidate(String userId, String candidateId) async {
    try {
      // First find the candidate's location in the nested structure
      final citiesSnapshot = await _firestore.collection('cities').get();
      String? candidateCityId;
      String? candidateWardId;

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateDoc = await wardDoc.reference
              .collection('candidates')
              .doc(candidateId)
              .get();

          if (candidateDoc.exists) {
            candidateCityId = cityDoc.id;
            candidateWardId = wardDoc.id;
            break;
          }
        }
        if (candidateCityId != null) break;
      }

      if (candidateCityId == null || candidateWardId == null) {
        throw Exception('Candidate not found');
      }

      final batch = _firestore.batch();

      // Remove from candidate's followers subcollection
      final candidateFollowersRef = _firestore
          .collection('cities')
          .doc(candidateCityId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .doc(userId);

      batch.delete(candidateFollowersRef);

      // Remove from user's following subcollection
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      batch.delete(userFollowingRef);

      // Update candidate's followers count
      final candidateRef = _firestore
          .collection('cities')
          .doc(candidateCityId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId);

      batch.update(candidateRef, {
        'followersCount': FieldValue.increment(-1),
      });

      // Update user's following count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'followingCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow candidate: $e');
    }
  }

  // Check if user is following a candidate
  Future<bool> isUserFollowingCandidate(String userId, String candidateId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check follow status: $e');
    }
  }

  // Get followers list for a candidate
  Future<List<Map<String, dynamic>>> getCandidateFollowers(String candidateId) async {
    try {
      // First find the candidate's location in the nested structure
      final citiesSnapshot = await _firestore.collection('cities').get();
      String? candidateCityId;
      String? candidateWardId;

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateDoc = await wardDoc.reference
              .collection('candidates')
              .doc(candidateId)
              .get();

          if (candidateDoc.exists) {
            candidateCityId = cityDoc.id;
            candidateWardId = wardDoc.id;
            break;
          }
        }
        if (candidateCityId != null) break;
      }

      if (candidateCityId == null || candidateWardId == null) {
        throw Exception('Candidate not found');
      }

      final snapshot = await _firestore
          .collection('cities')
          .doc(candidateCityId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .orderBy('followedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get followers: $e');
    }
  }

  // Get following list for a user
  Future<List<String>> getUserFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get following list: $e');
    }
  }

  // Get user data by user ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching user data for $userId: $e');
      return null;
    }
  }

  // Update notification settings for a follow relationship
  Future<void> updateFollowNotificationSettings(String userId, String candidateId, bool notificationsEnabled) async {
    try {
      // First find the candidate's location in the nested structure
      final citiesSnapshot = await _firestore.collection('cities').get();
      String? candidateCityId;
      String? candidateWardId;

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateDoc = await wardDoc.reference
              .collection('candidates')
              .doc(candidateId)
              .get();

          if (candidateDoc.exists) {
            candidateCityId = cityDoc.id;
            candidateWardId = wardDoc.id;
            break;
          }
        }
        if (candidateCityId != null) break;
      }

      if (candidateCityId == null || candidateWardId == null) {
        throw Exception('Candidate not found');
      }

      final batch = _firestore.batch();

      // Update in candidate's followers subcollection (use set with merge to handle both create and update)
      final candidateFollowersRef = _firestore
          .collection('cities')
          .doc(candidateCityId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .doc(userId);

      batch.set(candidateFollowersRef, {
        'notificationsEnabled': notificationsEnabled,
        'followedAt': FieldValue.serverTimestamp(), // Ensure timestamp exists
      }, SetOptions(merge: true));

      // Update in user's following subcollection (use set with merge to handle both create and update)
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      batch.set(userFollowingRef, {
        'notificationsEnabled': notificationsEnabled,
        'followedAt': FieldValue.serverTimestamp(), // Ensure timestamp exists
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }
}