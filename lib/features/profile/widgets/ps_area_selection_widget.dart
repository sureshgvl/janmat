import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../models/ward_model.dart';
import '../../../widgets/modals/area_in_ward_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class PSAreaSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const PSAreaSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PS Area Selection (only show if PS ward has areas)
        if (controller.selectedElectionType == 'zp_ps_combined' &&
            controller.selectedPSWardId != null &&
            controller.selectedPSBodyId != null) ...[
          // Get PS ward object to check if it has areas
          Builder(
            builder: (context) {
              final psWard = controller.bodyWards[controller.selectedPSBodyId!]?.firstWhere(
                (ward) => ward.id == controller.selectedPSWardId,
                orElse: () => Ward(
                  id: '',
                  districtId: controller.selectedDistrictId ?? '',
                  bodyId: controller.selectedPSBodyId ?? '',
                  name: '',
                  stateId: controller.selectedStateId ?? '',
                  areas: null,
                ),
              );

              if (psWard != null && psWard.areas != null && psWard.areas!.isNotEmpty) {
                return InkWell(
                  onTap: () => _showPSAreaSelectionModal(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: localizations.selectPSAreaLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: controller.selectedPSArea != null
                        ? Text(
                            controller.selectedPSArea!,
                            style: const TextStyle(fontSize: 16),
                          )
                        : Text(
                            localizations.selectPSArea.toLowerCase(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              } else {
                return Container(); // No area selection needed
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  void _showPSAreaSelectionModal(BuildContext context) {
    // Get PS ward object
    final psWard = controller.bodyWards[controller.selectedPSBodyId!]?.firstWhere(
      (ward) => ward.id == controller.selectedPSWardId,
      orElse: () => Ward(
        id: '',
        districtId: controller.selectedDistrictId ?? '',
        bodyId: controller.selectedPSBodyId ?? '',
        name: '',
        stateId: controller.selectedStateId ?? '',
        areas: null,
      ),
    );

    if (psWard != null && psWard.areas != null && psWard.areas!.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return AreaInWardSelectionModal(
            ward: psWard,
            selectedArea: controller.selectedPSArea,
            onAreaSelected: controller.onPSAreaSelected,
          );
        },
      );
    }
  }
}

