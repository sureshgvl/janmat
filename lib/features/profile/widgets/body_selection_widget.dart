import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../models/body_model.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../../widgets/profile/area_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class BodySelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const BodySelectionWidget({
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
            controller.selectedDistrictId != null &&
            controller.districtBodies[controller.selectedDistrictId!] != null &&
            controller.districtBodies[controller.selectedDistrictId!]!.isNotEmpty)
          InkWell(
            onTap: () => _showBodySelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.areaLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.business),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedBodyId != null
                  ? Builder(
                      builder: (context) {
                        final body =
                            controller.districtBodies[controller.selectedDistrictId!]!
                                .firstWhere(
                                  (b) => b.id == controller.selectedBodyId,
                                  orElse: () => Body(
                                    id: '',
                                    name: '',
                                    type: BodyType.municipal_corporation,
                                    districtId: '',
                                    stateId: '',
                                  ),
                                );
                        return Text(
                          body.id.isNotEmpty
                              ? '${MaharashtraUtils.getDistrictDisplayNameV2(controller.selectedDistrictId!, Localizations.localeOf(context))} - ${MaharashtraUtils.getBodyTypeDisplayNameV2(body.type.toString().split('.').last, Localizations.localeOf(context))}'
                              : controller.selectedBodyId!,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    )
                  : Text(
                      localizations.selectAreaLabel,
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
                const Icon(Icons.business, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  controller.selectedStateId == null
                      ? localizations.selectStateFirst
                      : controller.selectedDistrictId == null
                          ? localizations.selectDistrictFirst
                          : controller.districtBodies[controller.selectedDistrictId!] == null ||
                                controller.districtBodies[controller.selectedDistrictId!]!.isEmpty
                          ? localizations.noAreasAvailable
                          : localizations.selectAreaLabel,
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

  void _showBodySelectionModal(BuildContext context) {
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
          bodies: controller.districtBodies[controller.selectedDistrictId!]!,
          selectedBodyId: controller.selectedBodyId,
          districtName: districtName,
          onBodySelected: (bodyId) {
            controller.updateSelectedBody(bodyId);
            controller.loadWards(controller.selectedDistrictId!, bodyId, context);
          },
        );
      },
    );
  }
}