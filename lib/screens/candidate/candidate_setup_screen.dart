import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/candidate_model.dart';
import '../../repositories/candidate_repository.dart';
import '../../controllers/chat_controller.dart';

class CandidateSetupScreen extends StatefulWidget {
  const CandidateSetupScreen({super.key});

  @override
  State<CandidateSetupScreen> createState() => _CandidateSetupScreenState();
}

class _CandidateSetupScreenState extends State<CandidateSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final candidateRepository = CandidateRepository();
  final chatController = Get.find<ChatController>();

  // Form controllers
  final nameController = TextEditingController();
  final partyController = TextEditingController();
  final manifestoController = TextEditingController();

  String? selectedParty;
  bool isLoading = false;

  final List<String> parties = [
    'Indian National Congress',
    'Bharatiya Janata Party',
    'Nationalist Congress Party (Ajit Pawar faction)',
    'Nationalist Congress Party – Sharadchandra Pawar',
    'Shiv Sena (Eknath Shinde faction)',
    'Shiv Sena (Uddhav Balasaheb Thackeray – UBT)',
    'Maharashtra Navnirman Sena',
    'Communist Party of India',
    'Communist Party of India (Marxist)',
    'Bahujan Samaj Party',
    'Samajwadi Party',
    'All India Majlis-e-Ittehad-ul-Muslimeen',
    'National Peoples Party',
    'Peasants and Workers Party of India',
    'Vanchit Bahujan Aaghadi',
    'Rashtriya Samaj Paksha',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      nameController.text = currentUser.displayName ?? '';
    }
  }

  Future<void> _createCandidateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedParty == null) {
      Get.snackbar('Error', 'Please select your party');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data for city/ward info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;
      final cityId = userData['cityId'] ?? '';
      final wardId = userData['wardId'] ?? '';

      // Create candidate
      final candidate = Candidate(
        candidateId: 'candidate_${currentUser.uid}',
        userId: currentUser.uid,
        name: nameController.text.trim(),
        party: selectedParty!,
        cityId: cityId,
        wardId: wardId,
        contact: Contact(
          phone: userData['phone'] ?? '',
          email: userData['email'],
        ),
        sponsored: false,
        premium: false,
        createdAt: DateTime.now(),
        manifesto: manifestoController.text.trim().isNotEmpty
            ? manifestoController.text.trim()
            : null,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('candidates')
          .doc(candidate.candidateId)
          .set(candidate.toJson());

      // Update user role to candidate
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'role': 'candidate',
            'candidateId': candidate.candidateId,
          });

      // Refresh user data
      await chatController.refreshUserDataAndChat();

      Get.snackbar(
        'Success!',
        'Your candidate profile has been created successfully!',
        duration: const Duration(seconds: 3),
      );

      // Navigate to candidate dashboard
      Get.offAllNamed('/home');

    } catch (e) {
      Get.snackbar('Error', 'Failed to create candidate profile: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    partyController.dispose();
    manifestoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Candidate Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Complete Your Candidate Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in your details to create your candidate profile and start engaging with voters.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name as it appears on ballot',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Party Selection
                DropdownButtonFormField<String>(
                  value: selectedParty,
                  decoration: const InputDecoration(
                    labelText: 'Political Party *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: parties.map((party) {
                    return DropdownMenuItem<String>(
                      value: party,
                      child: Text(party),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedParty = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your political party';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Manifesto Field
                TextFormField(
                  controller: manifestoController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Manifesto (Optional)',
                    hintText: 'Briefly describe your key promises and vision for the community',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    // Manifesto is optional, so no validation needed
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Your profile will be created and visible to voters\n'
                        '• You can access the Candidate Dashboard to manage your campaign\n'
                        '• Premium features will be available for enhanced visibility\n'
                        '• You can update your manifesto, contact info, and media anytime',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _createCandidateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Candidate Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to Role Selection
                Center(
                  child: TextButton(
                    onPressed: () {
                      Get.offAllNamed('/role-selection');
                    },
                    child: const Text('Change Role Selection'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}