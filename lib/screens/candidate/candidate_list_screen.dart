import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_controller.dart';
import '../../models/city_model.dart';
import '../../models/ward_model.dart';
import '../../widgets/modal_selector.dart';

class CandidateListScreen extends StatefulWidget {
  final String? initialCityId;
  final String? initialWardId;

  const CandidateListScreen({
    super.key,
    this.initialCityId,
    this.initialWardId,
  });

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  final CandidateController controller = Get.put(CandidateController());
  City? selectedCity;
  Ward? selectedWard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.fetchAllCities();

      if (widget.initialCityId != null && controller.cities.isNotEmpty) {
        // Set initial city if provided
        final city = controller.cities.firstWhere(
          (city) => city.cityId == widget.initialCityId,
          orElse: () => controller.cities.isNotEmpty ? controller.cities.first : City(cityId: '', name: '', state: '', population: 0, wardIds: []),
        );
        if (city.cityId.isNotEmpty) {
          setState(() => selectedCity = city);
          await controller.fetchWardsByCity(city.cityId);

          if (widget.initialWardId != null) {
            // Set initial ward if provided
            await controller.fetchCandidatesByWard(city.cityId, widget.initialWardId!);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Candidates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<CandidateController>(
        builder: (controller) {
          return Column(
            children: [
              // City and Ward Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // City Dropdown
                    ModalSelector<City>(
                      title: 'Select City',
                      label: 'City',
                      hint: 'Select City',
                      items: controller.cities.map((city) {
                        return DropdownMenuItem<City>(
                          value: city,
                          child: Text('${city.name} (${city.state})'),
                        );
                      }).toList(),
                      value: selectedCity,
                      onChanged: (city) {
                        print('🔍 [City Selected] ID: ${city?.cityId}, Name: ${city?.name}');
                        setState(() {
                          selectedCity = city;
                          selectedWard = null;
                        });
                        if (city != null) {
                          print('📍 [Fetching Wards] For city: ${city.name} (${city.cityId})');
                          controller.fetchWardsByCity(city.cityId);
                          controller.clearCandidates();
                        } else {
                          print('❌ [City Cleared] No city selected');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ward Dropdown
                    ModalSelector<Ward>(
                      title: 'Select Ward',
                      label: 'Ward',
                      hint: 'Select Ward',
                      items: controller.wards.map((ward) {
                        return DropdownMenuItem<Ward>(
                          value: ward,
                          child: Text('${ward.name} (${ward.areas.length} areas)'),
                        );
                      }).toList(),
                      value: selectedWard,
                      enabled: selectedCity != null,
                      onChanged: (ward) {
                        if (selectedCity != null) {
                          print('🏛️ [Ward Selected] ID: ${ward?.wardId}, Name: ${ward?.name}, Areas: ${ward?.areas.length}');
                          setState(() => selectedWard = ward);
                          if (ward != null) {
                            print('👥 [Fetching Candidates] City: ${selectedCity!.name} (${selectedCity!.cityId}), Ward: ${ward.name} (${ward.wardId})');
                            controller.fetchCandidatesByWard(selectedCity!.cityId, ward.wardId);
                          } else {
                            print('❌ [Ward Cleared] No ward selected');
                          }
                        } else {
                          print('⚠️ [Ward Selection Skipped] No city selected yet');
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Results Section
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  controller.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.clearError();
                                    if (selectedCity != null && selectedWard != null) {
                                      controller.fetchCandidatesByWard(
                                        selectedCity!.cityId,
                                        selectedWard!.wardId,
                                      );
                                    }
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : controller.candidates.isEmpty && selectedWard != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No candidates found',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No candidates available in ${selectedWard!.name}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : selectedWard == null
                                ? const Center(
                                    child: Text(
                                      'Select a ward to view candidates',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: controller.candidates.length,
                                    itemBuilder: (context, index) {
                                      final candidate = controller.candidates[index];
                                      return _buildCandidateCard(context, candidate);
                                    },
                                  ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, candidate) {
    // Get party symbol path
    String getPartySymbolPath(String party) {
      print('🔍 [Mapping Party Symbol] For party: $party');
      final partySymbols = {
        'Indian National Congress': 'assets/symbols/inc.png',
        'Bharatiya Janata Party': 'assets/symbols/bjp.png',
        'Nationalist Congress Party (Ajit Pawar faction)': 'assets/symbols/ncp_ajit.png',
        'Nationalist Congress Party – Sharadchandra Pawar': 'assets/symbols/ncp_sp.png',
        'Shiv Sena (Eknath Shinde faction)': 'assets/symbols/shiv_sena_shinde.png',
        'Shiv Sena (Uddhav Balasaheb Thackeray – UBT)': 'assets/symbols/shiv_sena_ubt.jpeg',
        'Maharashtra Navnirman Sena': 'assets/symbols/mns.png',
        'Communist Party of India': 'assets/symbols/cpi.png',
        'Communist Party of India (Marxist)': 'assets/symbols/cpi_m.png',
        'Bahujan Samaj Party': 'assets/symbols/bsp.png',
        'Samajwadi Party': 'assets/symbols/sp.png',
        'All India Majlis-e-Ittehad-ul-Muslimeen': 'assets/symbols/aimim.png',
        'National Peoples Party': 'assets/symbols/npp.png',
        'Peasants and Workers Party of India': 'assets/symbols/pwp.jpg',
        'Vanchit Bahujan Aaghadi': 'assets/symbols/vba.png',
        'Rashtriya Samaj Paksha': 'assets/symbols/default.png',
      };

      // First try exact match
      if (partySymbols.containsKey(party)) {
        return partySymbols[party]!;
      }

      // Try case-insensitive match
      final upperParty = party.toUpperCase();
      for (var entry in partySymbols.entries) {
        if (entry.key.toUpperCase() == upperParty) {
          return entry.value;
        }
      }

      // Try partial matches for common variations
      final partialMatches = {
        'INDIAN NATIONAL CONGRESS': 'assets/symbols/inc.png',
        'INDIA NATIONAL CONGRESS': 'assets/symbols/inc.png',
        'BHARATIYA JANATA PARTY': 'assets/symbols/bjp.png',
        'NATIONALIST CONGRESS PARTY': 'assets/symbols/ncp_ajit.png',
        'NATIONALIST CONGRESS PARTY AJIT': 'assets/symbols/ncp_ajit.png',
        'NATIONALIST CONGRESS PARTY SP': 'assets/symbols/ncp_sp.png',
        'SHIV SENA': 'assets/symbols/shiv_sena_ubt.jpeg',
        'SHIV SENA UBT': 'assets/symbols/shiv_sena_ubt.jpeg',
        'SHIV SENA SHINDE': 'assets/symbols/shiv_sena_shinde.png',
        'MAHARASHTRA NAVNIRMAN SENA': 'assets/symbols/mns.png',
        'COMMUNIST PARTY OF INDIA': 'assets/symbols/cpi.png',
        'COMMUNIST PARTY OF INDIA MARXIST': 'assets/symbols/cpi_m.png',
        'BAHUJAN SAMAJ PARTY': 'assets/symbols/bsp.png',
        'SAMAJWADI PARTY': 'assets/symbols/sp.png',
        'ALL INDIA MAJLIS E ITTEHADUL MUSLIMEEN': 'assets/symbols/aimim.png',
        'ALL INDIA MAJLIS-E-ITTEHADUL MUSLIMEEN': 'assets/symbols/aimim.png',
        'NATIONAL PEOPLES PARTY': 'assets/symbols/npp.png',
        'PEASANT AND WORKERS PARTY': 'assets/symbols/pwp.jpg',
        'VANCHIT BAHUJAN AGHADI': 'assets/symbols/vba.png',
        'REVOLUTIONARY SOCIALIST PARTY': 'assets/symbols/default.png',
      };

      for (var entry in partialMatches.entries) {
        if (upperParty.contains(entry.key.toUpperCase().replaceAll(' ', '')) ||
            entry.key.toUpperCase().contains(upperParty.replaceAll(' ', ''))) {
          return entry.value;
        }
      }

      return 'assets/symbols/default.png';
    }

    return GestureDetector(
      onTap: () {
        // Navigate to candidate profile
        Get.toNamed('/candidate-profile', arguments: candidate);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Candidate Photo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: candidate.sponsored ? Colors.amber : Colors.blue,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: candidate.photo != null && candidate.photo!.isNotEmpty
                      ? Image.network(
                          candidate.photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return CircleAvatar(
                              backgroundColor: candidate.sponsored ? Colors.amber : Colors.blue,
                              child: Text(
                                candidate.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            );
                          },
                        )
                      : CircleAvatar(
                          backgroundColor: candidate.sponsored ? Colors.amber : Colors.blue,
                          child: Text(
                            candidate.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Candidate Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Party with Symbol
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            image: DecorationImage(
                              image: AssetImage(getPartySymbolPath(candidate.party)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            candidate.party,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Manifesto
                    if (candidate.manifesto != null && candidate.manifesto!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          candidate.manifesto!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9ca3af),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Sponsored Badge
                    if (candidate.sponsored)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Text(
                          'SPONSORED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400e),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Phone Number
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    candidate.contact.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}