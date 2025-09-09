import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/candidate_model.dart';
import '../../services/file_upload_service.dart';
import 'demo_data_modal.dart';

class ProfileSection extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String) onBioChange;
  final Function(String) onPhotoChange;

  const ProfileSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onBioChange,
    required this.onPhotoChange,
  });

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  late TextEditingController _bioController;
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;
    final bio = data.extraInfo?.bio ?? '';
    _bioController = TextEditingController(text: bio);
  }

  @override
  void didUpdateWidget(ProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      final data = widget.editedData ?? widget.candidateData;
      final bio = data.extraInfo?.bio ?? '';
      _bioController.text = bio;
    }
  }

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
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.editedData ?? widget.candidateData;
    final bio = data.extraInfo?.bio ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.lightbulb,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DemoDataModal(
                          category: 'bio',
                          onDataSelected: (selectedData) {
                            _bioController.text = selectedData;
                            widget.onBioChange(selectedData);
                          },
                        ),
                      );
                    },
                    tooltip: 'Use demo bio',
                  ),
                ),
                maxLines: 3,
                onChanged: widget.onBioChange,
              )
            else
              Text(
                bio.isNotEmpty ? bio : 'No bio available',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 24),

            // Profile Photo Section
            const Text(
              'Profile Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: Stack(
                children: [
                  // Profile Photo Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isUploadingPhoto
                          ? Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : (data.photo != null && data.photo!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: data.photo!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                )),
                    ),
                  ),

                  // Change Photo Button/Overlay
                  if (widget.isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _uploadPhoto,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Photo Status Text
            Center(
              child: Text(
                _isUploadingPhoto
                    ? 'Uploading photo...'
                    : (data.photo != null && data.photo!.isNotEmpty
                        ? 'Tap camera icon to change photo'
                        : 'No profile photo uploaded'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}