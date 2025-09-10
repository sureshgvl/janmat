import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
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
  InputDecoration _buildInputDecoration(BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    bool showPreFilledHelper = false,
  }) {
    final localizations = AppLocalizations.of(context)!;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
      helperText: showPreFilledHelper ? localizations.autoFilledFromAccount : null,
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
      // For now, keep the error message in English since we don't have context here
      Get.snackbar('Error', 'Failed to load cities: $e');
      setState(() {
        isLoadingCities = false;
      });
    }
  }

  Future<void> _loadWards(String cityId, BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      wards = await candidateRepository.getWardsByCity(cityId);
      setState(() {});
    } catch (e) {
      Get.snackbar(localizations.error, localizations.failedToLoadWards(e.toString()));
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

  Future<void> _saveProfile(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (selectedCity == null || selectedWard == null || selectedGender == null) {
      Get.snackbar(localizations.error, localizations.pleaseFillAllRequiredFields);
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
          localizations.profileCompleted,
          localizations.basicProfileCompletedSetupCandidate,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.offAllNamed('/home');
        Get.snackbar(
          localizations.success,
          localizations.profileCompletedWardChatCreated,
          duration: const Duration(seconds: 4),
        );
      }

    } catch (e) {
      Get.snackbar(localizations.error, localizations.failedToSaveProfile(e.toString()));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.completeYourProfile),
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
                Text(
                  localizations.welcomeCompleteYourProfile,
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
                    String loginMethod = localizations.autoFilledFromAccount;

                    if (currentUser?.providerData.isNotEmpty ?? false) {
                      final provider = currentUser!.providerData.first;
                      if (provider.providerId == 'google.com') {
                        loginMethod = 'Google account';
                      } else if (provider.providerId == 'phone') {
                        loginMethod = 'phone number';
                      }
                    }

                    return Text(
                      localizations.preFilledFromAccount(loginMethod),
                      style: TextStyle(
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
                  decoration: _buildInputDecoration(context,
                    label: localizations.fullNameRequired,
                    hint: localizations.enterYourFullName,
                    icon: Icons.person,
                    showPreFilledHelper: _isNamePreFilled,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.pleaseEnterYourName;
                    }
                    if (value.trim().length < 2) {
                      return localizations.nameMustBeAtLeast2Characters;
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
                  decoration: _buildInputDecoration(context,
                    label: localizations.phoneNumberRequired,
                    hint: localizations.enterYourPhoneNumber,
                    icon: Icons.phone,
                    showPreFilledHelper: _isPhonePreFilled,
                  ).copyWith(
                    prefixText: '+91 ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.pleaseEnterYourPhoneNumber;
                    }
                    if (value.trim().length != 10) {
                      return localizations.phoneNumberMustBe10Digits;
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                      return localizations.pleaseEnterValidPhoneNumber;
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
                  decoration: InputDecoration(
                    labelText: localizations.birthDateRequired,
                    hintText: localizations.selectYourBirthDate,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (value) {
                    if (selectedBirthDate == null) {
                      return localizations.pleaseSelectYourBirthDate;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Gender Selection
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    labelText: localizations.genderRequired,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: [
                    DropdownMenuItem(value: 'male', child: Text(localizations.male)),
                    DropdownMenuItem(value: 'female', child: Text(localizations.female)),
                    DropdownMenuItem(value: 'other', child: Text(localizations.other)),
                    DropdownMenuItem(value: 'prefer_not_to_say', child: Text(localizations.preferNotToSay)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return localizations.pleaseSelectYourGender;
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
                    title: localizations.selectCity,
                    label: localizations.cityRequired,
                    hint: localizations.selectYourCity,
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
                        _loadWards(city.cityId, context);
                      }
                    },
                  ),
                const SizedBox(height: 24),

                // Ward Selection
                ModalSelector<Ward>(
                  title: localizations.selectWard,
                  label: localizations.wardRequired,
                  hint: selectedCity != null ? localizations.selectYourWard : localizations.selectCityFirst,
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
                    onPressed: isLoading ? null : () => _saveProfile(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            localizations.completeProfile,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Text
                Text(
                  localizations.requiredFields,
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