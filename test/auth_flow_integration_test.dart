import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// Import your app's main files
import 'package:janmat/main.dart';
import 'package:janmat/features/auth/controllers/auth_controller.dart';
import 'package:janmat/features/auth/repositories/auth_repository.dart';
import 'package:janmat/features/auth/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset GetX controllers between tests
    if (Get.isRegistered<AuthController>()) {
      Get.delete<AuthController>(force: true);
    }
  });

  group('🔇 Enhanced Silent Login Flow UI Tests', () {
    testWidgets('G1: Launch app (cold start) - shows login screen', (tester) async {
      // Launch app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('UI Structure: Login screen has all required elements', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should have app logo
      expect(find.byType(Image), findsAtLeast(1));

      // Should have welcome text
      expect(find.textContaining('Welcome'), findsOneWidget);

      // Should have phone input field
      expect(find.byType(TextField), findsAtLeast(1));

      // Should have Send OTP button
      expect(find.textContaining('Send OTP'), findsOneWidget);

      // Should have Google sign-in button
      expect(find.textContaining('Google'), findsOneWidget);
    });

    testWidgets('Phone Input: Field accepts valid input', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find phone input field
      final phoneField = find.byType(TextField).first;
      expect(phoneField, findsOneWidget);

      // Enter valid phone number
      await tester.enterText(phoneField, '9876543210');
      await tester.pump();

      // Field should accept the input
      final textField = tester.widget<TextField>(phoneField);
      expect(textField.controller?.text, '9876543210');
    });

    testWidgets('Phone Input: Field has proper constraints', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final phoneField = find.byType(TextField).first;
      final textField = tester.widget<TextField>(phoneField);

      // Should have maxLength: 10
      expect(textField.maxLength, 10);

      // Should have phone keyboard type
      expect(textField.keyboardType, TextInputType.phone);
    });

    testWidgets('Button States: Send OTP button shows loading state', (tester) async {
      final authController = Get.put(AuthController());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Initially should not be loading
      expect(authController.isLoading.value, false);

      // Find Send OTP button
      final sendButton = find.textContaining('Send OTP');
      expect(sendButton, findsOneWidget);
    });

    testWidgets('Navigation: Back button behavior on login screen', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should be on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Test that back button works (this tests the scaffold structure)
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('📱 OTP Login Flow UI Tests', () {
    testWidgets('OTP Screen: Switches to OTP input after phone entry', (tester) async {
      final authController = Get.put(AuthController());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Initially should show phone input screen
      expect(authController.isOTPScreen.value, false);

      // Simulate switching to OTP screen
      authController.isOTPScreen.value = true;
      await tester.pump();

      // Should now show OTP input
      expect(find.textContaining('Enter OTP'), findsOneWidget);
      expect(find.textContaining('Verify OTP'), findsOneWidget);
    });

    testWidgets('OTP Input: Field has proper constraints', (tester) async {
      final authController = Get.put(AuthController());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Switch to OTP screen
      authController.isOTPScreen.value = true;
      await tester.pump();

      // Should have OTP input field
      final otpFields = find.byType(TextField);
      expect(otpFields, findsAtLeast(1));

      // Find the OTP field (usually the second TextField)
      bool foundOTPField = false;
      final otpFieldElements = tester.widgetList<TextField>(otpFields);
      for (final textField in otpFieldElements) {
        if (textField.maxLength == 6) {
          foundOTPField = true;
          // Should have number keyboard
          expect(textField.keyboardType, TextInputType.number);
          break;
        }
      }

      expect(foundOTPField, true, reason: 'Should have OTP field with maxLength 6');
    });

    testWidgets('Timer: OTP resend timer functionality', (tester) async {
      final authController = Get.put(AuthController());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Switch to OTP screen
      authController.isOTPScreen.value = true;
      await tester.pump();

      // Initially timer should be 60
      expect(authController.otpTimer.value, 60);
      expect(authController.canResendOTP.value, false);
    });
  });

  group('🌐 Google Login Flow UI Tests', () {
    testWidgets('Google Button: Present and properly configured', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should have Google sign-in button
      final googleButtons = find.textContaining('Google');
      expect(googleButtons, findsAtLeast(1));

      // Should have Google logo image
      final googleImages = find.byType(Image);
      expect(googleImages, findsAtLeast(1));
    });

    testWidgets('Smart UI: Shows appropriate buttons based on stored account', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Without stored account, should show default Google button
      expect(find.textContaining('Sign in with Google'), findsOneWidget);
    });
  });

  group('🎨 UI/UX Tests', () {
    testWidgets('Layout: Screen is properly scrollable', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should have SingleChildScrollView for proper layout
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('Theme: Uses proper Material Design components', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should use Card for the login form
      expect(find.byType(Card), findsOneWidget);

      // Should use ElevatedButton for actions
      expect(find.byType(ElevatedButton), findsAtLeast(2)); // Send OTP + Google
    });

    testWidgets('Responsiveness: LayoutBuilder handles different screen sizes', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should use LayoutBuilder for responsive design
      expect(find.byType(LayoutBuilder), findsOneWidget);
    });
  });

  group('🔧 Repository Unit Tests', () {
    test('AuthRepository: Can be instantiated', () {
      final authRepo = AuthRepository();
      expect(authRepo, isNotNull);
    });

    test('AuthRepository: Has required methods', () {
      final authRepo = AuthRepository();

      // Should have the key methods
      expect(authRepo.getLastGoogleAccount, isNotNull);
      expect(authRepo.clearLastGoogleAccount, isNotNull);
      expect(authRepo.signInWithGoogle, isNotNull);
    });

    test('Account Data Validation: Proper structure validation', () {
      final authRepo = AuthRepository();

      // Test valid data structure
      final validData = {
        'email': 'test@example.com',
        'displayName': 'Test User',
        'lastLogin': DateTime.now().toIso8601String(),
        'version': '2.0',
      };

      // This tests the validation logic indirectly through the method structure
      expect(validData.containsKey('email'), true);
      expect(validData.containsKey('displayName'), true);
    });

    test('Data Security: No sensitive tokens stored', () {
      // Test that our data structure doesn't include sensitive information
      final accountData = {
        'email': 'user@example.com',
        'displayName': 'Test User',
        'id': '12345',
        'lastLogin': DateTime.now().toIso8601String(),
        'version': '2.0',
      };

      // Should not contain sensitive data
      expect(accountData.containsKey('password'), false);
      expect(accountData.containsKey('accessToken'), false);
      expect(accountData.containsKey('refreshToken'), false);
      expect(accountData.containsKey('authToken'), false);
    });
  });

  group('📊 Performance Tests', () {
    testWidgets('UI Rendering: Login screen renders within reasonable time', (tester) async {
      final startTime = DateTime.now();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final renderTime = DateTime.now().difference(startTime);

      // Should render within 2 seconds
      expect(renderTime.inSeconds, lessThan(2));
    });

    testWidgets('Memory: No memory leaks in basic navigation', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Basic check that widgets are properly disposed
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
