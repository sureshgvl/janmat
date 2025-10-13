import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/symbol_utils.dart';
import '../controllers/change_party_symbol_controller.dart';
import 'party_selection_modal.dart';

class PartySelector extends StatelessWidget {
  final ChangePartySymbolController controller;

  const PartySelector({
    super.key,
    required this.controller,
  });

  void _showPartySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PartySelectionModal(controller: controller);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Obx(() => controller.isLoadingParties.value
        ? const CircularProgressIndicator()
        : InkWell(
            onTap: () => _showPartySelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.newPartyLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.flag),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedParty.value != null
                  ? Row(
                      children: [
                        // Selected Party Symbol
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 12),
                          child: Image(
                            image: SymbolUtils.getSymbolImageProvider(
                              SymbolUtils.getPartySymbolPathFromParty(
                                controller.selectedParty.value!,
                              ),
                            ),
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return const Icon(
                                Icons.flag,
                                size: 28,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                        // Selected Party Name
                        Expanded(
                          child: Text(
                            controller.selectedParty.value!.getDisplayName(
                              Localizations.localeOf(
                                context,
                              ).languageCode,
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      localizations.selectPartyValidation,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ));
  }
}