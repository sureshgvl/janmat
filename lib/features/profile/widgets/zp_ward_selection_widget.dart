import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../widgets/profile/ward_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class ZPWardSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const ZPWardSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ZP Ward Selection (only show for ZP+PS combined elections)
        if (controller.selectedElectionType == 'zp_ps_combined' &&
            controller.selectedZPBodyId != null) ...[
          InkWell(
            onTap: () => _showZPWardSelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.selectZPWardLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.home, color: Colors.blue),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedZPWardId != null
                  ? Text(
                    localizations.zpWardDisplayFormat(controller.selectedZPWardId!),
                    style: const TextStyle(fontSize: 16),
                  )
                  : Text(
                      localizations.selectZPWard.toLowerCase(),
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
                  localizations.selectZPWard.toLowerCase(),
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

  void _showZPWardSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: controller.bodyWards[controller.selectedZPBodyId!] ?? [],
          selectedWardId: controller.selectedZPWardId,
          onWardSelected: controller.onZPWardSelected,
        );
      },
    );
  }
}