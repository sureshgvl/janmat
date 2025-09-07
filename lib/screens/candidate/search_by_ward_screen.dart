import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/ward_model.dart';
import '../../models/candidate_model.dart';
import '../../widgets/ward_tile.dart';

class SearchByWardScreen extends StatefulWidget {
  const SearchByWardScreen({super.key});

  @override
  State<SearchByWardScreen> createState() => _SearchByWardScreenState();
}

class _SearchByWardScreenState extends State<SearchByWardScreen> {
  Ward? selectedWard;
  List<Candidate> candidates = [];
  bool isLoading = false;

  // Mock data for demonstration
  final List<Ward> wards = [
    Ward(wardId: 'pune-ward-42', cityId: 'pune', name: 'Ward 42', areas: ['Undri', 'Ambegaon Khurd'], seats: 4),
    Ward(wardId: 'pune-ward-43', cityId: 'pune', name: 'Ward 43', areas: ['Kothrud', 'Karve Nagar'], seats: 3),
    Ward(wardId: 'mumbai-ward-1', cityId: 'mumbai', name: 'Ward 1', areas: ['Colaba', 'Fort'], seats: 5),
  ];

  final List<Candidate> mockCandidates = [
    Candidate(
      candidateId: '1',
      name: 'Suresh Jadhav',
      party: 'NCP',
      symbol: 'url-to-party-symbol.png',
      cityId: 'pune',
      wardId: 'pune-ward-42',
      manifesto: 'Better roads, clean water',
      photo: 'url-to-photo.png',
      contact: Contact(phone: '9876543210', email: 'suresh@gmail.com', socialLinks: {'facebook': 'fb.com/suresh', 'twitter': 'twitter.com/suresh'}),
      sponsored: true,
      createdAt: DateTime.now(),
    ),
    Candidate(
      candidateId: '2',
      name: 'Rajesh Kumar',
      party: 'BJP',
      symbol: 'url-to-bjp-symbol.png',
      cityId: 'pune',
      wardId: 'pune-ward-42',
      manifesto: 'Education and healthcare focus',
      photo: 'url-to-rajesh-photo.png',
      contact: Contact(phone: '9123456789', email: 'rajesh@gmail.com'),
      sponsored: false,
      createdAt: DateTime.now(),
    ),
    Candidate(
      candidateId: '3',
      name: 'Priya Sharma',
      party: 'Congress',
      symbol: 'url-to-congress-symbol.png',
      cityId: 'pune',
      wardId: 'pune-ward-43',
      manifesto: 'Women empowerment and safety',
      photo: 'url-to-priya-photo.png',
      contact: Contact(phone: '8765432109', email: 'priya@gmail.com'),
      sponsored: true,
      createdAt: DateTime.now(),
    ),
  ];

  void _selectWard(Ward ward) {
    setState(() {
      selectedWard = ward;
      _searchCandidatesByWard(ward.wardId);
    });
  }

  void _searchCandidatesByWard(String wardId) {
    setState(() {
      isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        candidates = mockCandidates.where((candidate) => candidate.wardId == wardId).toList();
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Candidates by Ward'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Ward Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Ward',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 0,
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: wards.length,
                      itemBuilder: (context, index) {
                        final ward = wards[index];
                        return WardTile(
                          ward: ward,
                          onTap: () => _selectWard(ward),
                          isSelected: selectedWard?.wardId == ward.wardId,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Candidates List Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedWard != null
                        ? 'Candidates in ${selectedWard!.name}'
                        : 'Select a ward to view candidates',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : candidates.isEmpty && selectedWard != null
                            ? const Center(child: Text('No candidates found in this ward'))
                            : ListView.builder(
                                itemCount: candidates.length,
                                itemBuilder: (context, index) {
                                  final candidate = candidates[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          candidate.name[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(candidate.name),
                                      subtitle: Text('${candidate.party}${candidate.sponsored ? ' (Sponsored)' : ''}'),
                                      trailing: Text(candidate.contact.phone),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}