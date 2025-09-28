import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../models/ward_model.dart';
import '../../../widgets/profile/area_in_ward_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class ZPAreaSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const ZPAreaSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ZP Area Selection (only show if ZP ward has areas)
        if (controller.selectedElectionType == 'zp_ps_combined' &&
            controller.selectedZPWardId != null &&
            controller.selectedZPBodyId != null) ...[
          // Get ZP ward object to check if it has areas
          Builder(
            builder: (context) {
              final zpWard = controller.bodyWards[controller.selectedZPBodyId!]?.firstWhere(
                (ward) => ward.id == controller.selectedZPWardId,
                orElse: () => Ward(
                  id: '',
                  districtId: controller.selectedDistrictId ?? '',
                  bodyId: controller.selectedZPBodyId ?? '',
                  name: '',
                  stateId: controller.selectedStateId ?? '',
                  areas: null,
                ),
              );

              if (zpWard != null && zpWard.areas != null && zpWard.areas!.isNotEmpty) {
                return InkWell(
                  onTap: () => _showZPAreaSelectionModal(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: localizations.selectZPAreaLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: controller.selectedZPArea != null
                        ? Text(
                            controller.selectedZPArea!,
                            style: const TextStyle(fontSize: 16),
                          )
                        : Text(
                            localizations.selectZPArea.toLowerCase(),
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

  void _showZPAreaSelectionModal(BuildContext context) {
    // Get ZP ward object
    final zpWard = controller.bodyWards[controller.selectedZPBodyId!]?.firstWhere(
      (ward) => ward.id == controller.selectedZPWardId,
      orElse: () => Ward(
        id: '',
        districtId: controller.selectedDistrictId ?? '',
        bodyId: controller.selectedZPBodyId ?? '',
        name: '',
        stateId: controller.selectedStateId ?? '',
        areas: null,
      ),
    );

    if (zpWard != null && zpWard.areas != null && zpWard.areas!.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return AreaInWardSelectionModal(
            ward: zpWard,
            selectedArea: controller.selectedZPArea,
            onAreaSelected: controller.onZPAreaSelected,
          );
        },
      );
    }
  }
}