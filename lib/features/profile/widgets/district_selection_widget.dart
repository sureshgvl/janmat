import 'package:flutter/material.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../../widgets/profile/district_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class DistrictSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const DistrictSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District Selection
        if (controller.selectedStateId == null)
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
                const Icon(Icons.location_city, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  localizations.selectStateFirst,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else if (controller.isLoadingDistricts)
          const Center(child: CircularProgressIndicator())
        else
          InkWell(
            onTap: () => _showDistrictSelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.districtRequired,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedDistrictId != null
                  ? Text(
                      MaharashtraUtils.getDistrictDisplayNameV2(
                        controller.selectedDistrictId!,
                        Localizations.localeOf(context),
                      ),
                      style: const TextStyle(fontSize: 16),
                    )
                  : Text(
                      localizations.selectYourDistrict,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showDistrictSelectionModal(BuildContext context) {
    AppLogger.common('🔍 Opening District Selection Modal');
    AppLogger.common('📊 Available districts: ${controller.districts.length}');
    AppLogger.common('🏢 District bodies: ${controller.districtBodies.length}');
    AppLogger.common('🎯 Selected district: ${controller.selectedDistrictId}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DistrictSelectionModal(
          districts: controller.districts,
          districtBodies: controller.districtBodies,
          selectedDistrictId: controller.selectedDistrictId,
          onDistrictSelected: controller.updateSelectedDistrict,
        );
      },
    );
  }
}

