import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  // Get candidate data by user ID (optimized)
  Future<Candidate?> getCandidateData(String userId) async {
    try {
    debugPrint('🔍 Candidate Repository: Searching for candidate data for userId: $userId');

      // First, get the user's cityId and wardId from their user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
      debugPrint('❌ User document not found for userId: $userId');
        return null;
      }

      final userData = userDoc.data()!;
      final cityId = userData['cityId'];
      final wardId = userData['wardId'];

      if (cityId == null || wardId == null || cityId.isEmpty || wardId.isEmpty) {
      debugPrint('⚠️ User has no cityId or wardId, falling back to brute force search');
        // Fallback to the old method if city/ward info is missing
        return await _getCandidateDataBruteForce(userId);
      }

    debugPrint('🎯 Direct search: City: $cityId, Ward: $wardId');

      // Direct query to the specific city/ward path
      final candidatesSnapshot = await _firestore
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

    debugPrint('👤 Found ${candidatesSnapshot.docs.length} candidates in $cityId/$wardId');

      if (candidatesSnapshot.docs.isNotEmpty) {
        final doc = candidatesSnapshot.docs.first;
        final data = doc.data()! as Map<String, dynamic>;
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = doc.id;

        debugPrint('📄 Raw candidate data from DB:');
        final extraInfo = data['extra_info'] as Map<String, dynamic>?;
        debugPrint('   extra_info keys: ${extraInfo?.keys.toList() ?? 'null'}');
        debugPrint('   education in extra_info: ${extraInfo?.containsKey('education') ?? false}');
        debugPrint('   education value: ${extraInfo != null && extraInfo.containsKey('education') ? extraInfo['education'] : 'not found'}');

      debugPrint('✅ Found candidate: ${candidateData['name']} (ID: ${doc.id})');
        return Candidate.fromJson(candidateData);
      }

    debugPrint('❌ No candidate found in user\'s city/ward: $cityId/$wardId');
      return null;
    } catch (e) {
    debugPrint('❌ Error fetching candidate data: $e');
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

  // Fallback brute force search (for backward compatibility)
  Future<Candidate?> _getCandidateDataBruteForce(String userId) async {
  debugPrint('🔍 Falling back to brute force search for userId: $userId');
    final citiesSnapshot = await _firestore.collection('cities').get();
  debugPrint('📊 Found ${citiesSnapshot.docs.length} cities to search');

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
        debugPrint('✅ Found candidate via brute force: ${candidateData['name']} (ID: ${doc.id})');
          return Candidate.fromJson(candidateData);
        }
      }
    }

  debugPrint('❌ No candidate found via brute force search');
    return null;
  }

  // Update candidate extra info (legacy - saves entire object)
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
                  'name': candidate.name,
                  'party': candidate.party,
                  'symbol': candidate.symbol,
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

  // Update specific fields only (optimized field-level updates)
  Future<bool> updateCandidateFields(String candidateId, Map<String, dynamic> fieldUpdates) async {
    try {
      // Find the candidate's location in the nested structure
      final citiesSnapshot = await _firestore.collection('cities').get();

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateDoc = await wardDoc.reference
              .collection('candidates')
              .doc(candidateId)
              .get();

          if (candidateDoc.exists) {
            // Found the candidate, update only specified fields
            await wardDoc.reference
                .collection('candidates')
                .doc(candidateId)
                .update(fieldUpdates);
            return true;
          }
        }
      }

      throw Exception('Candidate not found');
    } catch (e) {
      throw Exception('Failed to update candidate fields: $e');
    }
  }

  // Update specific extra_info fields (most common use case)
  Future<bool> updateCandidateExtraInfoFields(String candidateId, Map<String, dynamic> extraInfoUpdates) async {
    try {
      debugPrint('🔄 updateCandidateExtraInfoFields - Input: $extraInfoUpdates');

      // Convert extra_info field updates to dot notation
      final fieldUpdates = <String, dynamic>{};

      extraInfoUpdates.forEach((key, value) {
        fieldUpdates['extra_info.$key'] = value;
        debugPrint('   Converting $key -> extra_info.$key = $value');
      });

      debugPrint('   Final field updates: $fieldUpdates');

      return await updateCandidateFields(candidateId, fieldUpdates);
    } catch (e) {
      throw Exception('Failed to update candidate extra info fields: $e');
    }
  }

  // Batch update multiple fields at once
  Future<bool> batchUpdateCandidateFields(String candidateId, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();

      // Find the candidate's location
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

      final candidateRef = _firestore
          .collection('cities')
          .doc(candidateCityId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId);

      batch.update(candidateRef, updates);
      await batch.commit();

      return true;
    } catch (e) {
      throw Exception('Failed to batch update candidate fields: $e');
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
    debugPrint('Error fetching user data for $userId: $e');
      return null;
    }
  }

  // Provisional Candidate Management Methods

  // Create a new candidate (self-registration)
  Future<String> createCandidate(Candidate candidate) async {
    try {
      final candidateData = candidate.toJson();
      candidateData['approved'] = false; // Default to not approved
      candidateData['status'] = 'pending_election'; // Default status
      candidateData['createdAt'] = FieldValue.serverTimestamp();

      // Use the candidateId if provided, otherwise let Firestore generate one
      final docRef = candidate.candidateId.isNotEmpty && !candidate.candidateId.startsWith('temp_')
          ? _firestore
              .collection('cities')
              .doc(candidate.cityId)
              .collection('wards')
              .doc(candidate.wardId)
              .collection('candidates')
              .doc(candidate.candidateId)
          : _firestore
              .collection('cities')
              .doc(candidate.cityId)
              .collection('wards')
              .doc(candidate.wardId)
              .collection('candidates')
              .doc();

      await docRef.set(candidateData);

      // Return the actual document ID (in case it was auto-generated)
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create candidate: $e');
    }
  }

  // Get candidates by approval status
  Future<List<Candidate>> getCandidatesByApprovalStatus(String cityId, String wardId, bool approved) async {
    try {
      final snapshot = await _firestore
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .where('approved', isEqualTo: approved)
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
      throw Exception('Failed to fetch candidates by approval status: $e');
    }
  }

  // Get candidates by status (pending_election or finalized)
  Future<List<Candidate>> getCandidatesByStatus(String cityId, String wardId, String status) async {
    try {
      final snapshot = await _firestore
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .where('status', isEqualTo: status)
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
      throw Exception('Failed to fetch candidates by status: $e');
    }
  }

  // Approve or reject a candidate
  Future<void> updateCandidateApproval(String cityId, String wardId, String candidateId, bool approved) async {
    try {
      await _firestore
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .update({
            'approved': approved,
            'status': approved ? 'pending_election' : 'rejected',
          });
    } catch (e) {
      throw Exception('Failed to update candidate approval: $e');
    }
  }

  // Switch candidates from provisional to finalized
  Future<void> finalizeCandidates(String cityId, String wardId, List<String> candidateIds) async {
    try {
      final batch = _firestore.batch();

      for (final candidateId in candidateIds) {
        final candidateRef = _firestore
            .collection('cities')
            .doc(cityId)
            .collection('wards')
            .doc(wardId)
            .collection('candidates')
            .doc(candidateId);

        batch.update(candidateRef, {
          'status': 'finalized',
          'approved': true,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to finalize candidates: $e');
    }
  }

  // Get all pending approval candidates across all cities and wards
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() async {
    try {
      final citiesSnapshot = await _firestore.collection('cities').get();
      List<Map<String, dynamic>> pendingCandidates = [];

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidatesSnapshot = await wardDoc.reference
              .collection('candidates')
              .where('approved', isEqualTo: false)
              .get();

          for (var candidateDoc in candidatesSnapshot.docs) {
            final data = candidateDoc.data()! as Map<String, dynamic>;
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = candidateDoc.id;
            candidateData['cityId'] = cityDoc.id;
            candidateData['wardId'] = wardDoc.id;
            pendingCandidates.add(candidateData);
          }
        }
      }

      return pendingCandidates;
    } catch (e) {
      throw Exception('Failed to fetch pending approval candidates: $e');
    }
  }

  // Check if user has already registered as a candidate
  Future<bool> hasUserRegisteredAsCandidate(String userId) async {
    try {
      final citiesSnapshot = await _firestore.collection('cities').get();

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateSnapshot = await wardDoc.reference
              .collection('candidates')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (candidateSnapshot.docs.isNotEmpty) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check user candidate registration: $e');
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