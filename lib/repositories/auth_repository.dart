import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
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
        wardId: '',
        cityId: '',
        xpPoints: 0,
        premium: false,
        createdAt: DateTime.now(),
      );
      await userDoc.set(userModel.toJson());
    } else {
      // Update existing user
      final existingData = userSnapshot.data()!;
      final updatedData = {
        ...existingData,
        'phone': firebaseUser.phoneNumber ?? existingData['phone'],
        'email': firebaseUser.email ?? existingData['email'],
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
}