import 'package:flutter/material.dart';
import '../../models/district_model.dart';
import '../../models/body_model.dart';
import '../../l10n/features/profile/profile_localizations.dart';
import '../../utils/location_translations.dart';

class DistrictSelectionModal extends StatefulWidget {
  final List<District> districts;
  final Map<String, List<Body>> districtBodies;
  final String? selectedDistrictId;
  final Function(String) onDistrictSelected;

  const DistrictSelectionModal({
    super.key,
    required this.districts,
    required this.districtBodies,
    required this.selectedDistrictId,
    required this.onDistrictSelected,
  });

  @override
  State<DistrictSelectionModal> createState() => _DistrictSelectionModalState();
}

class _DistrictSelectionModalState extends State<DistrictSelectionModal> {
  late List<District> filteredDistricts;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredDistricts = List.from(widget.districts);
  }

  void _filterDistricts(String query) {
    if (query.isEmpty) {
      filteredDistricts = List.from(widget.districts);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredDistricts = widget.districts.where((district) {
        // Search in district name
        final nameMatch = district.name.toLowerCase().contains(lowerQuery);

        // Search in district ID
        final idMatch = district.id.toLowerCase().contains(lowerQuery);

        // Search for Marathi equivalents (e.g., "pune" should find "पुणे")
        final marathiMatch = _hasMarathiEquivalent(district.name, lowerQuery);

        return nameMatch || idMatch || marathiMatch;
      }).toList();
    }
    setState(() {});
  }

  // Check if district name has Marathi equivalent of English query
  bool _hasMarathiEquivalent(String districtName, String query) {
    final Map<String, List<String>> marathiEquivalents = {
      'pune': ['पुणे', 'पुणे'],
      'mumbai': ['मुंबई', 'मुंबई'],
      'thane': ['ठाणे', 'ठाणे'],
      'nagpur': ['नागपूर', 'नागपूर'],
      'nashik': ['नाशिक', 'नाशिक'],
      'aurangabad': ['औरंगाबाद', 'औरंगाबाद'],
      'solapur': ['सोलापूर', 'सोलापूर'],
      'kolhapur': ['कोल्हापूर', 'कोल्हापूर'],
      'satara': ['सातारा', 'सातारा'],
      'sangli': ['सांगली', 'सांगली'],
      'ahmednagar': ['अहमदनगर', 'अहमदनगर'],
      'jalgaon': ['जळगाव', 'जळगाव'],
      'dhule': ['धुळे', 'धुळे'],
      'buldhana': ['बुलढाणा', 'बुलढाणा'],
      'akola': ['अकोला', 'अकोला'],
      'washim': ['वाशीम', 'वाशीम'],
      'amravati': ['अमरावती', 'अमरावती'],
      'wardha': ['वर्धा', 'वर्धा'],
      'yavatmal': ['यवतमाळ', 'यवतमाळ'],
      'hingoli': ['हिंगोली', 'हिंगोली'],
      'nanded': ['नांदेड', 'नांदेड'],
      'latur': ['लातूर', 'लातूर'],
      'osmanabad': ['उस्मानाबाद', 'उस्मानाबाद'],
      'beed': ['बीड', 'बीड'],
      'parbhani': ['परभणी', 'परभणी'],
      'jalna': ['जालना', 'जालना'],
      'raigad': ['रायगड', 'रायगड'],
      'ratnagiri': ['रत्नागिरी', 'रत्नागिरी'],
      'sindhudurg': ['सिंधुदुर्ग', 'सिंधुदुर्ग'],
      'palghar': ['पालघर', 'पालघर'],
      'gondia': ['गोंदिया', 'गोंदिया'],
      'bhandara': ['भंडारा', 'भंडारा'],
      'chandrapur': ['चंद्रपूर', 'चंद्रपूर'],
      'gadchiroli': ['गडचिरोली', 'गडचिरोली'],
    };

    final districtLower = districtName.toLowerCase();
    final equivalents = marathiEquivalents[query] ?? [];

    return equivalents.any(
      (equivalent) => districtLower.contains(equivalent.toLowerCase()),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

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
                      Icons.location_city,
                      color: Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations.selectDistrict,
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
                    hintText: localizations.searchDistricts,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterDistricts,
                ),
              ],
            ),
          ),

          // District List
          Expanded(
            child: filteredDistricts.isEmpty
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
                          'No districts found',
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
                    itemCount: filteredDistricts.length,
                    itemBuilder: (context, index) {
                      final district = filteredDistricts[index];
                      final isSelected =
                          widget.selectedDistrictId == district.id;
                      final hasBodies =
                          widget
                              .districtBodies[district.id]
                              ?.isNotEmpty ??
                          false;
                      final isDisabled = !hasBodies;

                      return InkWell(
                        onTap: isDisabled
                            ? null
                            : () {
                                widget.onDistrictSelected(district.id);
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
                                : isDisabled
                                ? Colors.grey.shade100
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade200
                                  : isDisabled
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
                                Icons.location_city,
                                color: isDisabled
                                    ? Colors.grey.shade400
                                    : Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocationTranslations.getDistrictDisplayName(
                                        district.id,
                                        Localizations.localeOf(context),
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.blue.shade800
                                            : isDisabled
                                            ? Colors.grey.shade500
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          district.id.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDisabled
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        if (isDisabled) ...[
                                          const SizedBox(width: 8),
                                          Container(
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
                                              'No Areas',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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
