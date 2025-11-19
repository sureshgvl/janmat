import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:janmat/firebase_options.dart';
import 'package:janmat/utils/app_logger.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize states and districts
  await populateStatesAndDistricts();
}

Future<void> populateStatesAndDistricts() async {
  final firestore = FirebaseFirestore.instance;

  try {
    AppLogger.core('🚀 Starting Firestore data population...');

    // Add Maharashtra state
    await firestore.collection('states').doc('maharashtra').set({
      'stateId': 'maharashtra',
      'name': 'Maharashtra',
      'marathiName': 'महाराष्ट्र',
      'code': 'MH',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.core('✅ Added Maharashtra state');

    // Add districts for Maharashtra
    final districts = [
      {'districtId': 'pune', 'name': 'Pune'},
      {'districtId': 'mumbai', 'name': 'Mumbai'},
      {'districtId': 'thane', 'name': 'Thane'},
      {'districtId': 'nagpur', 'name': 'Nagpur'},
      {'districtId': 'nashik', 'name': 'Nashik'},
      {'districtId': 'ahmednagar', 'name': 'Ahmednagar'},
      {'districtId': 'solapur', 'name': 'Solapur'},
      {'districtId': 'jalgaon', 'name': 'Jalgaon'},
      {'districtId': 'kolhapur', 'name': 'Kolhapur'},
      {'districtId': 'satara', 'name': 'Satara'},
      {'districtId': 'aurangabad', 'name': 'Aurangabad'},
      {'districtId': 'latur', 'name': 'Latur'},
      {'districtId': 'dhule', 'name': 'Dhule'},
      {'districtId': 'nanded', 'name': 'Nanded'},
    ];

    for (final district in districts) {
      await firestore
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(district['districtId'])
          .set({
            ...district,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    }

    AppLogger.core('✅ Added ${districts.length} districts to Maharashtra');

    // Add a sample body and ward for Pune (for testing)
    await firestore
        .collection('states')
        .doc('maharashtra')
        .collection('districts')
        .doc('pune')
        .collection('bodies')
        .doc('pune_m_corp')
        .set({
          'bodyId': 'pune_m_corp',
          'name': 'Pune Municipal Corporation',
          'type': 'municipal_corporation',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    AppLogger.core('✅ Added Pune Municipal Corporation body');

    // Add sample wards for Pune
    for (int i = 1; i <= 5; i++) {
      await firestore
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc('pune')
          .collection('bodies')
          .doc('pune_m_corp')
          .collection('wards')
          .doc('ward_$i')
          .set({
            'wardId': 'ward_$i',
            'name': 'Ward $i',
            'districtId': 'pune',
            'bodyId': 'pune_m_corp',
            'stateId': 'maharashtra',
            'areas': ['Area A', 'Area B', 'Area C'],
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    }

    AppLogger.core('✅ Added 5 sample wards to Pune Municipal Corporation');

    AppLogger.core('🎉 Firestore data population completed successfully!');
  } catch (e) {
    AppLogger.coreError('❌ Error populating Firestore data', error: e);
  }
}
