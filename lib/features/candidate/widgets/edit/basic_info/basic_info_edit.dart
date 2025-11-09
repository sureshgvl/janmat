import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../../../../utils/snackbar_utils.dart';
import '../../../models/candidate_model.dart';
import '../../../controllers/candidate_user_controller.dart';
import 'photo_upload_handler.dart';
import 'date_picker_handler.dart';
import 'gender_selector.dart';
import 'form_field_builder.dart';
import 'demo_data_populator.dart';
import '../../../../../../l10n/features/candidate/candidate_localizations.dart';

/// BasicInfoEdit - Handles editing of candidate basic information
/// Follows Single Responsibility Principle: Only responsible for editing logic
class BasicInfoEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final String Function(String) getPartySymbolPath;
  final Function(String) onNameChange;
  final Function(String) onCityChange;
  final Function(String) onWardChange;
  final Function(String) onPhotoChange;
  final Function(String) onPartyChange;
  final Function(String, dynamic) onBasicInfoChange;

  const BasicInfoEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.getPartySymbolPath,
    required this.onNameChange,
    required this.onCityChange,
    required this.onWardChange,
    required this.onPhotoChange,
    required this.onPartyChange,
    required this.onBasicInfoChange,
  });

  @override
  State<BasicInfoEdit> createState() => _BasicInfoEditState();
}

class _BasicInfoEditState extends State<BasicInfoEdit> {
  // Handler instances
  final PhotoUploadHandler _photoHandler = PhotoUploadHandler();
  final DatePickerHandler _dateHandler = DatePickerHandler();
  final GenderSelector _genderSelector = GenderSelector();

  // Access controller directly for reactive photo updates
  final CandidateUserController _controller = Get.find<CandidateUserController>();

  bool _isUploadingPhoto = false;
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _wardController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _educationController;
  late TextEditingController _addressController;
  late TextEditingController _professionController;
  late TextEditingController _languagesController;
  late TextEditingController _symbolNameController;

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;

    AppLogger.candidate('🎯 BasicInfoEdit initState - Education debug:');
    AppLogger.candidate('   basicInfo exists: ${data.basicInfo != null}');
    AppLogger.candidate(
      '   education from basicInfo: ${data.basicInfo?.education}',
    );
    AppLogger.candidate('   address from contact: ${data.contact.address}');

    _nameController = TextEditingController(
      text: data.basicInfo?.fullName ?? '',
    );
    _cityController = TextEditingController(text: data.location.districtId);
    _wardController = TextEditingController(text: data.location.wardId);
    _ageController = TextEditingController(
      text: data.basicInfo?.age?.toString() ?? '',
    );
    _genderController = TextEditingController(
      text: data.basicInfo?.gender ?? '',
    );
    _educationController = TextEditingController(
      text: data.basicInfo?.education ?? '',
    );
    _addressController = TextEditingController(
      text: data.contact.address ?? '',
    );
    _professionController = TextEditingController(
      text: data.basicInfo?.profession ?? '',
    );
    _languagesController = TextEditingController(
      text: data.basicInfo?.languages?.join(', ') ?? '',
    );
    _symbolNameController = TextEditingController(text: data.symbolName ?? '');

