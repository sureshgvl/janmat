import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../utils/app_logger.dart';
import '../../models/candidate_model.dart';
import '../../../../utils/symbol_utils.dart';
import '../../../../services/file_upload_service.dart';

class BasicInfoTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final String Function(String) getPartySymbolPath;
  final Function(String) onNameChange;
  final Function(String) onCityChange;
  final Function(String) onWardChange;
  final Function(String) onPhotoChange;
  final Function(String) onPartyChange;
  final Function(String, dynamic) onBasicInfoChange;

  const BasicInfoTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.getPartySymbolPath,
    required this.onNameChange,
    required this.onCityChange,
    required this.onWardChange,
    required this.onPartyChange,
    required this.onPhotoChange,
    required this.onBasicInfoChange,
  });

  @override
  State<BasicInfoTabEdit> createState() => _BasicInfoTabEditState();
}

class _BasicInfoTabEditState extends State<BasicInfoTabEdit> {
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _wardController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _educationController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;
    final extraInfo = data.extraInfo;

    _nameController = TextEditingController(text: data.name);
    _cityController = TextEditingController(text: data.districtId);
    _wardController = TextEditingController(text: data.wardId);
    _ageController = TextEditingController(
      text: extraInfo?.basicInfo?.age?.toString() ?? '',
    );
    _genderController = TextEditingController(
      text: extraInfo?.basicInfo?.gender ?? '',
    );
    _educationController = TextEditingController(
      text: extraInfo?.basicInfo?.education ?? '',
    );
    _addressController = TextEditingController(
      text: extraInfo?.contact?.address ?? '',
    );
  }

  @override
  void didUpdateWidget(BasicInfoTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      final data = widget.editedData ?? widget.candidateData;
      final extraInfo = data.extraInfo;
      _nameController.text = data.name;
      _cityController.text = data.districtId;
      _wardController.text = data.wardId;
      _ageController.text = extraInfo?.basicInfo?.age?.toString() ?? '';
      _genderController.text = extraInfo?.basicInfo?.gender ?? '';
      _educationController.text = extraInfo?.basicInfo?.education ?? '';
      _addressController.text = extraInfo?.contact?.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _educationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Photo',
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Photo',
              aspectRatioLockEnabled: true,
            ),
          ],
        );
      } catch (cropError) {
        AppLogger.candidate('Cropping failed, using original image: $cropError');
      }

      final String imagePath = croppedFile?.path ?? pickedFile.path;
      await _uploadCroppedPhoto(imagePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadCroppedPhoto(String imagePath) async {
    final userId = widget.candidateData.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'profile_photos/$fileName';
      final photoUrl = await _fileUploadService.uploadFile(
        imagePath,
        storagePath,
        'image/jpeg',
      );

      if (photoUrl != null) {
        widget.onPhotoChange(photoUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final age = _calculateAge(picked);
      _ageController.text = age.toString();
      widget.onBasicInfoChange('age', age);
      widget.onBasicInfoChange('date_of_birth', picked.toIso8601String());
    }
  }

  Future<void> _selectGender(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Male'),
                onTap: () => Navigator.of(context).pop('Male'),
              ),
              ListTile(
                title: const Text('Female'),
                onTap: () => Navigator.of(context).pop('Female'),
              ),
              ListTile(
                title: const Text('Other'),
                onTap: () => Navigator.of(context).pop('Other'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      _genderController.text = result;
      widget.onBasicInfoChange('gender', result);
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _populateDemoData() {
    _nameController.text = 'राहुल पाटील';
    _ageController.text = '42';
    _genderController.text = 'पुरुष';
    _educationController.text = 'B.A. Political Science';
    _addressController.text = 'पुणे, महाराष्ट्र';

    widget.onNameChange('राहुल पाटील');
    widget.onBasicInfoChange('age', 42);
    widget.onBasicInfoChange('gender', 'पुरुष');
    widget.onBasicInfoChange('date_of_birth', '1982-01-15T00:00:00.000Z');
    widget.onBasicInfoChange('education', 'B.A. Political Science');
    widget.onBasicInfoChange('address', 'पुणे, महाराष्ट्र');
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.editedData ?? widget.candidateData;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),

            // Photo and Name Section
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: data.photo != null
                          ? NetworkImage(data.photo!)
                          : null,
                      child: data.photo == null
                          ? Text(
                              data.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickAndCropImage,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
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
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.onNameChange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Age and Gender
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectBirthDate(context),
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
                                  'Age',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _ageController.text.isNotEmpty
                                      ? _ageController.text
                                      : 'Tap to select birth date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _ageController.text.isNotEmpty
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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
                                  'Gender',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  _genderController.text.isNotEmpty
                                      ? _genderController.text
                                      : 'Tap to select gender',
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

            // Education
            TextFormField(
              controller: _educationController,
              decoration: const InputDecoration(
                labelText: 'Education',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  widget.onBasicInfoChange('education', value),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => widget.onBasicInfoChange('address', value),
            ),
            const SizedBox(height: 16),

            // Party and Location Info (Display only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (data.party.toLowerCase().contains('independent') ||
                          data.party.trim().isEmpty)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: const Icon(
                            Icons.label,
                            size: 20,
                            color: Colors.grey,
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: SymbolUtils.getSymbolImageProvider(
                                SymbolUtils.getPartySymbolPath(
                                  data.party,
                                  candidate: data,
                                ),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.party.toLowerCase().contains(
                                        'independent',
                                      ) ||
                                      data.party.trim().isEmpty
                                  ? 'Independent Candidate'
                                  : data.party,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    data.party.toLowerCase().contains(
                                          'independent',
                                        ) ||
                                        data.party.trim().isEmpty
                                    ? Colors.grey.shade700
                                    : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (data.symbolName != null && data.symbolName!.isNotEmpty)
                              Text(
                                'Symbol: ${data.symbolName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'District: ${data.districtId}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Ward: ${data.wardId}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Demo Data Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _populateDemoData,
                icon: const Icon(Icons.lightbulb),
                label: const Text('Use Demo Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

