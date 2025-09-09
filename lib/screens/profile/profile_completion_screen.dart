import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/login_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/user_model.dart';
import '../../models/city_model.dart';
import '../../models/ward_model.dart';
import '../../models/candidate_model.dart';
import '../../repositories/candidate_repository.dart';
import '../../widgets/modal_selector.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final loginController = Get.find<LoginController>();
  final chatController = Get.find<ChatController>();
  final candidateRepository = CandidateRepository();

  // Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? selectedBirthDate;
  String? selectedGender;
  City? selectedCity;
  Ward? selectedWard;

  List<City> cities = [];
  List<Ward> wards = [];
  bool isLoading = false;
  bool isLoadingCities = true;
  bool _isNamePreFilled = false;
  bool _isPhonePreFilled = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _preFillUserData();
  }


  // Pre-fill user data from Firebase Auth
  void _preFillUserData() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Pre-fill name from display name (Google login) or email prefix
    if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
      nameController.text = currentUser.displayName!;
      _isNamePreFilled = true;
    } else if (currentUser.email != null && currentUser.email!.isNotEmpty) {
      // Extract name from email (before @)
      final emailPrefix = currentUser.email!.split('@').first;
      // Capitalize first letter of each word
      final nameParts = emailPrefix.split('.');
      final formattedName = nameParts.map((part) {
        if (part.isNotEmpty) {
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        }
        return part;
      }).join(' ');
      nameController.text = formattedName;
      _isNamePreFilled = true;
    }

    // Pre-fill phone number from Firebase Auth (remove +91 prefix for display)
    if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
      phoneController.text = currentUser.phoneNumber!.replaceFirst('+91', '');
      _isPhonePreFilled = true;
    }

  debugPrint('🔍 Pre-filled user data:');
  debugPrint('  Name: ${nameController.text} (${_isNamePreFilled ? 'from auth' : 'manual'})');
  debugPrint('  Phone: ${phoneController.text} (${_isPhonePreFilled ? 'from auth' : 'manual'})');
  debugPrint('  Email: ${currentUser.email}');
  debugPrint('  Photo: ${currentUser.photoURL}');

    // Trigger rebuild to show helper text
    setState(() {});
  }

  // Build input decoration with dynamic helper text
  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool showPreFilledHelper = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
      helperText: showPreFilledHelper ? 'Auto-filled from your account' : null,
      helperStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 12,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      cities = await candidateRepository.getAllCities();
      setState(() {
        isLoadingCities = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load cities: $e');
      setState(() {
        isLoadingCities = false;
      });
    }
  }

  Future<void> _loadWards(String cityId) async {
    try {
      wards = await candidateRepository.getWardsByCity(cityId);
      setState(() {});
    } catch (e) {
      Get.snackbar('Error', 'Failed to load wards: $e');
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // 13 years ago (minimum age)
    );

    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
        birthDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCity == null || selectedWard == null || selectedGender == null) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current user role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentRole = userDoc.data()?['role'] ?? 'voter';

      // Create updated user model
      final updatedUser = UserModel(
        uid: currentUser.uid,
        name: nameController.text.trim(),
        phone: '+91${phoneController.text.trim()}',
        email: currentUser.email,
        role: currentRole,
        roleSelected: true,
        profileCompleted: true,
        wardId: selectedWard!.wardId,
        cityId: selectedCity!.cityId,
        xpPoints: 0,
        premium: false,
        createdAt: DateTime.now(),
        photoURL: currentUser.photoURL,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            ...updatedUser.toJson(),
            'birthDate': selectedBirthDate?.toIso8601String(),
            'gender': selectedGender,
            'profileCompleted': true,
          });

      // Refresh chat controller with new user data and create ward room
      try {
        await chatController.refreshUserDataAndChat();
      debugPrint('✅ Ward chat room created successfully for user: ${currentUser.uid}');
      } catch (e) {
      debugPrint('⚠️ Failed to create ward room, but profile saved: $e');
        // Don't fail the entire process if room creation fails
      }

      // If user is a candidate, create basic candidate record immediately
      if (currentRole == 'candidate') {
        try {
          // Create basic candidate record
          final candidate = Candidate(
            candidateId: 'temp_${currentUser.uid}', // Temporary ID, will be updated in candidate setup
            userId: currentUser.uid,
            name: nameController.text.trim(),
            party: 'Independent', // Default party, will be updated in candidate setup
            cityId: selectedCity!.cityId,
            wardId: selectedWard!.wardId,
            contact: Contact(
              phone: '+91${phoneController.text.trim()}',
              email: currentUser.email,
            ),
            sponsored: false,
            premium: false,
            createdAt: DateTime.now(),
            manifesto: null, // Will be updated in candidate setup
          );

          // Save basic candidate record to make them visible to voters
        debugPrint('🏗️ Profile Completion: Creating candidate record for ${candidate.name}');
        debugPrint('   City: ${candidate.cityId}, Ward: ${candidate.wardId}');
        debugPrint('   Temp ID: ${candidate.candidateId}');
          final actualCandidateId = await candidateRepository.createCandidate(candidate);
        debugPrint('✅ Basic candidate record created with ID: $actualCandidateId');

          // Update user document with the actual candidateId
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
                'candidateId': actualCandidateId,
              });
        debugPrint('✅ User document updated with candidateId: $actualCandidateId');

        } catch (e) {
        debugPrint('⚠️ Failed to create basic candidate record: $e');
          // Continue with navigation even if candidate creation fails
        }
      }

      // Navigate based on role
      if (currentRole == 'candidate') {
        Get.offAllNamed('/candidate-setup');
        Get.snackbar(
          'Profile Completed!',
          'Basic profile completed. Now set up your candidate profile.',
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.offAllNamed('/home');
        Get.snackbar(
          'Success',
          'Profile completed! Your ward chat room has been created.',
          duration: const Duration(seconds: 4),
        );
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to save profile: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Prevent back button
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
                  'Welcome! Please complete your profile to continue.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    String loginMethod = 'your account';

                    if (currentUser?.providerData.isNotEmpty ?? false) {
                      final provider = currentUser!.providerData.first;
                      if (provider.providerId == 'google.com') {
                        loginMethod = 'Google account';
                      } else if (provider.providerId == 'phone') {
                        loginMethod = 'phone number';
                      }
                    }

                    return Text(
                      'Some information has been pre-filled from $loginMethod. This helps us connect you with your local community.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: nameController,
                  decoration: _buildInputDecoration(
                    label: 'Full Name *',
                    hint: 'Enter your full name',
                    icon: Icons.person,
                    showPreFilledHelper: _isNamePreFilled,
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

                // Phone Field
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _buildInputDecoration(
                    label: 'Phone Number *',
                    hint: 'Enter your phone number',
                    icon: Icons.phone,
                    showPreFilledHelper: _isPhonePreFilled,
                  ).copyWith(
                    prefixText: '+91 ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().length != 10) {
                      return 'Phone number must be 10 digits';
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Birth Date Field
                TextFormField(
                  controller: birthDateController,
                  readOnly: true,
                  onTap: () => _selectBirthDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Birth Date *',
                    hintText: 'Select your birth date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (value) {
                    if (selectedBirthDate == null) {
                      return 'Please select your birth date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Gender Selection
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                    DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // City Selection
                if (isLoadingCities)
                  const Center(child: CircularProgressIndicator())
                else
                  ModalSelector<City>(
                    title: 'Select City',
                    label: 'City *',
                    hint: 'Select your city',
                    items: cities.map((city) {
                      return DropdownMenuItem<City>(
                        value: city,
                        child: Text('${city.name} (${city.state})'),
                      );
                    }).toList(),
                    value: selectedCity,
                    onChanged: (city) {
                      setState(() {
                        selectedCity = city;
                        selectedWard = null;
                        wards = [];
                      });
                      if (city != null) {
                        _loadWards(city.cityId);
                      }
                    },
                  ),
                const SizedBox(height: 24),

                // Ward Selection
                ModalSelector<Ward>(
                  title: 'Select Ward',
                  label: 'Ward *',
                  hint: selectedCity != null ? 'Select your ward' : 'Select city first',
                  items: wards.map((ward) {
                    return DropdownMenuItem<Ward>(
                      value: ward,
                      child: Text('${ward.name} (${ward.areas.length} areas)'),
                    );
                  }).toList(),
                  value: selectedWard,
                  enabled: selectedCity != null,
                  onChanged: (ward) {
                    setState(() {
                      selectedWard = ward;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Complete Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Text
                const Text(
                  '* Required fields',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
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