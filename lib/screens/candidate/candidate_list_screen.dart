import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_controller.dart';
import '../../models/candidate_model.dart';
import '../../models/city_model.dart';
import '../../models/ward_model.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAllCities();

      if (widget.initialCityId != null) {
        // Set initial city if provided
        final city = controller.cities.firstWhere(
          (city) => city.cityId == widget.initialCityId,
          orElse: () => controller.cities.isNotEmpty ? controller.cities.first : City(cityId: '', name: '', state: '', population: 0, wardIds: []),
        );
        if (city.cityId.isNotEmpty) {
          setState(() => selectedCity = city);
          controller.fetchWardsByCity(city.cityId);

          if (widget.initialWardId != null) {
            // Set initial ward if provided
            controller.fetchCandidatesByWard(city.cityId, widget.initialWardId!);
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
                    DropdownButtonFormField<City>(
                      value: selectedCity,
                      hint: const Text('Select City'),
                      items: controller.cities.map((city) {
                        return DropdownMenuItem<City>(
                          value: city,
                          child: Text('${city.name} (${city.state})'),
                        );
                      }).toList(),
                      onChanged: (city) {
                        setState(() {
                          selectedCity = city;
                          selectedWard = null;
                        });
                        if (city != null) {
                          controller.fetchWardsByCity(city.cityId);
                          controller.clearCandidates();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ward Dropdown
                    DropdownButtonFormField<Ward>(
                      value: selectedWard,
                      hint: const Text('Select Ward'),
                      items: controller.wards.map((ward) {
                        return DropdownMenuItem<Ward>(
                          value: ward,
                          child: Text('${ward.name} (${ward.areas.length} areas)'),
                        );
                      }).toList(),
                      onChanged: selectedCity == null ? null : (ward) {
                        setState(() => selectedWard = ward);
                        if (ward != null && selectedCity != null) {
                          controller.fetchCandidatesByWard(selectedCity!.cityId, ward.wardId);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Ward',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: selectedCity == null ? Colors.grey[200] : Colors.white,
                        enabled: selectedCity != null,
                      ),
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
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: candidate.sponsored ? Colors.amber : Colors.blue,
                                            child: Text(
                                              candidate.name[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            candidate.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${candidate.party}'),
                                              if (candidate.manifesto != null)
                                                Text(
                                                  candidate.manifesto!,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              if (candidate.sponsored)
                                                const Text(
                                                  'Sponsored',
                                                  style: TextStyle(
                                                    color: Colors.amber,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Text(
                                            candidate.contact.phone,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          isThreeLine: candidate.manifesto != null,
                                        ),
                                      );
                                    },
                                  ),
              ),
            ],
          );
        },
      ),
    );
  }
}