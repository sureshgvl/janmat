import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../widgets/modals/ward_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class PSWardSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const PSWardSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PS Ward Selection (only show for ZP+PS combined elections after PS body is selected)
        if (controller.selectedElectionType == 'zp_ps_combined' &&
            controller.selectedPSBodyId != null) ...[
          InkWell(
            onTap: () => _showPSWardSelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.selectPSWardLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.home, color: Colors.green),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedPSWardId != null
                  ? Text(
                    localizations.psWardDisplayFormat(controller.selectedPSWardId!),
                    style: const TextStyle(fontSize: 16),
                  )
                  : Text(
                      localizations.selectPSWard.toLowerCase(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ] else if (controller.selectedElectionType == 'zp_ps_combined') ...[
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
                  localizations.selectPSWard.toLowerCase(),
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
      ],
    );
  }

  void _showPSWardSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: controller.bodyWards[controller.selectedPSBodyId!] ?? [],
          selectedWardId: controller.selectedPSWardId,
          onWardSelected: controller.onPSWardSelected,
        );
      },
    );
  }
}

