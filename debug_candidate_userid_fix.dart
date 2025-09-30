// Debug script to fix candidate userId mismatch issue
// Run this in debug console or as a temporary addition to your app

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CandidateUserIdFixer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Find all candidates with incorrect userId
  Future<void> findMismatchedCandidates() async {
    print('🔍 Finding candidates with mismatched userId...');

    try {
      // Get all states
      final statesSnapshot = await _firestore.collection('states').get();

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (var bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (var wardDoc in wardsSnapshot.docs) {
              final candidatesSnapshot = await wardDoc.reference.collection('candidates').get();

              for (var candidateDoc in candidatesSnapshot.docs) {
                final candidateData = candidateDoc.data();
                final candidateId = candidateDoc.id;
                final storedUserId = candidateData['userId'] as String?;
                final candidateName = candidateData['name'] as String? ?? 'Unknown';

                if (storedUserId != null) {
                  // Check if user exists with this userId
                  final userDoc = await _firestore.collection('users').doc(storedUserId).get();

                  if (!userDoc.exists) {
                    print('❌ MISMATCH FOUND:');
                    print('   Candidate: $candidateName (ID: $candidateId)');
                    print('   Stored userId: $storedUserId (DOES NOT EXIST)');
                    print('   Location: states/${stateDoc.id}/districts/${districtDoc.id}/bodies/${bodyDoc.id}/wards/${wardDoc.id}/candidates/$candidateId');
                    print('');
                  } else {
                    // Check if user has FCM token
                    final userData = userDoc.data();
                    final fcmToken = userData?['fcmToken'];
                    if (fcmToken == null) {
                      print('⚠️  NO FCM TOKEN:');
                      print('   Candidate: $candidateName (ID: $candidateId)');
                      print('   User exists but no FCM token');
                      print('');
                    }
                  }
                } else {
                  print('⚠️  NO USERID:');
                  print('   Candidate: $candidateName (ID: $candidateId)');
                  print('   No userId field in candidate document');
                  print('');
                }
              }
            }
          }
        }
      }

      print('✅ Finished scanning all candidates');
    } catch (e) {
      print('❌ Error finding mismatched candidates: $e');
    }
  }

  // Fix candidate userId by finding the correct user
  Future<void> fixCandidateUserId(String candidateId, String correctUserId) async {
    print('🔧 Fixing candidate userId...');
    print('   Candidate ID: $candidateId');
    print('   New userId: $correctUserId');

    try {
      // Find the candidate document
      final candidateRef = await _findCandidateReference(candidateId);

      if (candidateRef == null) {
        print('❌ Candidate not found: $candidateId');
        return;
      }

      // Update the userId
      await candidateRef.update({
        'userId': correctUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully updated candidate userId');
    } catch (e) {
      print('❌ Error fixing candidate userId: $e');
    }
  }

  // Find candidate document reference by candidateId
  Future<DocumentReference?> _findCandidateReference(String candidateId) async {
    try {
      final statesSnapshot = await _firestore.collection('states').get();

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (var bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (var wardDoc in wardsSnapshot.docs) {
              final candidateDoc = await wardDoc.reference
                  .collection('candidates')
                  .doc(candidateId)
                  .get();

              if (candidateDoc.exists) {
                return wardDoc.reference.collection('candidates').doc(candidateId);
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error finding candidate reference: $e');
      return null;
    }
  }

  // Get current user's FCM token and userId
  Future<void> checkCurrentUserFCM() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No current user logged in');
        return;
      }

      print('👤 Current User:');
      print('   UID: ${currentUser.uid}');
      print('   Email: ${currentUser.email}');
      print('   Display Name: ${currentUser.displayName}');

      // Check user document
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final fcmToken = userData?['fcmToken'];
        print('   FCM Token: ${fcmToken != null ? "Present (${fcmToken.substring(0, 20)}...)" : "MISSING"}');
      } else {
        print('   User document: DOES NOT EXIST');
      }
    } catch (e) {
      print('❌ Error checking current user: $e');
    }
  }

  // Auto-fix candidates by matching with user documents
  Future<void> autoFixCandidates() async {
    print('🔧 Auto-fixing candidate userIds...');

    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      final userMap = <String, String>{}; // email -> userId
      final userRoleMap = <String, String>{}; // userId -> role

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final email = userData['email'] as String?;
        final role = userData['role'] as String?;
        if (email != null) {
          userMap[email] = userDoc.id;
        }
        if (role == 'candidate') {
          userRoleMap[userDoc.id] = role!;
        }
      }

      print('📋 Found ${userMap.length} users with emails');
      print('👥 Found ${userRoleMap.length} candidate-role users');

      // Scan candidates and fix mismatches
      final statesSnapshot = await _firestore.collection('states').get();
      int fixedCount = 0;

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (var bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (var wardDoc in wardsSnapshot.docs) {
              final candidatesSnapshot = await wardDoc.reference.collection('candidates').get();

              for (var candidateDoc in candidatesSnapshot.docs) {
                final candidateData = candidateDoc.data();
                final candidateId = candidateDoc.id;
                final storedUserId = candidateData['userId'] as String?;
                final candidateEmail = candidateData['email'] as String?;
                final candidateName = candidateData['name'] as String? ?? 'Unknown';
                final candidateStatus = candidateData['status'] as String? ?? 'unknown';

                print('🔍 Checking candidate: $candidateName (ID: $candidateId)');
                print('   Status: $candidateStatus');
                print('   Stored userId: $storedUserId');

                // Check if userId exists and is valid
                if (storedUserId != null) {
                  final userDoc = await _firestore.collection('users').doc(storedUserId).get();
                  if (!userDoc.exists) {
                    print('   ❌ User document does not exist for userId: $storedUserId');

                    // Try to find correct userId by email
                    if (candidateEmail != null) {
                      final correctUserId = userMap[candidateEmail];
                      if (correctUserId != null) {
                        print('   ✅ Found matching user by email: $correctUserId');

                        await candidateDoc.reference.update({
                          'userId': correctUserId,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        fixedCount++;
                        print('   ✅ Fixed candidate userId');
                        print('');
                        continue;
                      }
                    }

                    // Try to find candidate-role users that might match
                    print('   🔍 Looking for candidate-role users...');
                    for (var userId in userRoleMap.keys) {
                      final userDoc = await _firestore.collection('users').doc(userId).get();
                      final userData = userDoc.data();
                      final userName = userData?['name'] as String?;
                      final userEmail = userData?['email'] as String?;

                      // Match by name or email if available
                      if (userName == candidateName ||
                          (userEmail != null && candidateEmail != null && userEmail == candidateEmail)) {
                        print('   ✅ Found matching candidate user: $userId ($userName)');

                        await candidateDoc.reference.update({
                          'userId': userId,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        fixedCount++;
                        print('   ✅ Fixed candidate userId by role/name match');
                        print('');
                        break;
                      }
                    }
                  } else {
                    print('   ✅ User document exists');
                    final userData = userDoc.data();
                    final fcmToken = userData?['fcmToken'];
                    print('   FCM Token: ${fcmToken != null ? 'Present' : 'MISSING'}');
                  }
                } else {
                  print('   ⚠️  No userId field in candidate document');
                }
                print('');
              }
            }
          }
        }
      }

      print('✅ Auto-fix completed. Fixed $fixedCount candidates.');
    } catch (e) {
      print('❌ Error during auto-fix: $e');
    }
  }
}

