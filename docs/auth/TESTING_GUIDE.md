# 🧪 Authentication Testing Guide

## Overview

This guide provides comprehensive testing scenarios for the authentication flow in the JanMat app. It covers manual testing, automated testing, and edge cases to ensure robust authentication functionality.

## 🚀 Quick Test Setup

### 1. Enable Test Logging
```dart
// In main.dart
AppLogger.configure(
  auth: true,        // Show all auth operations
  network: true,     // Show Firebase calls
  cache: true,       // Show user data caching
  database: true,    // Show Firestore operations
  performance: true, // Show timing metrics
);
```

### 2. Firebase Test Configuration
```javascript
// Firebase Console > Authentication > Sign-in method > Phone
// Add test phone numbers for development
[
  { phone: "+91 9999999999", code: "123456" },
  { phone: "+91 8888888888", code: "123456" },
  { phone: "+91 7777777777", code: "123456" }
]
```

### 3. Test Commands
```bash
# Run with test configuration
flutter run --debug --dart-define=TEST_MODE=true
```

## 📋 Manual Testing Checklist

### Phone Authentication Tests

#### ✅ Basic Phone Flow
- [ ] Enter valid 10-digit Indian number (+91 prefix auto-added)
- [ ] Click "Send OTP" button
- [ ] Verify reCAPTCHA challenge appears (if required)
- [ ] Verify "OTP sent" success message
- [ ] Verify navigation to OTP screen
- [ ] Enter 6-digit OTP from test numbers
- [ ] Verify auto-submit on 6th digit
- [ ] Verify successful authentication
- [ ] Verify navigation to role selection

#### ✅ OTP Timer & Resend
- [ ] Verify 60-second countdown starts
- [ ] Verify "Resend OTP" button disabled during countdown
- [ ] Wait for timer to expire
- [ ] Verify "Resend OTP" button becomes enabled
- [ ] Click resend and verify new OTP sent
- [ ] Verify timer resets to 60 seconds

#### ✅ Phone Number Validation
- [ ] Try empty phone number → Should show error
- [ ] Try 9 digits → Should show error
- [ ] Try 11 digits → Should show error
- [ ] Try non-numeric characters → Should show error
- [ ] Try valid 10 digits → Should proceed

#### ✅ OTP Validation
- [ ] Try empty OTP → Should show error
- [ ] Try 5 digits → Should show error
- [ ] Try 7 digits → Should show error
- [ ] Try wrong OTP → Should show error
- [ ] Try expired OTP → Should show error

#### ✅ Error Recovery
- [ ] Network disconnect during OTP send → Should show network error
- [ ] Network disconnect during verification → Should show network error
- [ ] Invalid phone number → Should show validation error
- [ ] Too many attempts → Should show rate limit error
- [ ] App restart during OTP process → Should handle gracefully

### Google Authentication Tests

#### ✅ Basic Google Flow
- [ ] Click "Continue with Google" button
- [ ] Verify Google account picker appears
- [ ] Select Google account
- [ ] Verify OAuth consent screen (first time)
- [ ] Verify successful authentication
- [ ] Verify navigation to role selection

#### ✅ Smart Account Switching
- [ ] Complete Google login once
- [ ] Logout and return to login screen
- [ ] Verify "Continue as [Name]" button appears
- [ ] Click button → Should login instantly
- [ ] Verify "Sign in with different account" option
- [ ] Click different account option → Should show picker

#### ✅ Multiple Account Handling
- [ ] Login with Account A
- [ ] Logout
- [ ] Login with Account B
- [ ] Verify Account B profile loads
- [ ] Switch back to Account A
- [ ] Verify Account A profile loads

#### ✅ Google Error Cases
- [ ] Cancel account picker → Should return to login
- [ ] Network disconnect during OAuth → Should show error
- [ ] Invalid Google account → Should show error
- [ ] Google Play Services outdated → Should show error
- [ ] Permission denied → Should show error

### Profile Setup Tests

#### ✅ Role Selection
- [ ] Verify voter card displays correctly
- [ ] Verify candidate card displays correctly
- [ ] Click voter card → Should highlight
- [ ] Click candidate card → Should highlight
- [ ] Click Continue without selection → Should show error
- [ ] Select role and click Continue → Should navigate to profile completion

#### ✅ Profile Completion (Voter)
- [ ] Verify basic info form loads
- [ ] Fill name field
- [ ] Select district
- [ ] Select body/ward
- [ ] Click Save → Should show success
- [ ] Verify navigation to home screen

