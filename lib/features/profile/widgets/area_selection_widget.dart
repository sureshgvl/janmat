import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../widgets/profile/area_in_ward_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class AreaSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const AreaSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Area Selection
        if (controller.selectedStateId != null &&
            controller.selectedWard != null &&
            controller.selectedWard!.areas != null &&
            controller.selectedWard!.areas!.isNotEmpty &&
            controller.currentUserRole != 'candidate') ...[
          InkWell(
            onTap: () => _showAreaSelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.areaRequired,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedArea != null
                  ? Text(
                      controller.selectedArea!,
                      style: const TextStyle(fontSize: 16),
                    )
                  : Text(
                      localizations.selectYourArea,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  void _showAreaSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaInWardSelectionModal(
          ward: controller.selectedWard!,
          selectedArea: controller.selectedArea,
          onAreaSelected: controller.updateSelectedArea,
        );
      },
    );
  }
}