// TEMPORARY DEBUG SCREEN - Add this to your app temporarily
class DebugCandidateFixScreen extends StatefulWidget {
  const DebugCandidateFixScreen({super.key});

  @override
  State<DebugCandidateFixScreen> createState() => _DebugCandidateFixScreenState();
}

class _DebugCandidateFixScreenState extends State<DebugCandidateFixScreen> {
  final CandidateUserIdFixer _fixer = CandidateUserIdFixer();
  String _output = '';
  bool _isRunning = false;

  void _addOutput(String text) {
    setState(() {
      _output += text + '\n';
    });
    print(text); // Also print to console
  }

  Future<void> _runCheckCurrentUser() async {
    setState(() => _isRunning = true);
    _addOutput('=== CHECKING CURRENT USER ===');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _addOutput('❌ No current user logged in');
        return;
      }

      _addOutput('👤 Current User:');
      _addOutput('   UID: ${currentUser.uid}');
      _addOutput('   Email: ${currentUser.email}');
      _addOutput('   Display Name: ${currentUser.displayName}');

      // Check user document
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final fcmToken = userData?['fcmToken'];
        _addOutput('   FCM Token: ${fcmToken != null ? "Present (${fcmToken.substring(0, 20)}...)" : "MISSING"}');
      } else {
        _addOutput('   User document: DOES NOT EXIST');
      }
    } catch (e) {
      _addOutput('❌ Error checking current user: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _runFindMismatched() async {
    setState(() => _isRunning = true);
    _addOutput('\n=== SCANNING CANDIDATES ===');

    try {
      await _fixer.findMismatchedCandidates();
      _addOutput('✅ Finished scanning all candidates');
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _runAutoFix() async {
    setState(() => _isRunning = true);
    _addOutput('\n=== AUTO-FIXING CANDIDATES ===');

    try {
      await _fixer.autoFixCandidates();
      _addOutput('✅ Auto-fix completed');
    } catch (e) {
      _addOutput('❌ Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Fix Candidate userId'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runCheckCurrentUser,
                  child: const Text('1. Check Current User'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runFindMismatched,
                  child: const Text('2. Find Mismatched Candidates'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runAutoFix,
                  child: const Text('3. Auto-Fix Candidates'),
                ),
                const SizedBox(height: 16),
                if (_isRunning)
                  const CircularProgressIndicator()
                else
                  const Text('Click buttons in order (1→2→3)'),
              ],
            ),
          ),

          // Output area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? 'Output will appear here...\n\nMake sure you are logged in as a candidate!' : _output,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// HOW TO USE:
// 1. Temporarily add this screen to your app's navigation
// 2. Navigate to it while logged in as a candidate
// 3. Click buttons in order: Check Current User → Find Mismatched → Auto-Fix
// 4. Check the output and console logs
// 5. Remove this screen after fixing

// Example navigation addition (add to your routes):
/*
GetPage(
  name: '/debug-candidate-fix',
  page: () => const DebugCandidateFixScreen(),
),
*/