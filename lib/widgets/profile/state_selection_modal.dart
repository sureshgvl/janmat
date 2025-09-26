import 'package:flutter/material.dart';
import '../../models/state_model.dart' as state_model;
import '../../l10n/app_localizations.dart';

class StateSelectionModal extends StatefulWidget {
  final List<state_model.State> states;
  final String? selectedStateId;
  final Function(String) onStateSelected;

  const StateSelectionModal({
    super.key,
    required this.states,
    required this.selectedStateId,
    required this.onStateSelected,
  });

  @override
  State<StateSelectionModal> createState() => _StateSelectionModalState();
}

class _StateSelectionModalState extends State<StateSelectionModal> {
  late List<state_model.State> filteredStates;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredStates = List.from(widget.states);
  }

  void _filterStates(String query) {
    if (query.isEmpty) {
      filteredStates = List.from(widget.states);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredStates = widget.states.where((state) {
        // Search in state name
        final nameMatch = state.name.toLowerCase().contains(lowerQuery);

        // Search in Marathi name
        final marathiNameMatch = state.marathiName?.toLowerCase().contains(lowerQuery) ?? false;

        // Search in state ID
        final idMatch = state.id.toLowerCase().contains(lowerQuery);

        // Search in state code
        final codeMatch = state.code?.toLowerCase().contains(lowerQuery) ?? false;

        return nameMatch || marathiNameMatch || idMatch || codeMatch;
      }).toList();
    }
    setState(() {});
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Debug: Print loaded states
    debugPrint('🔍 StateSelectionModal - Building with ${widget.states.length} states');
    for (final state in widget.states) {
      debugPrint('   State: ${state.id} - Name: ${state.name} - Marathi: ${state.marathiName} - Code: ${state.code}');
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.map,
                      color: Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select State',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Field
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search states...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterStates,
                ),
              ],
            ),
          ),

          // State List
          Expanded(
            child: filteredStates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No states found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredStates.length,
                    itemBuilder: (context, index) {
                      final state = filteredStates[index];
                      final isSelected = widget.selectedStateId == state.id;
                      final isActive = state.isActive ?? true;

                      return InkWell(
                        onTap: !isActive
                            ? null
                            : () {
                                widget.onStateSelected(state.id);
                                Navigator.of(context).pop();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : !isActive
                                ? Colors.grey.shade100
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade200
                                  : !isActive
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.shade100,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map,
                                color: !isActive
                                    ? Colors.grey.shade400
                                    : Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Primary name (Marathi if available, otherwise English)
                                    Text(
                                      state.marathiName ?? state.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.blue.shade800
                                            : !isActive
                                            ? Colors.grey.shade500
                                            : Colors.black87,
                                      ),
                                    ),
                                    // Secondary line: English name + state code (no brackets)
                                    Text(
                                      '${state.name}${state.code != null ? ' ${state.code}' : ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: !isActive
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    // Show inactive status if applicable
                                    if (!isActive)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Inactive',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}