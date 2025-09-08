import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../controllers/login_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/candidate_controller.dart';
import '../services/admob_service.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Phone Authentication
  Future<void> verifyPhoneNumber(String phoneNumber, Function(String) onCodeSent) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw e;
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> signInWithOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw 'Google sign-in cancelled';

    // Log Google response
    print('Google Sign-In Response:');
    print('Display Name: ${googleUser.displayName}');
    print('Email: ${googleUser.email}');
    print('Photo URL: ${googleUser.photoUrl}');
    print('ID: ${googleUser.id}');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    // Log Firebase user details
    final user = userCredential.user;
    print('Firebase User:');
    print('UID: ${user?.uid}');
    print('Display Name: ${user?.displayName}');
    print('Email: ${user?.email}');
    print('Phone Number: ${user?.phoneNumber}');
    print('Photo URL: ${user?.photoURL}');

    return userCredential;
  }

  // Create or update user in Firestore
  Future<void> createOrUpdateUser(User firebaseUser, {String? name, String? role}) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final userSnapshot = await userDoc.get();

    if (!userSnapshot.exists) {
      // Create new user
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name ?? firebaseUser.displayName ?? 'User',
        phone: firebaseUser.phoneNumber ?? '',
        email: firebaseUser.email,
        role: role ?? 'voter',
        roleSelected: false,
        wardId: '',
        cityId: '',
        xpPoints: 0,
        premium: false,
        createdAt: DateTime.now(),
        photoURL: firebaseUser.photoURL,
      );
      await userDoc.set(userModel.toJson());
    } else {
      // Update existing user
      final existingData = userSnapshot.data()!;
      final updatedData = {
        ...existingData,
        'phone': firebaseUser.phoneNumber ?? existingData['phone'],
        'email': firebaseUser.email ?? existingData['email'],
        'photoURL': firebaseUser.photoURL ?? existingData['photoURL'],
      };
      await userDoc.update(updatedData);
    }
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Delete account and all associated data
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      // If no user is currently signed in, still clear cache and controllers
      await _clearAppCache();
      await _clearAllControllers();
      return; // Consider this a successful "deletion" since user is already gone
    }

    final userId = user.uid;
    final batch = _firestore.batch();

    try {
      // Get user document to check if they're a candidate
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final isCandidate = userData?['role'] == 'candidate';

      // Delete user document and subcollections
      await _deleteUserDocument(userId, batch);

      // Delete conversations and messages
      await _deleteConversations(userId, batch);

      // Delete rewards
      await _deleteRewards(userId, batch);

      // Delete XP transactions
      await _deleteXpTransactions(userId, batch);

      // If user is a candidate, delete candidate data
      if (isCandidate) {
        await _deleteCandidateData(userId, batch);
      }

      // Commit all Firestore deletions
      await batch.commit();

      // Delete from Firebase Auth BEFORE clearing cache
      await user.delete();

      // Force sign out from Google (if applicable)
      await _googleSignIn.signOut();

      // Clear all local app data and cache AFTER auth deletion
      await _clearAppCache();

      // Clear all GetX controllers
      await _clearAllControllers();

    } catch (e) {
      // If Firestore deletion fails, still try to delete from Auth
      try {
        await user.delete();
        await _googleSignIn.signOut();
        await _clearAppCache();
        await _clearAllControllers();
      } catch (authError) {
        // If auth deletion also fails, still clear cache and controllers
        try {
          await _clearAppCache();
          await _clearAllControllers();
        } catch (cacheError) {
          // At minimum, try to clear controllers
          await _clearAllControllers();
        }
        // Don't throw auth error if user was already deleted
        if (!authError.toString().contains('no-current-user')) {
          throw 'Failed to delete account: $authError';
        }
      }
      // Don't throw Firestore errors if they are just permission/indexing issues
      if (!e.toString().contains('failed-precondition') && !e.toString().contains('permission-denied')) {
        throw 'Failed to delete user data: $e';
      }
    }
  }

  // Clear all app cache and local storage
  Future<void> _clearAppCache() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear Firebase local cache (handle errors gracefully)
      try {
        await _firestore.clearPersistence();
      } catch (cacheError) {
        // Cache clearing might fail due to various reasons (indexing, etc.)
        // This is not critical for account deletion, so we continue
        print('Warning: Firebase cache clearing failed: $cacheError');
      }

      // Clear any cached data in Firebase Auth
      await _firebaseAuth.signOut();

    } catch (e) {
      print('Warning: Failed to clear some cache: $e');
      // Don't throw here as cache clearing failure shouldn't stop account deletion
    }
  }

  // Clear all GetX controllers
  Future<void> _clearAllControllers() async {
    try {
      // Delete all registered controllers (but don't reset GetX navigation)
      if (Get.isRegistered<LoginController>()) {
        Get.delete<LoginController>(force: true);
      }
      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }
      if (Get.isRegistered<CandidateController>()) {
        Get.delete<CandidateController>(force: true);
      }
      if (Get.isRegistered<AdMobService>()) {
        Get.delete<AdMobService>(force: true);
      }

    } catch (e) {
      print('Warning: Failed to clear some controllers: $e');
    }
  }

  Future<void> _deleteUserDocument(String userId, WriteBatch batch) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Delete following subcollection
    final followingSnapshot = await userRef.collection('following').get();
    for (final doc in followingSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete main user document
    batch.delete(userRef);
  }

  Future<void> _deleteConversations(String userId, WriteBatch batch) async {
    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .get();

    for (final conversationDoc in conversationsSnapshot.docs) {
      // Delete messages subcollection
      final messagesSnapshot = await conversationDoc.reference.collection('messages').get();
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete conversation document
      batch.delete(conversationDoc.reference);
    }
  }

  Future<void> _deleteRewards(String userId, WriteBatch batch) async {
    final rewardsSnapshot = await _firestore
        .collection('rewards')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in rewardsSnapshot.docs) {
      batch.delete(doc.reference);
    }
  }

  Future<void> _deleteXpTransactions(String userId, WriteBatch batch) async {
    final xpTransactionsSnapshot = await _firestore
        .collection('xp_transactions')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in xpTransactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }
  }

  Future<void> _deleteCandidateData(String userId, WriteBatch batch) async {
    // Find candidate document by userId (assuming there's a userId field in candidates)
    final candidateSnapshot = await _firestore
        .collection('candidates')
        .where('userId', isEqualTo: userId)
        .get();

    for (final candidateDoc in candidateSnapshot.docs) {
      // Delete followers subcollection
      final followersSnapshot = await candidateDoc.reference.collection('followers').get();
      for (final followerDoc in followersSnapshot.docs) {
        batch.delete(followerDoc.reference);
      }

      // Delete candidate document
      batch.delete(candidateDoc.reference);
    }
  }
}