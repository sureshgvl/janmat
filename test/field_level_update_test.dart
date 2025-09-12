import 'package:flutter_test/flutter_test.dart';
import '../lib/models/candidate_model.dart';
import '../lib/models/achievement_model.dart';

void main() {
  group('Data Model Tests', () {
    test('Should create candidate with proper structure', () {
      final candidate = Candidate(
        candidateId: 'test_candidate_123',
        userId: 'test_user_123',
        name: 'Test Candidate',
        party: 'Test Party',
        cityId: 'test_city',
        wardId: 'test_ward',
        contact: Contact(phone: '1234567890'),
        sponsored: false,
        premium: false,
        createdAt: DateTime.now(),
        extraInfo: ExtraInfo(
          bio: 'Test bio',
          achievements: [],
        ),
      );

      expect(candidate.candidateId, 'test_candidate_123');
      expect(candidate.name, 'Test Candidate');
      expect(candidate.extraInfo?.bio, 'Test bio');
      expect(candidate.contact.phone, '1234567890');
    });

    test('Should handle ExtraInfo copyWith correctly', () {
      final original = ExtraInfo(
        bio: 'Original bio',
        achievements: [],
      );

      final updated = original.copyWith(bio: 'Updated bio');

      expect(original.bio, 'Original bio');
      expect(updated.bio, 'Updated bio');
      expect(updated.achievements, original.achievements); // Other fields preserved
    });

    test('Should handle achievements correctly', () {
      final achievements = [
        Achievement(
          title: 'Test Achievement',
          description: 'Test Description',
          year: 2023,
        )
      ];

      final extraInfo = ExtraInfo(
        bio: 'Test bio',
        achievements: achievements,
      );

      expect(extraInfo.achievements?.length, 1);
      expect(extraInfo.achievements?.first.title, 'Test Achievement');
      expect(extraInfo.achievements?.first.year, 2023);
    });

    test('Should handle candidate copyWith correctly', () {
      final original = Candidate(
        candidateId: 'test_123',
        userId: 'user_123',
        name: 'Original Name',
        party: 'Test Party',
        cityId: 'test_city',
        wardId: 'test_ward',
        contact: Contact(phone: '1234567890'),
        sponsored: false,
        premium: false,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(name: 'Updated Name');

      expect(original.name, 'Original Name'); // Original unchanged
      expect(updated.name, 'Updated Name'); // Updated has new value
      expect(updated.party, original.party); // Other fields preserved
    });

    test('Should handle contact data structure', () {
      final contact = Contact(
        phone: '1234567890',
        email: 'test@example.com',
        socialLinks: {'facebook': 'fb.com/test'},
      );

      expect(contact.phone, '1234567890');
      expect(contact.email, 'test@example.com');
      expect(contact.socialLinks?['facebook'], 'fb.com/test');
    });

    test('Should demonstrate data integrity with copyWith', () {
      final original = ExtraInfo(
        bio: 'Original bio',
        achievements: [
          Achievement(
            title: 'Original Achievement',
            description: 'Original Description',
            year: 2023,
          )
        ],
      );

      final updated = original.copyWith(bio: 'Updated bio');

      // Original should be unchanged
      expect(original.bio, 'Original bio');
      // Updated should have new value
      expect(updated.bio, 'Updated bio');
      // Other fields should be preserved
      expect(updated.achievements, original.achievements);
    });

    test('Should handle JSON serialization', () {
      final candidate = Candidate(
        candidateId: 'test_123',
        userId: 'user_123',
        name: 'Test Candidate',
        party: 'Test Party',
        cityId: 'test_city',
        wardId: 'test_ward',
        contact: Contact(phone: '1234567890'),
        sponsored: false,
        premium: false,
        createdAt: DateTime.now(),
        extraInfo: ExtraInfo(bio: 'Test bio'),
      );

      // Test JSON serialization
      final json = candidate.toJson();
      expect(json['candidateId'], 'test_123');
      expect(json['name'], 'Test Candidate');
      expect(json['extra_info']['bio'], 'Test bio');
    });
  });

  group('Field-Level Update Concept Tests', () {
    test('Should demonstrate the concept of field-level updates', () {
      // This test shows how field-level updates work conceptually

      // Simulate what happens in field-level updates
      final originalData = {'bio': 'Original bio', 'achievements': []};
      final updates = {'bio': 'Updated bio'};

      // Apply updates (simulating Firebase dot notation)
      final updatedData = {...originalData, ...updates};

      expect(originalData['bio'], 'Original bio'); // Original unchanged
      expect(updatedData['bio'], 'Updated bio'); // Updated applied
      expect(updatedData['achievements'], originalData['achievements']); // Other fields preserved
    });

    test('Should show efficiency of partial updates vs full updates', () {
      // Simulate payload sizes
      final fullUpdate = {
        'name': 'Test Candidate',
        'party': 'Test Party',
        'bio': 'Test bio',
        'achievements': [],
        'contact': {'phone': '1234567890'},
        'media': {},
        'events': [],
        // ... many more fields
      };

      final fieldLevelUpdate = {
        'extra_info.bio': 'Updated bio only'
      };

      // Field-level update is much smaller
      expect(fieldLevelUpdate.length < fullUpdate.length, true);
      expect(fieldLevelUpdate.containsKey('extra_info.bio'), true);
    });
  });
}