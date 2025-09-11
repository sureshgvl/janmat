import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../../models/candidate_model.dart';
import '../../utils/symbol_utils.dart';
import '../../services/file_upload_service.dart';

class BasicInfoSection extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final String Function(String) getPartySymbolPath;
  final Function(String) onNameChange;
  final Function(String) onCityChange;
  final Function(String) onWardChange;
  final Function(String) onPartyChange;
  final Function(String) onPhotoChange;
  final Function(String, dynamic) onBasicInfoChange;

  const BasicInfoSection({
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
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _wardController;
  late TextEditingController _partyController;
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
    _cityController = TextEditingController(text: data.cityId);
    _wardController = TextEditingController(text: data.wardId);
    _partyController = TextEditingController(text: data.party);
    _ageController = TextEditingController(text: extraInfo?.age?.toString() ?? '');
    _genderController = TextEditingController(text: extraInfo?.gender ?? '');
    _educationController = TextEditingController(text: extraInfo?.education ?? '');
    _addressController = TextEditingController(text: extraInfo?.address ?? '');
  }

  @override
  void didUpdateWidget(BasicInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      final data = widget.editedData ?? widget.candidateData;
      final extraInfo = data.extraInfo;
      _nameController.text = data.name;
      _cityController.text = data.cityId;
      _wardController.text = data.wardId;
      _partyController.text = data.party;
      _ageController.text = extraInfo?.age?.toString() ?? '';
      _genderController.text = extraInfo?.gender ?? '';
      _educationController.text = extraInfo?.education ?? '';
      _addressController.text = extraInfo?.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    _partyController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _educationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    try {
      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Try to crop the image, but have a fallback if cropping fails
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square aspect ratio for profile photo
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Photo',
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
              showCropGrid: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
              rotateClockwiseButtonHidden: false,
              rotateButtonsHidden: false,
            ),
          ],
        );
      } catch (cropError) {
        debugPrint('Cropping failed, using original image: $cropError');
        // If cropping fails, we'll use the original picked file
      }

      // Use cropped file if available, otherwise use original
      final String imagePath = croppedFile?.path ?? pickedFile.path;

      // Upload the image
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
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  void _populateDemoData() {
    _nameController.text = 'राहुल पाटील';
    _ageController.text = '42';
    _genderController.text = 'पुरुष';
    _partyController.text = 'Indian National Congress';
    _educationController.text = 'B.A. Political Science';
    _addressController.text = 'पुणे, महाराष्ट्र';

    // Update the callbacks
    widget.onNameChange('राहुल पाटील');
    widget.onBasicInfoChange('age', 42);
    widget.onBasicInfoChange('gender', 'पुरुष');
    widget.onPartyChange('Indian National Congress');
    widget.onBasicInfoChange('education', 'B.A. Political Science');
    widget.onBasicInfoChange('address', 'पुणे, महाराष्ट्र');
  }

  // Keep the old method for backward compatibility
  Future<void> _uploadPhoto() async {
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
      final photoUrl = await _fileUploadService.uploadProfilePhoto(userId);

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

  @override
  Widget build(BuildContext context) {
    final data = widget.editedData ?? widget.candidateData;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Photo and Name Section
            Row(
              children: [
                // Profile Photo with Camera Overlay
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
                    if (widget.isEditing)
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
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isEditing)
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: widget.onNameChange,
                        )
                      else
                        Text(
                          data.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (data.party.toLowerCase().contains('independent') || data.party.trim().isEmpty)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: const Icon(
                                Icons.label,
                                size: 30,
                                color: Colors.grey,
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: SymbolUtils.getSymbolImageProvider(
                                    SymbolUtils.getPartySymbolPath(data.party, candidate: data)
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.party.toLowerCase().contains('independent') || data.party.trim().isEmpty
                                      ? 'Independent Candidate'
                                      : data.party,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: data.party.toLowerCase().contains('independent') || data.party.trim().isEmpty
                                        ? Colors.grey.shade700
                                        : Colors.blue,
                                    fontWeight: data.party.toLowerCase().contains('independent') || data.party.trim().isEmpty
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (data.symbol != null && data.symbol!.isNotEmpty)
                                  Text(
                                    'Symbol: ${data.symbol}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.isEditing) ...[
              // Age and Gender fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => widget.onBasicInfoChange('age', int.tryParse(value) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _genderController,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => widget.onBasicInfoChange('gender', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Party field
              TextFormField(
                controller: _partyController,
                decoration: const InputDecoration(
                  labelText: 'Party',
                  border: OutlineInputBorder(),
                ),
                onChanged: widget.onPartyChange,
              ),
              const SizedBox(height: 16),
              // Education field
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => widget.onBasicInfoChange('education', value),
              ),
              const SizedBox(height: 16),
              // Address field
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
                    const Text(
                      'Location (Non-editable)',
                      style: TextStyle(
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
                            'City: ${data.cityId}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Ward: ${data.wardId}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Display additional info fields
              if (data.extraInfo != null) ...[
                const SizedBox(height: 16),
                if (data.extraInfo!.age != null || data.extraInfo!.gender != null) ...[
                  Row(
                    children: [
                      if (data.extraInfo!.age != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Age',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${data.extraInfo!.age}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (data.extraInfo!.age != null && data.extraInfo!.gender != null)
                        const SizedBox(width: 16),
                      if (data.extraInfo!.gender != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                data.extraInfo!.gender!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.extraInfo!.education != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Education',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        data.extraInfo!.education!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.extraInfo!.address != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        data.extraInfo!.address!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              // City and Ward
              Row(
                children: [
                  //city
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'City',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          data.cityId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  //ward
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ward',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          data.wardId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}