# 🔧 Authentication Troubleshooting Guide

## Overview

This guide helps you diagnose and fix common authentication issues in the JanMat app. Use the AppLogger to get detailed information about what's happening during the login process.

## 🚀 Quick Diagnosis

### Step 1: Enable Auth Logging
```dart
// In main.dart
AppLogger.configure(
  auth: true,        // Show authentication operations
  network: true,     // Show Firebase calls
  cache: true,       // Show user data caching
  database: true,    // Show Firestore operations
  performance: true, // Show timing metrics
);
```

### Step 2: Run the App
```bash
flutter run --debug
```

### Step 3: Check the Console
Look for these patterns in the logs to identify issues.

## 🚨 Common Issues & Solutions

### Issue 1: "No OTP Received"

#### Symptoms
- User enters phone number
- "OTP sent" message appears
- No SMS received on phone

#### Possible Causes
1. **Invalid Phone Number Format**
2. **Network Issues**
3. **Firebase Configuration**
4. **reCAPTCHA Failure**
5. **Carrier Blocking**

#### Diagnosis Steps
```dart
// Check logs for:
AppLogger.auth('Starting phone verification for: +91XXXXXXXXXX');
AppLogger.network('Phone verification setup completed');
AppLogger.authError('Phone verification failed');
```

#### Solutions

**For Invalid Phone Number:**
```dart
// Ensure phone number format is correct
String phoneNumber = '+91' + controller.phoneController.text;
assert(phoneNumber.length == 13, 'Phone number must be 13 characters');
```

**For Network Issues:**
- Check internet connection
- Try different network (WiFi vs Mobile data)
- Disable VPN if active

**For Firebase Issues:**
```dart
// Check Firebase console
// 1. Phone authentication enabled
// 2. reCAPTCHA configured
// 3. Test phone numbers added (for development)
```

**For reCAPTCHA Issues:**
- Complete the reCAPTCHA challenge
- Try again after a few minutes
- Check if browser opens for verification

#### Test Commands
```dart
// Add test phone number in Firebase Console
// Authentication > Sign-in method > Phone > Test phone numbers
// Example: +91 9999999999 with OTP: 123456
```

### Issue 2: "Invalid OTP" Error

#### Symptoms
- OTP SMS received
- Entering correct OTP shows "Invalid OTP"
- Multiple attempts fail

#### Possible Causes
1. **OTP Timeout** (60 seconds)
2. **Wrong Verification ID**
3. **Firebase Auth State Issues**
4. **App Restart During Process**

#### Diagnosis Steps
```dart
// Check logs for:
AppLogger.auth('OTP verification successful');
AppLogger.authError('Invalid OTP');
AppLogger.network('Firebase auth failed');
```

#### Solutions

**For OTP Timeout:**
```dart
// Check OTP timer in UI
// Resend OTP after 60 seconds
// Timer resets on resend
```

**For Verification ID Issues:**
```dart
// Ensure verificationId is stored correctly
debugPrint('Verification ID: $verificationId');
// Should be a non-empty string
```

**For Firebase State:**
```dart
// Check Firebase Auth instance
final currentUser = FirebaseAuth.instance.currentUser;
debugPrint('Current user: ${currentUser?.uid ?? 'null'}');
```

#### Test Commands
```dart
// Manual OTP verification test
await FirebaseAuth.instance.signInWithCredential(
  PhoneAuthProvider.credential(
    verificationId: verificationId,
    smsCode: '123456'
  )
);
```

### Issue 3: "Google Sign-In Fails"

#### Symptoms
- Google account picker appears
- Authentication fails after selection
- "Sign-in failed" error message

#### Possible Causes
1. **Google Services Configuration**
2. **SHA-1 Certificate Issues**
3. **Network Connectivity**
4. **Account Permissions**
5. **Firebase Project Settings**

#### Diagnosis Steps
```dart
// Check logs for:
AppLogger.auth('Starting Google Sign-In process');
AppLogger.network('Google auth failed');
AppLogger.authError('Google sign-in failed');
```

#### Solutions

