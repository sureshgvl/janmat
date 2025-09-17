import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/candidate_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ward_model.dart';
import '../../models/district_model.dart';
import '../../models/body_model.dart';
import '../../utils/symbol_utils.dart';
import '../../widgets/profile/district_selection_modal.dart';
import '../../widgets/profile/area_selection_modal.dart';
import '../../widgets/profile/ward_selection_modal.dart';

class CandidateListScreen extends StatefulWidget {
  final String? initialDistrictId;
  final String? initialBodyId;
  final String? initialWardId;

  const CandidateListScreen({
    super.key,
    this.initialDistrictId,
    this.initialBodyId,
    this.initialWardId,
  });

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  final CandidateController controller = Get.put(CandidateController());
  String? selectedDistrictId;
  String? selectedBodyId;
  Ward? selectedWard;

  List<District> districts = [];
  Map<String, List<Body>> districtBodies = {};
  Map<String, List<Ward>> bodyWards = {};
  bool isLoadingDistricts = true;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    try {
      // Load districts from Firestore
      final districtsSnapshot = await FirebaseFirestore.instance.collection('districts').get();
      districts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        return District.fromJson({
          'districtId': doc.id,
          ...data,
        });
      }).toList();

      // Load bodies for each district
      for (final district in districts) {
        final bodiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(district.districtId)
            .collection('bodies')
            .get();
        districtBodies[district.districtId] = bodiesSnapshot.docs.map((doc) {
          final data = doc.data();
          return Body.fromJson({
            'bodyId': doc.id,
            'districtId': district.districtId,
            ...data,
          });
        }).toList();
      }

      setState(() {
        isLoadingDistricts = false;
      });

      // Set initial values if provided
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (widget.initialDistrictId != null && districts.any((d) => d.districtId == widget.initialDistrictId)) {
          setState(() => selectedDistrictId = widget.initialDistrictId);

          if (widget.initialBodyId != null && districtBodies[widget.initialDistrictId]?.contains(widget.initialBodyId) == true) {
            setState(() => selectedBodyId = widget.initialBodyId);
            await _loadWards(widget.initialDistrictId!, widget.initialBodyId!, context);

            if (widget.initialWardId != null) {
              // Set initial ward if provided
              final ward = bodyWards[widget.initialBodyId]?.firstWhere(
                (ward) => ward.wardId == widget.initialWardId,
                orElse: () => Ward(wardId: '', name: '', areas: [], districtId: '', bodyId: ''),
              );
              if (ward != null && ward.wardId.isNotEmpty) {
                setState(() => selectedWard = ward);
                await controller.fetchCandidatesByWard(widget.initialDistrictId!, widget.initialBodyId!, widget.initialWardId!);
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading districts: $e');
      setState(() {
        isLoadingDistricts = false;
      });
    }
  }

  Future<void> _loadWards(String districtId, String bodyId, BuildContext context) async {
    try {
      // Load wards for the selected district and body
      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      bodyWards[bodyId] = wardsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Ward.fromJson({
          ...data,
          'wardId': doc.id,
          'districtId': districtId,
          'bodyId': bodyId,
        });
      }).toList();

      setState(() {});
    } catch (e) {
      debugPrint('Error loading wards: $e');
    }
  }

  void _showDistrictSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DistrictSelectionModal(
          districts: districts,
          districtBodies: districtBodies,
          selectedDistrictId: selectedDistrictId,
          onDistrictSelected: (districtId) {
            setState(() {
              selectedDistrictId = districtId;
              selectedBodyId = null;
              selectedWard = null;
              bodyWards.clear();
            });
            controller.clearCandidates();
          },
        );
      },
    );
  }

  void _showBodySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaSelectionModal(
          bodies: districtBodies[selectedDistrictId!]!,
          selectedBodyId: selectedBodyId,
          onBodySelected: (bodyId) {
            setState(() {
              selectedBodyId = bodyId;
              selectedWard = null;
              bodyWards.clear();
            });
            _loadWards(selectedDistrictId!, bodyId, context);
            controller.clearCandidates();
          },
        );
      },
    );
  }

  void _showWardSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: bodyWards[selectedBodyId!] ?? [],
          selectedWardId: selectedWard?.wardId,
          onWardSelected: (wardId) {
            final ward = bodyWards[selectedBodyId!]!.firstWhere((w) => w.wardId == wardId);
            setState(() {
              selectedWard = ward;
            });
            if (selectedDistrictId != null && selectedBodyId != null) {
              controller.fetchCandidatesByWard(selectedDistrictId!, selectedBodyId!, wardId);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchCandidates),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<CandidateController>(
        builder: (controller) {
          return Column(
            children: [
              // District, Body and Ward Selection
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
                    // District Selection
                    if (isLoadingDistricts)
                      const Center(child: CircularProgressIndicator())
                    else
                      InkWell(
                        onTap: () => _showDistrictSelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Select District',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_city),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedDistrictId != null
                              ? Text(
                                  districts.firstWhere((d) => d.districtId == selectedDistrictId).name,
                                  style: const TextStyle(fontSize: 16),
                                )
                              : const Text(
                                  'Select District',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Body Selection
                    if (selectedDistrictId != null && districtBodies[selectedDistrictId!] != null && districtBodies[selectedDistrictId!]!.isNotEmpty)
                      InkWell(
                        onTap: () => _showBodySelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Select Area (विभाग)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.business),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedBodyId != null
                              ? Builder(
                                  builder: (context) {
                                    final body = districtBodies[selectedDistrictId!]!.firstWhere(
                                      (b) => b.bodyId == selectedBodyId,
                                      orElse: () => Body(bodyId: '', districtId: '', name: '', type: '', wardCount: 0),
                                    );
                                    return Text(
                                      body.bodyId.isNotEmpty ? '${body.name} (${body.type})' : selectedBodyId!,
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                )
                              : const Text(
                                  'Select Area (विभाग)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              selectedDistrictId == null
                                  ? 'Select district first'
                                  : districtBodies[selectedDistrictId!] == null || districtBodies[selectedDistrictId!]!.isEmpty
                                      ? 'No areas available in this district'
                                      : 'Select Area (विभाग)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Ward Selection
                    if (selectedBodyId != null && bodyWards[selectedBodyId!] != null && bodyWards[selectedBodyId!]!.isNotEmpty)
                      InkWell(
                        onTap: () => _showWardSelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Select Ward (वॉर्ड)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.home),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedWard != null
                              ? Builder(
                                  builder: (context) {
                                    // Format ward display like "वॉर्ड 1 - Ward Name"
                                    final numberMatch = RegExp(r'ward_(\d+)').firstMatch(selectedWard!.wardId.toLowerCase());
                                    final displayText = numberMatch != null
                                        ? 'वॉर्ड ${numberMatch.group(1)} - ${selectedWard!.name}'
                                        : selectedWard!.name;
                                    return Text(
                                      displayText,
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                )
                              : const Text(
                                  'Select Ward (वॉर्ड)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.home, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              selectedBodyId == null
                                  ? 'Select area first'
                                  : bodyWards[selectedBodyId!] == null || bodyWards[selectedBodyId!]!.isEmpty
                                      ? 'No wards available in this area'
                                      : 'Select Ward (वॉर्ड)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
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
                                    if (selectedDistrictId != null && selectedBodyId != null && selectedWard != null) {
                                      controller.fetchCandidatesByWard(
                                        selectedDistrictId!,
                                        selectedBodyId!,
                                        selectedWard!.wardId,
                                      );
                                    }
                                  },
                                  child: Text(AppLocalizations.of(context)!.retry),
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
                                    Text(
                                      AppLocalizations.of(context)!.noCandidatesFound,
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${AppLocalizations.of(context)!.noCandidatesFound} ${selectedWard!.name}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : selectedWard == null
                                ? Center(
                                        child: Text(
                                          AppLocalizations.of(context)!.selectWardToViewCandidates,
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
    // Determine if candidate is premium
    bool isPremiumCandidate = candidate.sponsored || candidate.followersCount > 1000;


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
                    color: isPremiumCandidate ? Colors.blue.shade600 : Colors.grey.shade500,
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
                              backgroundColor: isPremiumCandidate ? Colors.blue.shade600 : Colors.grey.shade500,
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
                          backgroundColor: isPremiumCandidate ? Colors.blue.shade600 : Colors.grey.shade500,
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
                              image: SymbolUtils.getSymbolImageProvider(
                                SymbolUtils.getPartySymbolPath(candidate.party, candidate: candidate)
                              ),
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

                    // Premium/Free Badge
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPremiumCandidate
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPremiumCandidate
                              ? Colors.blue.shade300
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: Text(
                        isPremiumCandidate
                            ? 'Premium'
                            : 'Free',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPremiumCandidate
                              ? Colors.blue.shade700
                              : Color(0xFF374151),
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
