import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidate_party_model.dart';

class PartyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check Firebase connectivity
  Future<bool> checkFirebaseConnection() async {
    try {
      print('🔗 PartyRepository: Checking Firebase connection...');
      // Try to get a simple document to test connection
      await _firestore.collection('test').limit(1).get();
      print('✅ PartyRepository: Firebase connection successful');
      return true;
    } catch (e) {
      print('❌ PartyRepository: Firebase connection failed: $e');
      return false;
    }
  }

  // Fetch all active parties - Using static Maharashtra parties data
  Future<List<Party>> getActiveParties() async {
    print('📋 PartyRepository: Returning static Maharashtra parties data');

    // Return the static Maharashtra parties data
    final parties = _getMaharashtraParties();

    // Sort by name for consistent ordering
    parties.sort((a, b) => a.name.compareTo(b.name));

    print('✅ PartyRepository: Loaded ${parties.length} Maharashtra parties');
    print(
      '📝 PartyRepository: Party names: ${parties.map((p) => p.name).join(', ')}',
    );

    return parties;
  }

  // Fetch party by ID
  Future<Party?> getPartyById(String partyId) async {
    try {
      final doc = await _firestore.collection('parties').doc(partyId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Party.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching party: $e');
      return null;
    }
  }

  // Add a new party
  Future<void> addParty(Party party) async {
    try {
      await _firestore.collection('parties').doc(party.id).set(party.toJson());
    } catch (e) {
      print('Error adding party: $e');
      rethrow;
    }
  }

  // Update party
  Future<void> updateParty(Party party) async {
    try {
      await _firestore
          .collection('parties')
          .doc(party.id)
          .update(party.toJson());
    } catch (e) {
      print('Error updating party: $e');
      rethrow;
    }
  }

  // Delete party
  Future<void> deleteParty(String partyId) async {
    try {
      await _firestore.collection('parties').doc(partyId).delete();
    } catch (e) {
      print('Error deleting party: $e');
      rethrow;
    }
  }

  // Get static Maharashtra parties data
  List<Party> _getMaharashtraParties() {
    print('📋 PartyRepository: Returning static Maharashtra parties data');
    return [
      Party(
        id: 'bjp',
        name: 'Bharatiya Janata Party',
        nameMr: 'भारतीय जनता पक्ष',
        abbreviation: 'BJP',
        symbolPath: 'assets/symbols/bjp.png',
        isActive: true,
      ),
      Party(
        id: 'inc',
        name: 'Indian National Congress',
        nameMr: 'भारतीय राष्ट्रीय काँग्रेस',
        abbreviation: 'INC',
        symbolPath: 'assets/symbols/inc.png',
        isActive: true,
      ),
      Party(
        id: 'ss_ubt',
        name: 'Shiv Sena (Uddhav Balasaheb Thackeray)',
        nameMr: 'शिवसेना (उद्धव बाळासाहेब ठाकरे)',
        abbreviation: 'Shiv Sena (UBT)',
        symbolPath: 'assets/symbols/shiv_sena_ubt.jpeg',
        isActive: true,
      ),
      Party(
        id: 'ss_shinde',
        name: 'Balasahebanchi Shiv Sena (Shinde)',
        nameMr: 'बाळासाहेबांची शिवसेना',
        abbreviation: 'Shiv Sena (Shinde)',
        symbolPath: 'assets/symbols/shiv_sena_shinde.png',
        isActive: true,
      ),
      Party(
        id: 'ncp_ajit',
        name: 'Nationalist Congress Party (Ajit Pawar)',
        nameMr: 'राष्ट्रवादी काँग्रेस पक्ष (अजित पवार)',
        abbreviation: 'NCP (Ajit Pawar)',
        symbolPath: 'assets/symbols/ncp_ajit.png',
        isActive: true,
      ),
      Party(
        id: 'ncp_sp',
        name: 'Nationalist Congress Party (Sharad Pawar)',
        nameMr: 'राष्ट्रवादी काँग्रेस पक्ष (शरदचंद्र पवार)',
        abbreviation: 'NCP (Sharad Pawar)',
        symbolPath: 'assets/symbols/ncp_sp.png',
        isActive: true,
      ),
      Party(
        id: 'mns',
        name: 'Maharashtra Navnirman Sena',
        nameMr: 'महाराष्ट्र नवनिर्माण सेना',
        abbreviation: 'MNS',
        symbolPath: 'assets/symbols/mns.png',
        isActive: true,
      ),
      Party(
        id: 'pwpi',
        name: 'Peasants and Workers Party of India',
        nameMr: 'शेतकरी कामगार पक्ष',
        abbreviation: 'PWP',
        symbolPath: 'assets/symbols/pwp.jpg',
        isActive: true,
      ),
      Party(
        id: 'cpi_m',
        name: 'Communist Party of India (Marxist)',
        nameMr: 'भारतीय कम्युनिस्ट पक्ष (मार्क्सवादी)',
        abbreviation: 'CPI(M)',
        symbolPath: 'assets/symbols/cpi_m.png',
        isActive: true,
      ),
      Party(
        id: 'rsp',
        name: 'Rashtriya Samaj Paksha',
        nameMr: 'राष्ट्रीय समाज पक्ष',
        abbreviation: 'RSP',
        symbolPath: 'assets/symbols/default.png',
        isActive: true,
      ),
      Party(
        id: 'sp',
        name: 'Samajwadi Party',
        nameMr: 'समाजवादी पक्ष',
        abbreviation: 'SP',
        symbolPath: 'assets/symbols/sp.png',
        isActive: true,
      ),
      Party(
        id: 'bsp',
        name: 'Bahujan Samaj Party',
        nameMr: 'बहुजन समाज पार्टी',
        abbreviation: 'BSP',
        symbolPath: 'assets/symbols/bsp.png',
        isActive: true,
      ),
      Party(
        id: 'bva',
        name: 'Bahujan Vikas Aaghadi',
        nameMr: 'बहुजन विकास आघाडी',
        abbreviation: 'BVA',
        symbolPath: 'assets/symbols/default.png',
        isActive: true,
      ),
      //Party(id: 'republican_sena', name: 'Republican Sena', nameMr: 'रिपब्लिकन सेना', abbreviation: 'Republican Sena', symbolPath: 'assets/symbols/default.png', isActive: true),
      Party(
        id: 'abs',
        name: 'Akhil Bharatiya Sena',
        nameMr: 'अखिल भारतीय सेना',
        abbreviation: 'ABS',
        symbolPath: 'assets/symbols/default.png',
        isActive: true,
      ),
      Party(
        id: 'vba',
        name: 'Vanchit Bahujan Aghadi',
        nameMr: 'वंचित बहुजन आघाडी',
        abbreviation: 'VBA',
        symbolPath: 'assets/symbols/vba.png',
        isActive: true,
      ),
      Party(
        id: 'independent',
        name: 'Independent',
        nameMr: 'अपक्ष',
        abbreviation: 'IND',
        symbolPath: 'assets/symbols/independent.png',
        isActive: true,
      ),
    ];
  }

  // Create default parties if none exist
  Future<void> _createDefaultParties() async {
    try {
      print('🏗️ PartyRepository: Creating default parties in Firebase...');

      final defaultParties = _getMaharashtraParties();

      // Create parties in batch
      final batch = _firestore.batch();
      for (final party in defaultParties) {
        final docRef = _firestore.collection('parties').doc(party.id);
        batch.set(docRef, party.toJson());
      }

      await batch.commit();
      print(
        '✅ PartyRepository: Successfully created ${defaultParties.length} default parties in Firebase',
      );
    } catch (e) {
      print('❌ PartyRepository: Error creating default parties: $e');
      rethrow;
    }
  }
}
