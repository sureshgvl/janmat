import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../widgets/profile/state_selection_modal.dart';
import '../controllers/profile_completion_controller.dart';

class StateSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const StateSelectionWidget({
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
}