#### ✅ Profile Completion (Candidate)
- [ ] Verify extended form loads
- [ ] Fill all required fields (name, party, location)
- [ ] Upload profile photo
- [ ] Fill optional fields (bio, experience, etc.)
- [ ] Click Save → Should show success
- [ ] Verify navigation to home screen

#### ✅ Profile Validation
- [ ] Try saving with empty name → Should show error
- [ ] Try saving without district → Should show error
- [ ] Try saving without ward → Should show error
- [ ] Upload invalid photo format → Should show error
- [ ] Upload photo too large → Should show error

### Navigation Tests

#### ✅ New User Flow
- [ ] Phone auth → Role selection → Profile completion → Home
- [ ] Google auth → Role selection → Profile completion → Home
- [ ] Verify each step completes before proceeding

#### ✅ Existing User Flow
- [ ] Login with existing account
- [ ] Verify direct navigation to home (if profile complete)
- [ ] Verify navigation to profile completion (if incomplete)
- [ ] Verify navigation to role selection (if role not selected)

#### ✅ App Restart Tests
- [ ] Complete authentication flow
- [ ] Close and restart app
- [ ] Verify automatic login (if session valid)
- [ ] Verify correct screen navigation

#### ✅ Logout/Login Tests
- [ ] Complete authentication
- [ ] Logout from app
- [ ] Verify return to login screen
- [ ] Verify clean state (no cached data)
- [ ] Login again → Should work normally

## 🔧 Automated Testing

### Unit Tests

#### Auth Controller Tests
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:janmat/features/auth/controllers/auth_controller.dart';

void main() {
  group('AuthController', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController();
    });

    test('Phone number validation', () {
      expect(controller.isValidPhoneNumber('+919876543210'), true);
      expect(controller.isValidPhoneNumber('9876543210'), false);
      expect(controller.isValidPhoneNumber('+91987654321'), false);
      expect(controller.isValidPhoneNumber('abc1234567'), false);
    });

    test('OTP validation', () {
      expect(controller.isValidOTP('123456'), true);
      expect(controller.isValidOTP('12345'), false);
      expect(controller.isValidOTP('1234567'), false);
      expect(controller.isValidOTP('abc123'), false);
    });

    test('Navigation logic', () {
      // Test role selection navigation
      expect(controller.getNextScreen({'roleSelected': false}), '/role-selection');
      expect(controller.getNextScreen({'roleSelected': true, 'profileCompleted': false}), '/profile-completion');
      expect(controller.getNextScreen({'roleSelected': true, 'profileCompleted': true}), '/home');
    });
  });
}
```

#### Auth Repository Tests
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:janmat/features/auth/repositories/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    late AuthRepository repository;

    setUp(() {
      repository = AuthRepository();
    });

    test('User data preparation', () async {
      final googleUser = MockGoogleSignInAccount();
      final userData = await repository.prepareUserDataLocally(googleUser);

      expect(userData['name'], isNotNull);
      expect(userData['email'], isNotNull);
      expect(userData['photoURL'], isNotNull);
    });

    test('Firebase user creation', () async {
      final mockUser = MockUser();
      await repository.createOrUpdateUser(mockUser);

      // Verify Firestore document created
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(mockUser.uid)
          .get();

      expect(doc.exists, true);
      expect(doc.data()!['name'], mockUser.displayName);
    });
  });
}
```

### Integration Tests

