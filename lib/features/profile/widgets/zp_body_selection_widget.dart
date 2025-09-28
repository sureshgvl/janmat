import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../models/body_model.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../../widgets/profile/area_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class ZPBodySelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const ZPBodySelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ZP Body Selection (only show for ZP+PS combined elections)
        if (controller.selectedElectionType == 'zp_ps_combined' &&
            controller.selectedStateId != null &&
            controller.selectedDistrictId != null &&
            controller.districtBodies[controller.selectedDistrictId!] != null &&
            controller.districtBodies[controller.selectedDistrictId!]!.isNotEmpty) ...[
          InkWell(
            onTap: () => _showZPBodySelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.selectZPBody,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.business, color: Colors.blue),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedZPBodyId != null
                  ? Builder(
                      builder: (context) {
                        final body =
                            controller.districtBodies[controller.selectedDistrictId!]!
                                .firstWhere(
                                  (b) => b.id == controller.selectedZPBodyId,
                                  orElse: () => Body(
                                    id: '',
                                    name: '',
                                    type: BodyType.zilla_parishad,
                                    districtId: '',
                                    stateId: '',
                                  ),
                                );
                        return Text(
                          body.id.isNotEmpty
                              ? '${body.name} (ZP)'
                              : controller.selectedZPBodyId!,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    )
                  : Text(
                      localizations.selectZPBody.toLowerCase(),
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
                  localizations.selectZPBody.toLowerCase(),
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

  void _showZPBodySelectionModal(BuildContext context) {
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
              .where((body) => body.type == BodyType.zilla_parishad)
              .toList(),
          selectedBodyId: controller.selectedZPBodyId,
          districtName: districtName,
          onBodySelected: (bodyId) {
            controller.onZPBodySelected(bodyId);
            controller.loadWards(controller.selectedDistrictId!, bodyId, context);
          },
        );
      },
    );
  }
}