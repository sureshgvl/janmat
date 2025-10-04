import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../utils/symbol_utils.dart';
import '../../../features/candidate/models/candidate_party_model.dart';
import '../controllers/profile_completion_controller.dart';

class PartySelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const PartySelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Party Selection
        InkWell(
          onTap: () => _showPartySelectionModal(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: localizations.selectPoliticalParty,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.flag),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: controller.selectedPartyId != null
                ? Row(
                    children: [
                      // Party Symbol
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1.5),
                          child: Image(
                            image: SymbolUtils.getSymbolImageProvider(
                              SymbolUtils.getPartySymbolPath(_getPartyById(controller.selectedPartyId!)?.name ?? ''),
                            ),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.flag,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Party Name
                      Expanded(
                        child: Text(
                          _getPartyDisplayName(controller.selectedPartyId!, context),
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text(
                    localizations.selectYourPoliticalParty.toLowerCase(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showPartySelectionModal(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;
    final parties = _getPartiesFromSymbolUtils();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, // Limit height to 70% of screen
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
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      localizations.selectPoliticalParty,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              // Party List - Make it scrollable
              Expanded(
                child: ListView(
                  children: parties.map((party) {
                    final isSelected = controller.selectedPartyId == party.id;
                    return InkWell(
                      onTap: () {
                        controller.onPartySelected(party.id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Party Symbol
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image(
                                  image: SymbolUtils.getSymbolImageProvider(
                                    SymbolUtils.getPartySymbolPath(party.name),
                                  ),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.flag,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Party Details
                            Expanded(
                              child: Text(
                                party.getDisplayName(Localizations.localeOf(context).languageCode),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue : Colors.black87,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Party> _getPartiesFromSymbolUtils() {
    return SymbolUtils.parties.map((partyData) {
      return Party(
        id: partyData['key']!,
        name: partyData['nameEn']!,
        nameMr: partyData['nameMr'] ?? partyData['nameEn']!,
        abbreviation: partyData['shortNameEn']!,
        symbolPath: partyData['image'],
      );
    }).toList();
  }

  Party? _getPartyById(String partyId) {
    return _getPartiesFromSymbolUtils().firstWhere(
      (p) => p.id == partyId,
      orElse: () => Party(
        id: partyId,
        name: partyId,
        nameMr: partyId,
        abbreviation: partyId,
      ),
    );
  }

  String _getPartyDisplayName(String partyId, BuildContext context) {
    final party = _getPartyById(partyId);
    return party?.getDisplayName(Localizations.localeOf(context).languageCode) ?? partyId;
  }
}