    // Debug log initial state of all input boxes
    AppLogger.candidate(
      '🎬 BasicInfoEdit initState - Initial controller values:',
    );
    AppLogger.candidate('   👤 Name: "${_nameController.text}"');
    AppLogger.candidate('   🎂 Age: "${_ageController.text}"');
    AppLogger.candidate('   👥 Gender: "${_genderController.text}"');
    AppLogger.candidate('   🎓 Education: "${_educationController.text}"');
    AppLogger.candidate('   💼 Profession: "${_professionController.text}"');
    AppLogger.candidate('   🌐 Languages: "${_languagesController.text}"');
    AppLogger.candidate('   📍 Address: "${_addressController.text}"');
    AppLogger.candidate('   🏛️ City: "${_cityController.text}"');
    AppLogger.candidate('   🏘️ Ward: "${_wardController.text}"');
    AppLogger.candidate('   🎯 Symbol Name: "${_symbolNameController.text}"');
  }

  @override
  void didUpdateWidget(BasicInfoEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    AppLogger.candidate('🔄 BasicInfoEdit didUpdateWidget called - old photo: ${oldWidget.editedData?.basicInfo?.photo}, new photo: ${widget.editedData?.basicInfo?.photo}');
    // Update controller text when external data changes (e.g., after data loads)
    if (widget.editedData != oldWidget.editedData) {
      final data = widget.editedData ?? widget.candidateData;
      // Only update if the data actually changed and basicInfo has fullName
      if (data.basicInfo?.fullName != null &&
          data.basicInfo!.fullName!.isNotEmpty) {
        _nameController.text = data.basicInfo!.fullName!;
        AppLogger.candidate(
          '🔄 Updated name controller with basicInfo.fullName: ${data.basicInfo!.fullName}',
        );
      }
    }
  }

  Future<void> _pickAndStoreImageLocally() async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final imagePath = await _photoHandler.pickAndCropImage(context);
      if (imagePath != null) {
        // Store local image path instead of uploading
        // We'll use a special identifier to indicate this is a local path pending upload
        final localPhotoIdentifier = 'local:$imagePath';
        widget.onPhotoChange(localPhotoIdentifier);
        AppLogger.candidate('📸 Photo selected locally: $imagePath');
      }
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final picked = await _dateHandler.selectBirthDate(context);
    if (picked != null) {
      final age = _dateHandler.calculateAge(picked);
      _ageController.text = age.toString();
      widget.onBasicInfoChange('age', age);
      widget.onBasicInfoChange('date_of_birth', picked.toIso8601String());
    }
  }

  Future<void> _selectGender(BuildContext context) async {
    final result = await _genderSelector.selectGender(context);
    if (result != null) {
      _genderController.text = result;
      widget.onBasicInfoChange('gender', result);
    }
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String labelText,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return CustomFormFieldBuilder.buildTextInputField(
      controller: controller,
      labelText: labelText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  void _populateDemoData() {
    final demoData = DemoDataPopulator.getDemoData();

    // Update controllers
    _nameController.text = demoData['name'] as String;
    _ageController.text = demoData['age'].toString();
    _genderController.text = demoData['gender'] as String;
    _educationController.text = demoData['education'] as String;
    _professionController.text = demoData['profession'] as String;
    _languagesController.text = (demoData['languages'] as List<String>).join(
      ', ',
    );
    _symbolNameController.text = demoData['symbolName'] as String;
    _addressController.text = demoData['address'] as String;

    // Update callbacks
    demoData.forEach((key, value) {
      if (key == 'name') {
        widget.onNameChange(value as String);
      } else {
        widget.onBasicInfoChange(key, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Use controller's reactive data directly instead of widget parameters
      final data = _controller.editedData.value ?? _controller.candidateData.value!;

      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CandidateLocalizations.of(context)!.personalInformation,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Photo and Name Section
              Builder(
                builder: (context) {
                  final photoValue = data.basicInfo!.photo;
                  final isLocalPhoto = photoValue != null && photoValue.startsWith('local:');
                  AppLogger.candidate(
                    '🎨 BasicInfoEdit displaying photo - value: "$photoValue", isLocal: $isLocalPhoto',
                    tag: 'PHOTO_DEBUG'
                  );
                  if (isLocalPhoto) {
                    final localPath = photoValue.substring(6);
                    AppLogger.candidate('📁 Local file path: $localPath', tag: 'PHOTO_DEBUG');
                  }

                  return Row(
                    children: [
                      // Profile Photo with Camera Overlay
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: photoValue != null
                                ? (isLocalPhoto
                                    ? FileImage(File(photoValue.substring(6))) // Remove 'local:' prefix
                                    : NetworkImage(photoValue))
                                : null,
                            child: photoValue == null
                                ? Text(
                                    data.basicInfo?.fullName?.isNotEmpty == true
                                        ? data.basicInfo!.fullName![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 24),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto ? null : _pickAndStoreImageLocally,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isUploadingPhoto
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: CandidateLocalizations.of(context)!.fullName,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: widget.onNameChange,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Age field
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        TextFormField(
                          controller: _ageController,
                          decoration: InputDecoration(
                            labelText: CandidateLocalizations.of(context)!.age,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => widget.onBasicInfoChange(
                            'age',
                            int.tryParse(value) ?? 0,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 12,
                          child: GestureDetector(
                            onTap: () => _selectBirthDate(context),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectGender(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    CandidateLocalizations.of(context)!.gender,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _genderController.text.isNotEmpty
                                        ? _genderController.text
                                        : CandidateLocalizations.of(
                                            context,
                                          )!.tapToSelectGender,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _genderController.text.isNotEmpty
                                          ? Colors.black
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Education field
              _buildTextInputField(
                controller: _educationController,
                labelText: CandidateLocalizations.of(context)!.education,
                onChanged: (value) {
                  AppLogger.candidate(
                    '🎯 Education changed to: "$value"',
                    tag: 'FORM_EDIT',
                  );
                  widget.onBasicInfoChange('education', value);
                },
              ),
              const SizedBox(height: 16),

              // Profession field
              TextFormField(
                controller: _professionController,
                decoration: InputDecoration(
                  labelText: CandidateLocalizations.of(context)!.profession,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  AppLogger.candidate('🎯 Profession changed: $value');
                  AppLogger.candidate(
                    '   📝 Profession controller text: "${_professionController.text}"',
                  );
                  widget.onBasicInfoChange('profession', value);
                },
              ),
              const SizedBox(height: 16),

              // Languages field
              TextFormField(
                controller: _languagesController,
                decoration: InputDecoration(
                  labelText: CandidateLocalizations.of(
                    context,
                  )!.languagesCommaSeparated,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  AppLogger.candidate('🎯 Languages changed: $value');
                  AppLogger.candidate(
                    '   📝 Languages controller text: "${_languagesController.text}"',
                  );
                  widget.onBasicInfoChange(
                    'languages',
                    value.split(',').map((e) => e.trim()).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Symbol Name field (only for independent candidates)
              if (data.party.toLowerCase().contains('independent') ||
                  data.party.trim().isEmpty) ...[
                const SizedBox(height: 16),
                _buildTextInputField(
                  controller: _symbolNameController,
                  labelText: CandidateLocalizations.of(
                    context,
                  )!.symbolNameForIndependent,
                  onChanged: (value) {
                    AppLogger.candidate('🎯 Symbol Name changed: $value');
                    widget.onBasicInfoChange('symbolName', value);
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Address field
              _buildTextInputField(
                controller: _addressController,
                labelText: CandidateLocalizations.of(context)!.address,
                maxLines: 2,
                onChanged: (value) => widget.onBasicInfoChange('address', value),
              ),

              const SizedBox(height: 16),

              // Demo Data Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _populateDemoData,
                  icon: const Icon(Icons.lightbulb),
                  label: Text(CandidateLocalizations.of(context)!.useDemoData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // City and Ward fields (non-editable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.locationNonEditable,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            CandidateLocalizations.of(context)!.districtLabel(
                              district: data.location.districtId ?? '',
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            CandidateLocalizations.of(
                              context,
                            )!.wardLabel(ward: data.location.wardId ?? ''),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
