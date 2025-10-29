import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/symbol_utils.dart';
import '../models/candidate_party_model.dart';

class PartyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check Firebase connectivity
  Future<bool> checkFirebaseConnection() async {
    try {
      AppLogger.candidate('🔗 PartyRepository: Checking Firebase connection...');
      // Try to get a simple document to test connection
      await _firestore.collection('test').limit(1).get();
      AppLogger.candidate('✅ PartyRepository: Firebase connection successful');
      return true;
    } catch (e) {
      AppLogger.candidateError('PartyRepository: Firebase connection failed: $e');
      return false;
    }
  }

  // Fetch all active parties - Using centralized party data from SymbolUtils
  Future<List<Party>> getActiveParties() async {
    AppLogger.candidate('📋 PartyRepository: Returning centralized party data from SymbolUtils');

    // Convert SymbolUtils.parties to List<Party>
    final parties = SymbolUtils.parties.map((partyMap) {
      return Party(
        id: partyMap['key']!,
        name: partyMap['nameEn']!,
        nameMr: partyMap['nameMr'] ?? '',
        abbreviation: partyMap['shortNameEn'] ?? '',
        symbolPath: 'assets/symbols/${partyMap['image']}',
        isActive: true,
      );
    }).toList();

    // Sort by name for consistent ordering
    parties.sort((a, b) => a.name.compareTo(b.name));

    AppLogger.candidate('✅ PartyRepository: Loaded ${parties.length} parties from SymbolUtils');
    AppLogger.candidate(
      '📝 PartyRepository: Party names: ${parties.map((p) => p.name).join(', ')}',
    );

    return parties;
  }



}