**For Google Services:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application>
    <!-- Add this meta-data -->
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version" />
</application>
```

**For SHA-1 Certificate:**
```bash
# Get SHA-1 from debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Add to Firebase Console
# Project Settings > General > Your apps > Add fingerprint
```

**For Network Issues:**
- Ensure stable internet connection
- Try different Google account
- Clear Google Play Services cache

#### Test Commands
```dart
// Test Google Sign-In manually
final GoogleSignIn googleSignIn = GoogleSignIn();
final account = await googleSignIn.signIn();
debugPrint('Google account: ${account?.email}');
```

### Issue 4: "Stuck on Loading Screen"

#### Symptoms
- Authentication successful
- App shows loading indefinitely
- No navigation to next screen

#### Possible Causes
1. **Profile Completion Check Failing**
2. **Firestore Permission Issues**
3. **Navigation Logic Error**
4. **Controller Initialization Issues**

#### Diagnosis Steps
```dart
// Check logs for:
AppLogger.auth('Checking profile completion');
AppLogger.database('User document fetched');
AppLogger.auth('Navigation decision made');
AppLogger.authError('Error during profile check');
```

#### Solutions

**For Profile Check Issues:**
```dart
// Check user document manually
final user = FirebaseAuth.instance.currentUser;
final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user?.uid)
    .get();
debugPrint('User document exists: ${doc.exists}');
debugPrint('User data: ${doc.data()}');
```

**For Firestore Permissions:**
```javascript
// Firestore Rules - ensure user can read their own document
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**For Navigation Issues:**
```dart
// Check GetX routes
Get.routing.printHistory();
Get.currentRoute;
```

#### Test Commands
```dart
// Force navigation for testing
Get.offAllNamed('/home');
```

### Issue 5: "Profile Not Saving"

#### Symptoms
- User fills profile information
- Clicks save button
- Profile doesn't update
- Stays on same screen

#### Possible Causes
1. **Firestore Write Permissions**
2. **Network Connectivity**
3. **Data Validation Issues**
4. **Controller State Problems**

#### Diagnosis Steps
```dart
// Check logs for:
AppLogger.auth('Starting profile save');
AppLogger.database('Updating user profile');
AppLogger.auth('Profile saved successfully');
AppLogger.authError('Profile save failed');
```

#### Solutions

**For Firestore Permissions:**
```javascript
// Ensure write permissions
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**For Network Issues:**
- Check internet connection
- Try saving again
- Check Firebase console for errors

**For Data Validation:**
```dart
// Check required fields
final profileData = {
  'name': nameController.text.isNotEmpty,
  'role': selectedRole != null,
  'districtId': selectedDistrict != null,
};
debugPrint('Validation results: $profileData');
```

#### Test Commands
```dart
// Manual profile update test
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'name': 'Test Name',
      'profileCompleted': true,
    });
```

### Issue 6: "Wrong Screen After Login"

#### Symptoms
- User authenticates successfully
- Navigates to wrong screen
- Skips role selection or profile completion

#### Possible Causes
1. **User Document Corruption**
2. **Navigation Logic Bug**
3. **Field Value Issues**
4. **Controller State Problems**

#### Diagnosis Steps
```dart
// Check logs for:
AppLogger.auth('Navigation decision: roleSelected=false');
AppLogger.auth('Navigation decision: profileCompleted=false');
AppLogger.auth('Navigating to role selection');
AppLogger.auth('Navigating to profile completion');
AppLogger.auth('Navigating to home');
```

#### Solutions

**For User Document Issues:**
```dart
// Check and fix user document
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

final data = userDoc.data() ?? {};
debugPrint('Current user data: $data');

// Fix missing fields
if (!data.containsKey('roleSelected')) {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({'roleSelected': false});
}
```

**For Navigation Logic:**
```dart
// Check navigation conditions
final roleSelected = userData['roleSelected'] ?? false;
final profileCompleted = userData['profileCompleted'] ?? false;

debugPrint('Role selected: $roleSelected');
debugPrint('Profile completed: $profileCompleted');

if (!roleSelected) {
  Get.offAllNamed('/role-selection');
} else if (!profileCompleted) {
  Get.offAllNamed('/profile-completion');
} else {
  Get.offAllNamed('/home');
}
```

#### Test Commands
```dart
// Reset user state for testing
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'roleSelected': false,
      'profileCompleted': false,
    });
```

## 🔍 Advanced Debugging

### Firebase Console Checks

#### Authentication
1. Go to Firebase Console > Authentication
2. Check recent sign-ins
3. Verify phone numbers in test list
4. Check for blocked accounts

#### Firestore
1. Go to Firebase Console > Firestore
2. Query user documents
3. Check security rules
4. Monitor read/write operations

#### Crashlytics (if enabled)
1. Check for authentication-related crashes
2. Review error patterns
3. Monitor user flow completion

### Network Debugging

#### Check Connectivity
```dart
// Test network connectivity
final connectivity = await Connectivity().checkConnectivity();
debugPrint('Connectivity: $connectivity');

// Test Firebase reachability
try {
  await FirebaseFirestore.instance.collection('test').doc('test').get();
  debugPrint('Firebase reachable');
} catch (e) {
  debugPrint('Firebase unreachable: $e');
}
```

#### DNS and Proxy Issues
```bash
# Test DNS resolution
nslookup firestore.googleapis.com

