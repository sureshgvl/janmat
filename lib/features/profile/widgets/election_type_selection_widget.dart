import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../controllers/profile_completion_controller.dart';

class ElectionTypeSelectionWidget extends StatelessWidget {
  final ProfileCompletionController controller;

  const ElectionTypeSelectionWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Election Type Selection
        if (controller.selectedStateId != null && controller.selectedDistrictId != null)
          InkWell(
            onTap: () => _showElectionTypeSelectionModal(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.selectElectionType,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.how_to_vote),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              child: controller.selectedElectionType != null
                  ? Text(
                    _getElectionTypeDisplayName(controller.selectedElectionType!, localizations),
                    style: const TextStyle(fontSize: 16),
                  )
                  : Text(
                      localizations.selectElectionType.toLowerCase(),
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
                const Icon(Icons.how_to_vote, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'Select state and district first',
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

  void _showElectionTypeSelectionModal(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;
    final isCandidate = controller.currentUserRole == 'candidate';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.how_to_vote, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      localizations.selectElectionType,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Election Types List
              ListView(
                shrinkWrap: true,
                children: [
                  _buildElectionTypeOption(
                    context,
                    'municipal_corporation',
                    localizations.municipalCorporation,
                    Icons.business,
                  ),
                  _buildElectionTypeOption(
                    context,
                    'municipal_council',
                    localizations.municipalCouncil,
                    Icons.account_balance,
                  ),
                  _buildElectionTypeOption(
                    context,
                    'nagar_panchayat',
                    localizations.nagarPanchayat,
                    Icons.location_city,
                  ),
                  // Rural election types - only for candidates (voters use combined option)
                  if (isCandidate) ...[
                    _buildElectionTypeOption(
                      context,
                      'zilla_parishad',
                      localizations.zillaParishad,
                      Icons.account_balance_wallet,
                    ),
                    _buildElectionTypeOption(
                      context,
                      'panchayat_samiti',
                      localizations.panchayatSamiti,
                      Icons.group,
                    ),
                  ],
                  // Only show ZP+PS combined for voters, not candidates
                  if (!isCandidate)
                    _buildElectionTypeOption(
                      context,
                      'zp_ps_combined',
                      localizations.zpPsCombined,
                      Icons.group_work,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElectionTypeOption(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.selectedElectionType == value;

    return InkWell(
      onTap: () {
        controller.onElectionTypeSelected(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  String _getElectionTypeDisplayName(String electionType, ProfileLocalizations localizations) {
    switch (electionType) {
      case 'municipal_corporation':
        return localizations.municipalCorporation;
      case 'municipal_council':
        return localizations.municipalCouncil;
      case 'nagar_panchayat':
        return localizations.nagarPanchayat;
      case 'zilla_parishad':
        return localizations.zillaParishad;
      case 'panchayat_samiti':
        return localizations.panchayatSamiti;
      case 'zp_ps_combined':
        return localizations.zpPsCombined;
      default:
        return electionType;
    }
  }
}