#### Complete Authentication Flow
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:janmat/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('Complete phone authentication flow', (tester) async {
      // Setup
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to login
      expect(find.text('Welcome'), findsOneWidget);

      // Enter phone number
      await tester.enterText(find.byType(TextField), '9999999999');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      // Verify OTP screen
      expect(find.text('Enter OTP'), findsOneWidget);

      // Enter OTP
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      // Verify role selection screen
      expect(find.text('Choose Your Role'), findsOneWidget);

      // Select candidate role
      await tester.tap(find.text('Candidate'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify profile completion screen
      expect(find.text('Complete Your Profile'), findsOneWidget);

      // Fill profile and save
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify home screen
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Google authentication flow', (tester) async {
      // Setup
      await tester.pumpWidget(const MyApp());

      // Mock Google Sign-In
      // Note: Actual Google Sign-In requires platform-specific setup

      // Verify navigation flow
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

### Widget Tests

#### Login Screen Tests
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:janmat/features/auth/screens/login_screen.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('Displays login form', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('Phone number input validation', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Enter invalid phone number
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Send OTP'));
      await tester.pump();

      // Should show error
      expect(find.text('Please enter a valid 10-digit phone number'), findsOneWidget);
    });

    testWidgets('OTP screen navigation', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Mock successful OTP send
      // Verify navigation to OTP screen
      expect(find.text('Enter OTP'), findsOneWidget);
    });
  });
}
```

## 🎯 Edge Cases & Stress Testing

### Network Conditions
- [ ] Airplane mode during authentication
- [ ] Poor network connectivity (2G speeds)
- [ ] Network switch during OTP process
- [ ] VPN enabled/disabled
- [ ] Firewall blocking Firebase

### Device Conditions
- [ ] Low memory (< 100MB available)
- [ ] Low storage (< 50MB available)
- [ ] Background app refresh disabled
- [ ] Push notifications disabled
- [ ] Location services disabled

### Firebase Conditions
- [ ] Firestore offline mode
- [ ] Authentication service down
- [ ] Realtime Database issues
- [ ] Storage quota exceeded
- [ ] Security rules blocking access

### User Behavior
- [ ] Rapid button clicking
- [ ] App minimization during auth
- [ ] Screen rotation during forms
- [ ] Keyboard show/hide during input
- [ ] Copy/paste in text fields

## 📊 Performance Testing

### Authentication Speed Tests
```dart
// Measure authentication performance
void testAuthPerformance() async {
  final stopwatch = Stopwatch()..start();

  // Phone authentication
  await authController.sendOTP();
  final otpSendTime = stopwatch.elapsedMilliseconds;

  // OTP verification
  await authController.verifyOTP();
  final otpVerifyTime = stopwatch.elapsedMilliseconds - otpSendTime;

  // Profile completion
  await profileController.saveProfile();
  final profileSaveTime = stopwatch.elapsedMilliseconds - otpVerifyTime;

  debugPrint('Performance Results:');
  debugPrint('OTP Send: ${otpSendTime}ms');
  debugPrint('OTP Verify: ${otpVerifyTime}ms');
  debugPrint('Profile Save: ${profileSaveTime}ms');
  debugPrint('Total: ${stopwatch.elapsedMilliseconds}ms');
}
```

### Memory Leak Tests
```dart
// Test for controller memory leaks
void testMemoryLeaks() async {
  final initialControllerCount = GetInstance().getControllers().length;

  // Navigate through auth flow
  await navigateThroughAuthFlow();

  // Check controller cleanup
  final finalControllerCount = GetInstance().getControllers().length;
  expect(finalControllerCount, equals(initialControllerCount));
}
```

### Concurrent User Tests
```dart
// Test multiple authentication attempts
void testConcurrentAuth() async {
  final futures = <Future>[];

  for (int i = 0; i < 10; i++) {
    futures.add(authController.sendOTP());
  }

  final results = await Future.wait(futures);
  final successCount = results.where((result) => result == true).length;

  debugPrint('Concurrent auth success rate: $successCount/10');
}
```

## 🔍 Debugging Failed Tests

### Common Test Failures

#### Firebase Test Numbers Not Working
```dart
// Check Firebase Console configuration
// Authentication > Sign-in method > Phone > Test phone numbers
// Format: +91 9999999999 (with spaces)
// Code: 123456 (6 digits)
```

#### Widget Not Found
```dart
// Use correct keys or text finders
expect(find.byKey(const Key('phone_input')), findsOneWidget);
expect(find.text('Send OTP'), findsOneWidget);
```

#### Async Operation Timeouts
```dart
// Increase timeout for slow operations
await tester.pumpAndSettle(const Duration(seconds: 10));
```

#### Firebase Emulators
```dart
// Use Firebase emulators for testing
// firebase emulators:start --only auth,firestore
// Set emulator URLs in test setup
```

## 📈 Test Metrics & Reporting

### Success Criteria
- **Phone Auth Success Rate**: > 95%
- **Google Auth Success Rate**: > 95%
- **Profile Completion Rate**: > 90%
- **Average Auth Time**: < 10 seconds
- **Error Recovery Rate**: > 95%

### Test Reporting
```dart
// Generate test report
void generateTestReport() {
  final report = {
    'total_tests': testCount,
    'passed_tests': passedCount,
    'failed_tests': failedCount,
    'success_rate': (passedCount / testCount) * 100,
    'average_time': totalTime / testCount,
    'error_types': errorCounts,
  };

  debugPrint('Test Report: $report');
}
```

## 🚀 CI/CD Integration

### Firebase Test Lab
```yaml
# .github/workflows/test.yml
name: Authentication Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter drive --target=test_driver/app.dart
```

### Automated Test Runs
```bash
# Run all auth tests
flutter test test/auth/

# Run integration tests
flutter drive --target=integration_test/auth_flow_test.dart

# Run performance tests
flutter test test/auth_performance_test.dart
```

This comprehensive testing guide ensures the authentication system in JanMat is thoroughly tested and reliable across all scenarios and edge cases.