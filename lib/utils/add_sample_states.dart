import 'package:cloud_firestore/cloud_firestore.dart';

class SampleStatesManager {
  static Future<void> addSampleStates() async {
    final firestore = FirebaseFirestore.instance;
    final statesCollection = firestore.collection('states');

    // Sample states data
    final sampleStates = [
      {
        'stateId': 'maharashtra',
        'name': 'Maharashtra',
        'marathiName': 'महाराष्ट्र',
        'code': 'MH',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'stateId': 'gujarat',
        'name': 'Gujarat',
        'marathiName': 'गुजरात',
        'code': 'GJ',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'stateId': 'karnataka',
        'name': 'Karnataka',
        'marathiName': 'कर्नाटक',
        'code': 'KA',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'stateId': 'rajasthan',
        'name': 'Rajasthan',
        'marathiName': 'राजस्थान',
        'code': 'RJ',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    try {
      // Add each state
      for (final stateData in sampleStates) {
        final stateId = stateData['stateId'] as String;
        await statesCollection.doc(stateId).set(stateData);
        print('✅ Added state: $stateId');
      }

      print('🎉 Successfully added ${sampleStates.length} sample states to Firestore');
    } catch (e) {
      print('❌ Error adding sample states: $e');
      rethrow;
    }
  }

  static Future<void> updateExistingStatesWithMarathiNames() async {
    final firestore = FirebaseFirestore.instance;
    final statesCollection = firestore.collection('states');

    // Marathi names mapping for all Indian states
    final marathiNames = {
      'andaman_and_nicobar_islands': 'अंदमान आणि निकोबार बेटे',
      'andhra_pradesh': 'आंध्र प्रदेश',
      'arunachal_pradesh': 'अरुणाचल प्रदेश',
      'assam': 'आसाम',
      'bihar': 'बिहार',
      'chandigarh': 'चंदीगड',
      'chhattisgarh': 'छत्तीसगड',
      'dadra_and_nagar_haveli_and_daman_and_diu': 'दादरा आणि नगर हवेली आणि दमन आणि दीव',
      'delhi': 'दिल्ली',
      'goa': 'गोवा',
      'gujarat': 'गुजरात',
      'haryana': 'हरियाणा',
      'himachal_pradesh': 'हिमाचल प्रदेश',
      'jammu_and_kashmir': 'जम्मू आणि काश्मीर',
      'jharkhand': 'झारखंड',
      'karnataka': 'कर्नाटक',
      'kerala': 'केरळ',
      'ladakh': 'लडाख',
      'lakshadweep': 'लक्षद्वीप',
      'madhya_pradesh': 'मध्य प्रदेश',
      'maharashtra': 'महाराष्ट्र',
      'manipur': 'मणिपूर',
      'meghalaya': 'मेघालय',
      'mizoram': 'मिझोरम',
      'nagaland': 'नागालँड',
      'odisha': 'ओडिशा',
      'puducherry': 'पुडुचेरी',
      'punjab': 'पंजाब',
      'rajasthan': 'राजस्थान',
      'sikkim': 'सिक्कीम',
      'tamil_nadu': 'तामिळनाडू',
      'telangana': 'तेलंगणा',
      'tripura': 'त्रिपुरा',
      'uttar_pradesh': 'उत्तर प्रदेश',
      'uttarakhand': 'उत्तराखंड',
      'west_bengal': 'पश्चिम बंगाल',
    };

    try {
      print('🔄 Updating existing states with Marathi names...');

      // Get all existing states
      final statesSnapshot = await statesCollection.get();

      for (final doc in statesSnapshot.docs) {
        final stateId = doc.id;
        final data = doc.data();

        // Check if Marathi name is missing
        if (data['marathiName'] == null && marathiNames.containsKey(stateId)) {
          await statesCollection.doc(stateId).update({
            'marathiName': marathiNames[stateId],
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Updated state: $stateId with Marathi name: ${marathiNames[stateId]}');
        }
      }

      print('🎉 Successfully updated existing states with Marathi names');
    } catch (e) {
      print('❌ Error updating existing states: $e');
      rethrow;
    }
  }

  static Future<void> addSampleDistrictsForMaharashtra() async {
    final firestore = FirebaseFirestore.instance;

    // Sample districts for Maharashtra
    final sampleDistricts = [
      {'districtId': 'pune', 'name': 'Pune'},
      {'districtId': 'mumbai', 'name': 'Mumbai'},
      {'districtId': 'thane', 'name': 'Thane'},
      {'districtId': 'nagpur', 'name': 'Nagpur'},
      {'districtId': 'nashik', 'name': 'Nashik'},
    ];

    try {
      for (final district in sampleDistricts) {
        await firestore
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc(district['districtId'])
            .set({
              ...district,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        print('✅ Added district: ${district['districtId']}');
      }

      print('🎉 Successfully added ${sampleDistricts.length} districts to Maharashtra');
    } catch (e) {
      print('❌ Error adding sample districts: $e');
      rethrow;
    }
  }
}