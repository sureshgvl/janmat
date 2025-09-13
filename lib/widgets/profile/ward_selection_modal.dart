import 'package:flutter/material.dart';
import '../../models/ward_model.dart';

class WardSelectionModal extends StatefulWidget {
  final List<Ward> wards;
  final String? selectedWardId;
  final Function(String) onWardSelected;

  const WardSelectionModal({
    super.key,
    required this.wards,
    required this.selectedWardId,
    required this.onWardSelected,
  });

  @override
  State<WardSelectionModal> createState() => _WardSelectionModalState();
}

class _WardSelectionModalState extends State<WardSelectionModal> {
  late List<Ward> filteredWards;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredWards = List.from(widget.wards);
  }

  void _filterWards(String query) {
    if (query.isEmpty) {
      filteredWards = List.from(widget.wards);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredWards = widget.wards.where((ward) {
        // Search in ward name
        final nameMatch = ward.name.toLowerCase().contains(lowerQuery);

        // Search in ward ID
        final idMatch = ward.wardId.toLowerCase().contains(lowerQuery);

        // Search in areas
        final areaMatch = ward.areas != null &&
                         ward.areas!.any((area) => area.toLowerCase().contains(lowerQuery));

        // Search in Marathi ward number (e.g., "ward 10" should find "वॉर्ड 10")
        final numberMatch = RegExp(r'ward\s*(\d+)').firstMatch(lowerQuery) != null &&
                           ward.wardId.toLowerCase().contains('ward_${RegExp(r'ward\s*(\d+)').firstMatch(lowerQuery)!.group(1)}');

        // Search in Marathi "वॉर्ड X" format
        final marathiMatch = lowerQuery.contains('वॉर्ड') &&
                            ward.wardId.toLowerCase().contains('ward_');

        return nameMatch || idMatch || areaMatch || numberMatch || marathiMatch;
      }).toList();
    }
    setState(() {});
  }

  // Convert ward_id to Marathi format (e.g., "ward_1" -> "वॉर्ड 1")
  String _formatWardDisplay(String wardId, String wardName) {
    // Extract number from ward_id (e.g., "ward_1" -> "1")
    final numberMatch = RegExp(r'ward_(\d+)').firstMatch(wardId.toLowerCase());
    if (numberMatch != null) {
      final wardNumber = numberMatch.group(1);
      return 'वॉर्ड $wardNumber - $wardName';
    }
    // Fallback to original name if pattern doesn't match
    return wardName;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
              color: Colors.purple.shade50,
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
                      Icons.home,
                      color: Colors.purple,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Ward (वॉर्ड)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.purple,
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
                    hintText: 'Search wards...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterWards,
                ),
              ],
            ),
          ),

          // Ward List
          Expanded(
            child: filteredWards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_work,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No wards found',
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
                    itemCount: filteredWards.length,
                    itemBuilder: (context, index) {
                      final ward = filteredWards[index];
                      final isSelected = widget.selectedWardId == ward.wardId;

                      return InkWell(
                        onTap: () {
                          widget.onWardSelected(ward.wardId);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.purple.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.purple.shade200 : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.purple.shade100,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.home,
                                color: Colors.purple,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatWardDisplay(ward.wardId, ward.name),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.purple.shade800 : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          ward.wardId.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (ward.areas != null && ward.areas!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${ward.areas!.length} areas',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Show areas preview if available
                                    if (ward.areas != null && ward.areas!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Areas: ${ward.areas!.take(3).join(", ")}${ward.areas!.length > 3 ? " +${ward.areas!.length - 3} more" : ""}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.purple,
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
