import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../models/candidate_party_model.dart';
import '../../../utils/symbol_utils.dart';
import '../controllers/change_party_symbol_controller.dart';

class PartySelectionModal extends StatelessWidget {
  final ChangePartySymbolController controller;

  const PartySelectionModal({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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
                Text(
                  localizations.newPartyLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Party List
          Expanded(
            child: Obx(() => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.parties.length,
              itemBuilder: (context, index) {
                final party = controller.parties[index];
                final isSelected = controller.selectedParty.value?.id == party.id;

                return InkWell(
                  onTap: () {
                    controller.selectParty(party);
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
                          width: 48,
                          height: 48,
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
                            decoration: const BoxDecoration(
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
            )),
          ),
        ],
      ),
    );
  }
}