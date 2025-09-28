import 'package:flutter/material.dart';
import 'state_selection_widget.dart';
import 'district_selection_widget.dart';
import 'election_type_selection_widget.dart';
import 'body_selection_widget.dart';
import 'ward_selection_widget.dart';
import 'area_selection_widget.dart';
import 'zp_body_selection_widget.dart';
import 'zp_ward_selection_widget.dart';
import 'zp_area_selection_widget.dart';
import 'ps_body_selection_widget.dart';
import 'ps_ward_selection_widget.dart';
import 'ps_area_selection_widget.dart';
import 'party_selection_widget.dart';
import '../controllers/profile_completion_controller.dart';

class LocationSelectionSection extends StatelessWidget {
  final ProfileCompletionController controller;

  const LocationSelectionSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State Selection
        StateSelectionWidget(controller: controller),
        const SizedBox(height: 24),

        // District Selection
        DistrictSelectionWidget(controller: controller),
        const SizedBox(height: 24),

        // Election Type Selection
        ElectionTypeSelectionWidget(controller: controller),

        // ZP+PS Combined Election Flow
        if (controller.selectedElectionType == 'zp_ps_combined') ...[
          // ZP Body Selection
          ZPBodySelectionWidget(controller: controller),

          // ZP Ward Selection
          ZPWardSelectionWidget(controller: controller),

          // ZP Area Selection (if ward has areas)
          ZPAreaSelectionWidget(controller: controller),

          // PS Body Selection
          PSBodySelectionWidget(controller: controller),

          // PS Ward Selection
          PSWardSelectionWidget(controller: controller),

          // PS Area Selection (if ward has areas)
          PSAreaSelectionWidget(controller: controller),
        ] else ...[
          // Regular Election Flow
          // Body Selection
          BodySelectionWidget(controller: controller),

          // Ward Selection
          WardSelectionWidget(controller: controller),

          // Area Selection (if ward has areas)
          AreaSelectionWidget(controller: controller),
        ],

        // Party Selection for Candidates
        if (controller.currentUserRole == 'candidate') ...[
          const SizedBox(height: 24),
          PartySelectionWidget(controller: controller),
        ],
      ],
    );
  }
}