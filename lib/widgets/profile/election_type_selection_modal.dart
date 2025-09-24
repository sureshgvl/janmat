import 'package:flutter/material.dart';

class ElectionType {
  final String key;
  final String nameEn;
  final String nameMr;
  final String descriptionEn;
  final String descriptionMr;
  final IconData icon;
  final Color color;

  const ElectionType({
    required this.key,
    required this.nameEn,
    required this.nameMr,
    required this.descriptionEn,
    required this.descriptionMr,
    required this.icon,
    required this.color,
  });
}

class ElectionTypeSelectionModal extends StatefulWidget {
  final String? selectedElectionType;
  final Function(String) onElectionTypeSelected;

  const ElectionTypeSelectionModal({
    super.key,
    required this.selectedElectionType,
    required this.onElectionTypeSelected,
  });

  @override
  State<ElectionTypeSelectionModal> createState() =>
      _ElectionTypeSelectionModalState();
}

class _ElectionTypeSelectionModalState extends State<ElectionTypeSelectionModal> {
  late List<ElectionType> filteredElectionTypes;
  final TextEditingController searchController = TextEditingController();

  // Election types based on Maharashtra elections
  final List<ElectionType> electionTypes = [
    ElectionType(
      key: 'municipal_corporation',
      nameEn: 'Municipal Corporation',
      nameMr: 'महानगरपालिका',
      descriptionEn: 'City-level elections for major cities like Mumbai, Pune, Nagpur',
      descriptionMr: 'मुंबई, पुणे, नागपूर यांसारख्या मोठ्या शहरांसाठी शहर-स्तरीय निवडणुका',
      icon: Icons.business,
      color: Colors.blue,
    ),
    ElectionType(
      key: 'municipal_council',
      nameEn: 'Municipal Council',
      nameMr: 'नगरपरिषद',
      descriptionEn: 'Town-level elections for medium-sized towns',
      descriptionMr: 'मध्यम आकाराच्या शहरांसाठी शहर-स्तरीय निवडणुका',
      icon: Icons.location_city,
      color: Colors.green,
    ),
    ElectionType(
      key: 'nagar_panchayat',
      nameEn: 'Nagar Panchayat',
      nameMr: 'नगर पंचायत',
      descriptionEn: 'Local body elections for small towns and villages',
      descriptionMr: 'लहान शहरे आणि गावांसाठी स्थानिक स्वराज्य संस्था निवडणुका',
      icon: Icons.home_work,
      color: Colors.orange,
    ),
    ElectionType(
      key: 'zilla_parishad',
      nameEn: 'Zilla Parishad',
      nameMr: 'जिल्हा परिषद',
      descriptionEn: 'District-level rural local body elections',
      descriptionMr: 'जिल्हा-स्तरीय ग्रामीण स्थानिक स्वराज्य संस्था निवडणुका',
      icon: Icons.account_balance,
      color: Colors.purple,
    ),
    ElectionType(
      key: 'panchayat_samiti',
      nameEn: 'Panchayat Samiti',
      nameMr: 'पंचायत समिती',
      descriptionEn: 'Block-level rural local body elections',
      descriptionMr: 'तालुका-स्तरीय ग्रामीण स्थानिक स्वराज्य संस्था निवडणुका',
      icon: Icons.group_work,
      color: Colors.teal,
    ),
    ElectionType(
      key: 'gram_panchayat',
      nameEn: 'Gram Panchayat',
      nameMr: 'ग्राम पंचायत',
      descriptionEn: 'Village-level local body elections',
      descriptionMr: 'गाव-स्तरीय स्थानिक स्वराज्य संस्था निवडणुका',
      icon: Icons.nature,
      color: Colors.brown,
    ),
  ];

  @override
  void initState() {
    super.initState();
    filteredElectionTypes = List.from(electionTypes);
  }

  void _filterElectionTypes(String query) {
    if (query.isEmpty) {
      filteredElectionTypes = List.from(electionTypes);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredElectionTypes = electionTypes.where((electionType) {
        return electionType.nameEn.toLowerCase().contains(lowerQuery) ||
               electionType.nameMr.toLowerCase().contains(lowerQuery) ||
               electionType.descriptionEn.toLowerCase().contains(lowerQuery) ||
               electionType.descriptionMr.toLowerCase().contains(lowerQuery) ||
               electionType.key.toLowerCase().contains(lowerQuery);
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.how_to_vote, color: Colors.indigo, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Election Type (निवडणूक प्रकार)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.indigo,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose the type of election you want to participate in or follow',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                // Search Field
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search election types...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterElectionTypes,
                ),
              ],
            ),
          ),

          // Election Types List
          Expanded(
            child: filteredElectionTypes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No election types found',
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
                    itemCount: filteredElectionTypes.length,
                    itemBuilder: (context, index) {
                      final electionType = filteredElectionTypes[index];
                      final isSelected = widget.selectedElectionType == electionType.key;

                      return InkWell(
                        onTap: () {
                          widget.onElectionTypeSelected(electionType.key);
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
                                ? electionType.color.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? electionType.color.withOpacity(0.3)
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: electionType.color.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: electionType.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  electionType.icon,
                                  color: electionType.color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${electionType.nameEn} / ${electionType.nameMr}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? electionType.color.withOpacity(0.8)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      electionType.descriptionEn,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      electionType.descriptionMr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: electionType.color,
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