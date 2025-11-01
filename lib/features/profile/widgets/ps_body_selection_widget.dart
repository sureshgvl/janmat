import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../models/body_model.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../../widgets/modals/area_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class PSBodySelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const PSBodySelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PS Body Selection (only show for ZP+PS combined elections after ZP ward is selected)
        if (controller.selectedElectionType == 'zp_ps_combined' &&
            controller.selectedZPWardId != null) ...[
          InkWell(
            onTap: () => _showPSBodySelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.selectPSBody,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.business, color: Colors.green),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedPSBodyId != null
                  ? Builder(
                      builder: (context) {
                        final body =
                            controller.districtBodies[controller.selectedDistrictId!]!
                                .firstWhere(
                                  (b) => b.id == controller.selectedPSBodyId,
                                  orElse: () => Body(
                                    id: '',
                                    name: '',
                                    type: BodyType.panchayat_samiti,
                                    districtId: '',
                                    stateId: '',
                                  ),
                                );
                        return Text(
                          body.id.isNotEmpty
                              ? '${body.name} (PS)'
                              : controller.selectedPSBodyId!,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    )
                  : Text(
                      localizations.selectPSBody.toLowerCase(),
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
                const Icon(Icons.business, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  localizations.selectPSBody.toLowerCase(),
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

  void _showPSBodySelectionModal(BuildContext context) {
    final districtName = MaharashtraUtils.getDistrictDisplayNameV2(
      controller.selectedDistrictId!,
      Localizations.localeOf(context),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaSelectionModal(
          bodies: controller.districtBodies[controller.selectedDistrictId!]!
              .where((body) => body.type == BodyType.panchayat_samiti)
              .toList(),
          selectedBodyId: controller.selectedPSBodyId,
          districtName: districtName,
          onBodySelected: (bodyId) {
            controller.onPSBodySelected(bodyId);
            controller.loadWards(controller.selectedDistrictId!, bodyId, context);
          },
        );
      },
    );
  }
}