# Test with different DNS
# 8.8.8.8 (Google DNS)
# 1.1.1.1 (Cloudflare DNS)
```

### Device-Specific Issues

#### Android Issues
- Check Google Play Services version
- Verify SHA-1 certificate
- Test on different Android versions
- Check device permissions

#### iOS Issues
- Verify iOS deployment target
- Check Info.plist configuration
- Test on different iOS versions
- Verify app store provisioning

### Performance Issues

#### Slow Authentication
```dart
// Check timing logs
AppLogger.performance('Phone verification time: ${duration}ms');
AppLogger.performance('Google sign-in time: ${duration}ms');

// Expected times:
// Phone OTP send: 2-5 seconds
// Google auth: 3-8 seconds
// Profile save: 0.5-2 seconds
```

#### Memory Issues
```dart
// Check for memory leaks
debugPrint('Memory usage: ${ProcessInfo.currentRss}');
debugPrint('Controller count: ${GetInstance().getControllers().length}');
```

## 🧪 Testing Scenarios

### Comprehensive Test Checklist

#### Phone Authentication
- [ ] Valid 10-digit Indian number
- [ ] Invalid number formats
- [ ] Network interruption during OTP send
- [ ] Network interruption during verification
- [ ] OTP timeout and resend
- [ ] Multiple OTP attempts
- [ ] App restart during verification

#### Google Authentication
- [ ] First-time Google login
- [ ] Returning user (smart account switching)
- [ ] Account picker cancellation
- [ ] Multiple Google accounts
- [ ] Network interruption
- [ ] Invalid Google account
- [ ] Google Play Services issues

#### Profile Flow
- [ ] Role selection (voter/candidate)
- [ ] Profile completion with all fields
- [ ] Profile completion with minimal fields
- [ ] Photo upload
- [ ] Location selection
- [ ] Party selection
- [ ] Save interruption (network issues)

#### Navigation
- [ ] New user complete flow
- [ ] Existing user login
- [ ] Incomplete profile recovery
- [ ] App restart after login
- [ ] Logout and re-login

### Automated Testing

#### Unit Tests
```dart
// Test auth controller methods
test('Phone number validation', () {
  expect(AuthController().isValidPhoneNumber('+919876543210'), true);
  expect(AuthController().isValidPhoneNumber('9876543210'), false);
});

// Test repository methods
test('User creation', () async {
  final user = await authRepository.createOrUpdateUser(mockFirebaseUser);
  expect(user, isNotNull);
});
```

#### Integration Tests
```dart
// Test complete auth flow
testWidgets('Complete authentication flow', (tester) async {
  // Setup
  await tester.pumpWidget(const MyApp());

  // Navigate to login
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  // Enter phone number
  await tester.enterText(find.byType(TextField), '9876543210');
  await tester.tap(find.text('Send OTP'));
  await tester.pumpAndSettle();

  // Verify navigation to OTP screen
  expect(find.text('Enter OTP'), findsOneWidget);
});
```

## 📞 Getting Help

### Debug Information to Collect

When reporting authentication issues, include:

1. **Device Information**
   - OS version (Android/iOS)
   - App version
   - Device model

2. **Network Information**
   - Connection type (WiFi/Mobile)
   - Network provider
   - Signal strength

3. **Log Excerpts**
   ```dart
   // Copy relevant logs from console
   AppLogger.configure(auth: true, network: true, database: true);
   // Run authentication flow
   // Copy console output
   ```

4. **Firebase Console Data**
   - Authentication logs
   - Firestore document state
   - Error reports

5. **Steps to Reproduce**
   - Exact sequence of actions
   - Expected vs actual behavior
   - Frequency of occurrence

### Emergency Fixes

#### Complete Auth Reset (Testing Only)
```dart
// WARNING: This will log out the user and clear all auth data
// Use only for testing/debugging

await FirebaseAuth.instance.signOut();
await GoogleSignIn().signOut();
await SharedPreferences.getInstance().then((prefs) => prefs.clear());
await UserCacheService().clearUserCache();
Get.offAllNamed('/login');
```

#### Force Profile Completion (Testing Only)
```dart
// Force complete a user's profile for testing
final user = FirebaseAuth.instance.currentUser;
await FirebaseFirestore.instance
    .collection('users')
    .doc(user?.uid)
    .update({
      'roleSelected': true,
      'profileCompleted': true,
      'role': 'candidate',
      'name': 'Test User',
    });
```

This troubleshooting guide should help you resolve most authentication issues in the JanMat app. If problems persist, check the logs and Firebase console for additional clues.