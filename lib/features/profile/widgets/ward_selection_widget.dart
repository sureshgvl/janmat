import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../widgets/modals/ward_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class WardSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const WardSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ward Selection
        if (controller.selectedStateId != null &&
            controller.selectedBodyId != null &&
            controller.bodyWards[controller.selectedBodyId!] != null &&
            controller.bodyWards[controller.selectedBodyId!]!.isNotEmpty)
          InkWell(
            onTap: () => _showWardSelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.wardRequired,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.home),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedWard != null
                  ? Builder(
                      builder: (context) {
                        // Format ward display like "वॉर्ड 1 - Ward Name"
                        final numberMatch = RegExp(r'ward_(\d+)')
                            .firstMatch(
                              controller.selectedWard!.id.toLowerCase(),
                            );
                        final displayText = numberMatch != null
                            ? localizations.wardDisplayFormat(numberMatch.group(1)!, controller.selectedWard!.name)
                            : controller.selectedWard!.name;
                        return Text(
                          displayText,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    )
                  : Text(
                      localizations.selectWardLabel,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.home, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  controller.selectedStateId == null
                      ? localizations.selectStateFirst
                      : controller.selectedBodyId == null
                          ? localizations.selectAreaFirst
                          : controller.bodyWards[controller.selectedBodyId!] == null ||
                                controller.bodyWards[controller.selectedBodyId!]!.isEmpty
                          ? localizations.noWardsAvailable
                          : localizations.selectWardLabel,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showWardSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: controller.bodyWards[controller.selectedBodyId!] ?? [],
          selectedWardId: controller.selectedWard?.id,
          onWardSelected: controller.onWardSelected,
        );
      },
    );
  }
}

