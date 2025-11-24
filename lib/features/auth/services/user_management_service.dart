import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/performance_monitor.dart';
import '../../../features/user/models/user_model.dart';

class UserManagementService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user in Firestore - Optimized for performance
  Future<void> createOrUpdateUser(
    User firebaseUser, {
    String? name,
    String? role,
  }) async {
    startPerformanceTimer('user_data_setup');

    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        AppLogger.auth('👤 Creating new user record...');
        // Create new user with optimized data structure
        final userModel = UserModel(
          uid: firebaseUser.uid,
          name: name ?? firebaseUser.displayName ?? 'User',
          phone: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email,
          role: role ?? '', // Default to empty string for first-time users
          roleSelected: false,
          profileCompleted: false,
          electionAreas: [], // Will be set during profile completion
          xpPoints: 0,
          premium: false,
          createdAt: DateTime.now(),
        );

        // Use set with merge to ensure atomic operation
        await userDoc.set(userModel.toJson(), SetOptions(merge: true));
        AppLogger.auth('✅ New user created successfully');
      } else {
        AppLogger.auth('🔄 Updating existing user record...');
        // Update existing user with minimal data transfer
        final updatedData = {
          'phone': firebaseUser.phoneNumber,
          'email': firebaseUser.email,
          'lastLogin': FieldValue.serverTimestamp(), // Track login time
        };

        // Only update non-null values to minimize data transfer
        final filteredData = Map<String, dynamic>.fromEntries(
          updatedData.entries.where((entry) => entry.value != null),
        );

        if (filteredData.isNotEmpty) {
          await userDoc.update(filteredData);
          AppLogger.auth('✅ User data updated successfully');
        } else {
          AppLogger.auth('ℹ️ No user data changes needed');
        }
      }

      stopPerformanceTimer('user_data_setup');
    } catch (e) {
      stopPerformanceTimer('user_data_setup');
      AppLogger.auth('Error in createOrUpdateUser: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
