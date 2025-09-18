import 'package:flutter/material.dart';
import '../../features/candidate/models/candidate_party_model.dart';
import '../../utils/symbol_utils.dart';

class PartySelectionModal extends StatefulWidget {
  final List<Party> parties;
  final String? selectedPartyId;
  final Function(String) onPartySelected;

  const PartySelectionModal({
    super.key,
    required this.parties,
    required this.selectedPartyId,
    required this.onPartySelected,
  });

  @override
  State<PartySelectionModal> createState() => _PartySelectionModalState();
}

class _PartySelectionModalState extends State<PartySelectionModal> {
  late List<Party> filteredParties;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredParties = List.from(widget.parties);
  }

  void _filterParties(String query) {
    if (query.isEmpty) {
      filteredParties = List.from(widget.parties);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredParties = widget.parties.where((party) {
        // Search in party name
        final nameMatch = party.name.toLowerCase().contains(lowerQuery);

        // Search in party abbreviation
        final abbreviationMatch = party.abbreviation.toLowerCase().contains(
          lowerQuery,
        );

        // Search for Marathi equivalents (e.g., "bjp" should find "भाजप")
        final marathiMatch = _hasMarathiEquivalent(
          party.name,
          party.abbreviation,
          lowerQuery,
        );

        return nameMatch || abbreviationMatch || marathiMatch;
      }).toList();
    }
    setState(() {});
  }

  // Check if party name or abbreviation has Marathi equivalent of English query
  bool _hasMarathiEquivalent(
    String partyName,
    String abbreviation,
    String query,
  ) {
    final Map<String, List<String>> marathiEquivalents = {
      'bjp': ['भाजप', 'भारतीय जनता पार्टी'],
      'inc': ['काँग्रेस', 'इंडियन नॅशनल काँग्रेस'],
      'ncp': ['राष्ट्रवादी', 'राष्ट्रवादी काँग्रेस पार्टी'],
      'shiv sena': ['शिवसेना', 'शिव सेना'],
      'aimim': ['आमिम', 'ऑल इंडिया मजलिस-ए-इत्तेहादुल मुस्लिमीन'],
      'bsp': ['बसपा', 'बहुजन समाज पार्टी'],
      'cpi': ['सीपीआय', 'कम्युनिस्ट पार्टी ऑफ इंडिया'],
      'cpim': ['सीपीआय(एम)', 'कम्युनिस्ट पार्टी ऑफ इंडिया (मार्क्सवादी)'],
      'independent': ['स्वतंत्र', 'निर्दलीय'],
      'mns': ['मनसे', 'महाराष्ट्र नवनिर्माण सेना'],
      'samajwadi': ['समाजवादी', 'समाजवादी पार्टी'],
      'rashtriya': ['राष्ट्रीय', 'राष्ट्रीय जनता दल'],
      'jdu': ['जेडीयू', 'जनता दल यूनाइटेड'],
      'tmc': ['टीएमसी', 'तृणमूल काँग्रेस'],
      'dmk': ['द्रमुक', 'द्रविड़ मुनेत्र कड़गम'],
      'aap': ['आप', 'आम आदमी पार्टी'],
    };

    final partyText = '$partyName $abbreviation'.toLowerCase();
    final equivalents = marathiEquivalents[query] ?? [];

    return equivalents.any(
      (equivalent) => partyText.contains(equivalent.toLowerCase()),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Select Political Party',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.blue, size: 28),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search parties...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterParties,
            ),
          ),

          // Party List
          Expanded(
            child: filteredParties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No parties found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredParties.length,
                    itemBuilder: (context, index) {
                      final party = filteredParties[index];
                      final isSelected = widget.selectedPartyId == party.id;

                      return InkWell(
                        onTap: () {
                          widget.onPartySelected(party.id);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade200
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.shade100,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Party Symbol
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image(
                                    image: SymbolUtils.getSymbolImageProvider(
                                      SymbolUtils.getPartySymbolPathFromParty(
                                        party,
                                      ),
                                    ),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Icon(
                                          Icons.flag,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Party Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      party.getDisplayName(
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.blue.shade800
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      party.abbreviation,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection Indicator
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
