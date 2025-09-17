import 'package:flutter/material.dart';
import '../../models/ward_model.dart';

class AreaInWardSelectionModal extends StatefulWidget {
  final Ward ward;
  final String? selectedArea;
  final Function(String) onAreaSelected;

  const AreaInWardSelectionModal({
    super.key,
    required this.ward,
    required this.selectedArea,
    required this.onAreaSelected,
  });

  @override
  State<AreaInWardSelectionModal> createState() =>
      _AreaInWardSelectionModalState();
}

class _AreaInWardSelectionModalState extends State<AreaInWardSelectionModal> {
  late List<String> filteredAreas;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredAreas = List.from(widget.ward.areas ?? []);
  }

  void _filterAreas(String query) {
    if (query.isEmpty) {
      filteredAreas = List.from(widget.ward.areas ?? []);
    } else {
      // Simple transliteration: convert common English letters to Marathi equivalents
      String transliteratedQuery = _transliterateToMarathi(query.toLowerCase());

      filteredAreas = (widget.ward.areas ?? []).where((area) {
        String areaLower = area.toLowerCase();
        String areaTransliterated = _transliterateToMarathi(areaLower);

        // Search in both original and transliterated forms
        return areaLower.contains(query.toLowerCase()) ||
            areaTransliterated.contains(transliteratedQuery) ||
            areaLower.contains(transliteratedQuery) ||
            areaTransliterated.contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  // Simple transliteration function for English to Marathi
  String _transliterateToMarathi(String english) {
    final Map<String, String> transliterationMap = {
      'a': 'अ',
      'aa': 'आ',
      'i': 'इ',
      'ee': 'ई',
      'u': 'उ',
      'oo': 'ऊ',
      'e': 'ए',
      'ai': 'ऐ',
      'o': 'ओ',
      'au': 'औ',
      'ka': 'क',
      'kha': 'ख',
      'ga': 'ग',
      'gha': 'घ',
      'nga': 'ङ',
      'cha': 'च',
      'chha': 'छ',
      'ja': 'ज',
      'jha': 'झ',
      'nya': 'ञ',
      'ta': 'त',
      'tha': 'थ',
      'da': 'द',
      'dha': 'ध',
      'na': 'न',
      'pa': 'प',
      'pha': 'फ',
      'ba': 'ब',
      'bha': 'भ',
      'ma': 'म',
      'ya': 'य',
      'ra': 'र',
      'la': 'ल',
      'va': 'व',
      'sha': 'श',
      'ssa': 'ष',
      'sa': 'स',
      'ha': 'ह',
      'k': 'क',
      'kh': 'ख',
      'g': 'ग',
      'gh': 'घ',
      'ng': 'ङ',
      'ch': 'च',
      'jh': 'झ',
      'ny': 'ञ',
      't': 'त',
      'th': 'थ',
      'd': 'द',
      'dh': 'ध',
      'n': 'न',
      'p': 'प',
      'ph': 'फ',
      'b': 'ब',
      'bh': 'भ',
      'm': 'म',
      'y': 'य',
      'r': 'र',
      'l': 'ल',
      'v': 'व',
      'sh': 'श',
      'ss': 'ष',
      's': 'स',
      'h': 'ह',
    };

    String result = english;
    transliterationMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
              color: Colors.green.shade50,
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
                      Icons.location_on,
                      color: Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select Area in ${widget.ward.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.green,
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
                    hintText: 'Search areas (English or Marathi)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterAreas,
                ),
              ],
            ),
          ),

          // Area List
          Expanded(
            child: filteredAreas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
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
                    itemCount: filteredAreas.length,
                    itemBuilder: (context, index) {
                      final area = filteredAreas[index];
                      final isSelected = widget.selectedArea == area;

                      return InkWell(
                        onTap: () {
                          widget.onAreaSelected(area);
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
                                ? Colors.green.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green.shade200
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.green.shade100,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  area,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.green.shade800
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
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
