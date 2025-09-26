import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../models/body_model.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../../widgets/profile/state_selection_modal.dart';
import '../../../widgets/profile/district_selection_modal.dart';
import '../../../widgets/profile/area_selection_modal.dart';
import '../../../widgets/profile/ward_selection_modal.dart';
import '../../../widgets/profile/area_in_ward_selection_modal.dart';
import '../../../widgets/profile/party_selection_modal.dart';
import '../../../utils/symbol_utils.dart';
import '../controllers/profile_completion_controller.dart';

class LocationSelectionSection extends StatelessWidget {
  final ProfileCompletionController controller;

  const LocationSelectionSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State Selection
        if (controller.isLoadingStates)
          const Center(child: CircularProgressIndicator())
        else
          InkWell(
            onTap: () => _showStateSelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.stateRequired,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.map),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedStateId != null
                  ? Builder(
                      builder: (context) {
                        final selectedState = controller.states.firstWhere(
                          (state) => state.id == controller.selectedStateId,
                        );
                        // Show Marathi name if available, otherwise English name
                        final displayName = selectedState.marathiName ?? selectedState.name;
                        return Text(
                          displayName,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    )
                  : Text(
                      localizations.selectYourState,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 24),

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

        // Area Selection (only show if ward has areas and user is not a candidate)
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

        // Party Selection (only for candidates)
        if (controller.currentUserRole == 'candidate') ...[
          if (controller.isLoadingParties)
            const Center(child: CircularProgressIndicator())
          else
            InkWell(
              onTap: () => _showPartySelectionModal(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: localizations.politicalPartyRequired,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.flag),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: controller.selectedParty != null
                    ? Row(
                        children: [
                          // Selected Party Symbol
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 12),
                            child: Image(
                              image: SymbolUtils.getSymbolImageProvider(
                                SymbolUtils.getPartySymbolPathFromParty(
                                  controller.selectedParty!,
                                ),
                              ),
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return const Icon(
                                  Icons.flag,
                                  size: 28,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                          // Selected Party Name
                          Expanded(
                            child: Text(
                              controller.selectedParty!.getDisplayName(
                                Localizations.localeOf(
                                  context,
                                ).languageCode,
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        localizations.pleaseSelectYourPoliticalParty,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  void _showStateSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StateSelectionModal(
          states: controller.states,
          selectedStateId: controller.selectedStateId,
          onStateSelected: controller.updateSelectedState,
        );
      },
    );
  }

  void _showDistrictSelectionModal(BuildContext context) {
    debugPrint('🔍 Opening District Selection Modal');
    debugPrint('📊 Available districts: ${controller.districts.length}');
    debugPrint('🏢 District bodies: ${controller.districtBodies.length}');
    debugPrint('🎯 Selected district: ${controller.selectedDistrictId}');

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

  void _showPartySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PartySelectionModal(
          parties: controller.parties,
          selectedPartyId: controller.selectedParty?.id,
          onPartySelected: (partyId) {
            controller.updateSelectedParty(controller.parties.firstWhere(
              (party) => party.id == partyId,
            ));
          },
        );
      },
    );
  }
}