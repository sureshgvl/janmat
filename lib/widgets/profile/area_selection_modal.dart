import 'package:flutter/material.dart';
import '../../models/body_model.dart';
import '../../utils/maharashtra_utils.dart';

class AreaSelectionModal extends StatefulWidget {
   final List<Body> bodies;
   final String? selectedBodyId;
   final String districtName;
   final Function(String) onBodySelected;

   const AreaSelectionModal({
     super.key,
     required this.bodies,
     required this.selectedBodyId,
     required this.districtName,
     required this.onBodySelected,
   });

  @override
  State<AreaSelectionModal> createState() => _AreaSelectionModalState();
}

class _AreaSelectionModalState extends State<AreaSelectionModal> {
  late List<Body> filteredBodies;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredBodies = List.from(widget.bodies);
  }

  void _filterBodies(String query) {
    if (query.isEmpty) {
      filteredBodies = List.from(widget.bodies);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredBodies = widget.bodies.where((body) {
        // Search in body name
        final nameMatch = body.name.toLowerCase().contains(lowerQuery);

        // Search in body type
        final typeMatch = body.type.toString().toLowerCase().contains(lowerQuery);

        // Search in body ID
        final idMatch = body.id.toLowerCase().contains(lowerQuery);

        // Search for Marathi equivalents (e.g., "municipal" should find "नगरपालिका")
        final marathiMatch = _hasMarathiEquivalent(
          body.name,
          body.type,
          lowerQuery,
        );

        return nameMatch || typeMatch || idMatch || marathiMatch;
      }).toList();
    }
    setState(() {});
  }

  // Check if body name or type has Marathi equivalent of English query
  bool _hasMarathiEquivalent(String bodyName, BodyType bodyType, String query) {
    final Map<String, List<String>> marathiEquivalents = {
      'municipal': ['नगरपालिका', 'नगर परिषद', 'नगर पंचायत'],
      'corporation': ['महानगरपालिका', 'महापालिका'],
      'council': ['परिषद', 'नगर परिषद'],
      'panchayat': ['पंचायत', 'नगर पंचायत'],
      'zilha': ['जिल्हा', 'जिल्हा परिषद'],
      'nagar': ['नगर', 'नगरपालिका'],
      'palika': ['पालिका', 'नगरपालिका'],
      'parishad': ['परिषद', 'नगर परिषद'],
    };

    final bodyText = '$bodyName ${bodyType.toString().split('.').last}'.toLowerCase();
    final equivalents = marathiEquivalents[query] ?? [];

    return equivalents.any(
      (equivalent) => bodyText.contains(equivalent.toLowerCase()),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Area (विभाग)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.orange,
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
                    hintText: 'Search areas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterBodies,
                ),
              ],
            ),
          ),

          // Body List
          Expanded(
            child: filteredBodies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_center,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No areas found',
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
                    itemCount: filteredBodies.length,
                    itemBuilder: (context, index) {
                      final body = filteredBodies[index];
                      final isSelected = widget.selectedBodyId == body.id;

                      return InkWell(
                        onTap: () {
                          widget.onBodySelected(body.id);
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
                                ? Colors.orange.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orange.shade200
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.orange.shade100,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.business,
                                color: Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${MaharashtraUtils.getDistrictDisplayNameV2(widget.districtName, Localizations.localeOf(context))} - ${MaharashtraUtils.getBodyTypeDisplayNameV2(body.type.toString().split('.').last, Localizations.localeOf(context))}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.orange.shade800
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      body.id.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
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
                                    color: Colors.orange,
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
