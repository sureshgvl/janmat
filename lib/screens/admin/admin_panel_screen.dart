import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_controller.dart';
import '../../models/candidate_model.dart';
import '../../models/city_model.dart';
import '../../models/ward_model.dart';
import '../../common/loading_overlay.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final CandidateController _candidateController = Get.find<CandidateController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _candidateController.fetchAllCities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
            Tab(text: 'Finalized'),
          ],
        ),
      ),
      body: Obx(() {
        return LoadingOverlay(
          isLoading: _candidateController.isLoading,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingApprovalTab(),
              _buildApprovedTab(),
              _buildRejectedTab(),
              _buildFinalizedTab(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPendingApprovalTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _candidateController.getPendingApprovalCandidates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final pendingCandidates = snapshot.data ?? [];

        if (pendingCandidates.isEmpty) {
          return const Center(
            child: Text('No pending candidates for approval'),
          );
        }

        return ListView.builder(
          itemCount: pendingCandidates.length,
          itemBuilder: (context, index) {
            final candidateData = pendingCandidates[index];
            final candidate = Candidate.fromJson(candidateData);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: candidate.photo != null
                      ? NetworkImage(candidate.photo!)
                      : null,
                  child: candidate.photo == null
                      ? Text(candidate.name[0].toUpperCase())
                      : null,
                ),
                title: Text(candidate.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Party: ${candidate.party}'),
                    Text('Ward: ${candidateData['wardId']}'),
                    Text('City: ${candidateData['cityId']}'),
                    const Text(
                      'Status: Self-declared (Pending Approval)',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveCandidate(
                        candidateData['cityId'],
                        candidateData['wardId'],
                        candidate.candidateId,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectCandidate(
                        candidateData['cityId'],
                        candidateData['wardId'],
                        candidate.candidateId,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showCandidateDetails(candidate),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApprovedTab() {
    return _buildCandidatesListByStatus('pending_election', 'Approved Candidates');
  }

  Widget _buildRejectedTab() {
    return _buildCandidatesListByStatus('rejected', 'Rejected Candidates');
  }

  Widget _buildFinalizedTab() {
    return _buildCandidatesListByStatus('finalized', 'Finalized Candidates');
  }

  Widget _buildCandidatesListByStatus(String status, String title) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: _candidateController.candidates.isEmpty
              ? Center(child: Text('No $status candidates'))
              : ListView.builder(
                  itemCount: _candidateController.candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = _candidateController.candidates[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: candidate.photo != null
                              ? NetworkImage(candidate.photo!)
                              : null,
                          child: candidate.photo == null
                              ? Text(candidate.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(candidate.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Party: ${candidate.party}'),
                            Text('Status: ${candidate.status ?? 'Unknown'}'),
                            Text('Followers: ${candidate.followersCount}'),
                          ],
                        ),
                        trailing: status == 'pending_election'
                            ? ElevatedButton(
                                onPressed: () => _showFinalizeDialog(candidate),
                                child: const Text('Finalize'),
                              )
                            : null,
                        onTap: () => _showCandidateDetails(candidate),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _approveCandidate(String cityId, String wardId, String candidateId) async {
    await _candidateController.updateCandidateApproval(cityId, wardId, candidateId, true);
    setState(() {}); // Refresh the UI
    Get.snackbar('Success', 'Candidate approved successfully');
  }

  void _rejectCandidate(String cityId, String wardId, String candidateId) async {
    await _candidateController.updateCandidateApproval(cityId, wardId, candidateId, false);
    setState(() {}); // Refresh the UI
    Get.snackbar('Success', 'Candidate rejected');
  }

  void _showFinalizeDialog(Candidate candidate) {
    Get.dialog(
      AlertDialog(
        title: const Text('Finalize Candidate'),
        content: Text('Are you sure you want to finalize ${candidate.name}? This will mark them as an official election candidate.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _candidateController.finalizeCandidates(
                candidate.cityId,
                candidate.wardId,
                [candidate.candidateId],
              );
              Get.snackbar('Success', 'Candidate finalized successfully');
            },
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
  }

  void _showCandidateDetails(Candidate candidate) {
    Get.dialog(
      AlertDialog(
        title: Text(candidate.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Party: ${candidate.party}'),
              if (candidate.symbol != null) Text('Symbol: ${candidate.symbol}'),
              Text('Phone: ${candidate.contact.phone}'),
              if (candidate.contact.email != null) Text('Email: ${candidate.contact.email}'),
              if (candidate.manifesto != null) Text('Manifesto: ${candidate.manifesto}'),
              Text('Sponsored: ${candidate.sponsored ? 'Yes' : 'No'}'),
              Text('Premium: ${candidate.premium ? 'Yes' : 'No'}'),
              Text('Followers: ${candidate.followersCount}'),
              Text('Status: ${candidate.status ?? 'Unknown'}'),
              Text('Approved: ${candidate.approved ?? false ? 'Yes' : 'No'}'),
              Text('Created: ${candidate.createdAt.toString().split(' ')[0]}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}