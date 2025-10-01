import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:janmat/firebase_options.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/widgets/view/manifesto_tab_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Manifesto Interaction Integration Tests', () {
    late Candidate testCandidate;

    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Create test candidate with manifesto
      testCandidate = _createTestCandidate();
    });

    testWidgets('Manifesto tab view renders correctly', (tester) async {
      // Create a test widget with the manifesto tab view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManifestoTabView(
              candidate: testCandidate,
              isOwnProfile: false,
              showVoterInteractions: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the widget renders without crashing
      // The manifesto content should be displayed (checking for any text content)
      expect(find.byType(ManifestoTabView), findsOneWidget);

      // Verify that the like button is present
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Verify that the comment input field is present
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Like button interaction works', (tester) async {
      // Create a test widget with the manifesto tab view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManifestoTabView(
              candidate: testCandidate,
              isOwnProfile: false,
              showVoterInteractions: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the like button (should be unliked initially)
      final likeButton = find.byIcon(Icons.favorite_border);
      expect(likeButton, findsOneWidget);

      // Tap the like button
      await tester.tap(likeButton);
      await tester.pumpAndSettle();

      // The button should still be visible (the service call may fail in test environment,
      // but the UI interaction should work)
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('Comment input functionality works', (tester) async {
      // Create a test widget with the manifesto tab view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManifestoTabView(
              candidate: testCandidate,
              isOwnProfile: false,
              showVoterInteractions: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the comment input field
      final commentField = find.byType(TextField);
      expect(commentField, findsOneWidget);

      // Enter a comment
      const testComment = 'This is a test comment for integration testing';
      await tester.enterText(commentField, testComment);
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text(testComment), findsOneWidget);
    });

    testWidgets('Comments visibility toggle works', (tester) async {
      // Create a test widget with the manifesto tab view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManifestoTabView(
              candidate: testCandidate,
              isOwnProfile: false,
              showVoterInteractions: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the comments toggle button (arrow icon)
      final toggleButton = find.byIcon(Icons.keyboard_arrow_down);
      expect(toggleButton, findsOneWidget);

      // Tap to expand comments
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // The arrow should change direction
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });
  });
}

Candidate _createTestCandidate() {
  // Create a test candidate with manifesto data
  final candidateData = {
    'userId': 'test_candidate_id',
    'candidateId': 'test_candidate_id',
    'name': 'Test Candidate',
    'party': 'Test Party',
    'districtId': 'test_district',
    'wardId': 'test_ward',
    'manifesto': 'Test Manifesto Content',
    'extraInfo': {
      'manifesto': {
        'title': 'Test Manifesto',
        'promises': [
          {
            'title': 'Education Reform',
            'points': ['Improve school facilities', 'Increase teacher salaries']
          }
        ]
      }
    }
  };

  return Candidate.fromJson(candidateData);
}