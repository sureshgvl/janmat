import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:janmat/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase for testing
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Debug Candidate Location', () {
    test('Check if candidate exists in legacy collection', () async {
      debugPrint(
        '🔍 Checking legacy /candidates collection for userId: efSlmEmHpyMrrAqF8i5V',
      );

      try {
        final candidatesSnapshot = await FirebaseFirestore.instance
            .collection('candidates')
            .where('userId', isEqualTo: 'efSlmEmHpyMrrAqF8i5V')
            .limit(1)
            .get();

        if (candidatesSnapshot.docs.isNotEmpty) {
          final doc = candidatesSnapshot.docs.first;
          debugPrint('✅ Found candidate in legacy collection:');
          debugPrint('   Document ID: ${doc.id}');
          debugPrint('   Data: ${doc.data()}');
        } else {
          debugPrint('❌ No candidate found in legacy collection');
        }
      } catch (e) {
        debugPrint('❌ Error checking legacy collection: $e');
      }
    });

    test('Check if candidate exists in hierarchical structure', () async {
      debugPrint(
        '🔍 Checking hierarchical structure: /states/maharashtra/districts/Pune/bodies/pune_city/wards/ward_17/candidates/efSlmEmHpyMrrAqF8i5V',
      );

      try {
        final candidateDoc = await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc('Pune')
            .collection('bodies')
            .doc('pune_city')
            .collection('wards')
            .doc('ward_17')
            .collection('candidates')
            .doc('efSlmEmHpyMrrAqF8i5V')
            .get();

        if (candidateDoc.exists) {
          debugPrint('✅ Found candidate in hierarchical structure:');
          debugPrint('   Data: ${candidateDoc.data()}');
        } else {
          debugPrint('❌ No candidate found in hierarchical structure');
        }
      } catch (e) {
        debugPrint('❌ Error checking hierarchical structure: $e');
      }
    });

    test('Check if district collections exist', () async {
      debugPrint('🔍 Checking if district collections exist');

      try {
        final districtsSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .get();

        debugPrint('📊 Found ${districtsSnapshot.docs.length} districts:');
        for (var doc in districtsSnapshot.docs) {
          debugPrint('   - ${doc.id}');
        }

        // Check if Pune district exists
        final puneDoc = await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc('Pune')
            .get();

        if (puneDoc.exists) {
          debugPrint('✅ Pune district exists');

          // Check bodies in Pune
          final bodiesSnapshot = await FirebaseFirestore.instance
              .collection('states')
              .doc('maharashtra')
              .collection('districts')
              .doc('Pune')
              .collection('bodies')
              .get();

          debugPrint('📊 Found ${bodiesSnapshot.docs.length} bodies in Pune:');
          for (var doc in bodiesSnapshot.docs) {
            debugPrint('   - ${doc.id}');
          }

          // Check if pune_city body exists
          final puneCityDoc = await FirebaseFirestore.instance
              .collection('states')
              .doc('maharashtra')
              .collection('districts')
              .doc('Pune')
              .collection('bodies')
              .doc('pune_city')
              .get();

          if (puneCityDoc.exists) {
            debugPrint('✅ pune_city body exists');

            // Check wards in pune_city
            final wardsSnapshot = await FirebaseFirestore.instance
                .collection('states')
                .doc('maharashtra')
                .collection('districts')
                .doc('Pune')
                .collection('bodies')
                .doc('pune_city')
                .collection('wards')
                .get();

            debugPrint(
              '📊 Found ${wardsSnapshot.docs.length} wards in pune_city:',
            );
            for (var doc in wardsSnapshot.docs) {
              debugPrint('   - ${doc.id}');
            }

            // Check if ward_17 exists
            final ward17Doc = await FirebaseFirestore.instance
                .collection('states')
                .doc('maharashtra')
                .collection('districts')
                .doc('Pune')
                .collection('bodies')
                .doc('pune_city')
                .collection('wards')
                .doc('ward_17')
                .get();

            if (ward17Doc.exists) {
              debugPrint('✅ ward_17 exists');

              // Check candidates in ward_17
              final candidatesSnapshot = await FirebaseFirestore.instance
                  .collection('states')
                  .doc('maharashtra')
                  .collection('districts')
                  .doc('Pune')
                  .collection('bodies')
                  .doc('pune_city')
                  .collection('wards')
                  .doc('ward_17')
                  .collection('candidates')
                  .get();

              debugPrint(
                '📊 Found ${candidatesSnapshot.docs.length} candidates in ward_17:',
              );
              for (var doc in candidatesSnapshot.docs) {
                debugPrint('   - ${doc.id}');
              }
            } else {
              debugPrint('❌ ward_17 does not exist');
            }
          } else {
            debugPrint('❌ pune_city body does not exist');
          }
        } else {
          debugPrint('❌ Pune district does not exist');
        }
      } catch (e) {
        debugPrint('❌ Error checking district collections: $e');
      }
    });
  });
}
