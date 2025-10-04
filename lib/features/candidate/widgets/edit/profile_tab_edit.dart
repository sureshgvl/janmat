import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../demo_data_modal.dart';
import '../../../../l10n/app_localizations.dart';

// Main ProfileTabEdit Widget
class ProfileTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String) onBioChange;

  const ProfileTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onBioChange,
  });

  @override
  State<ProfileTabEdit> createState() => ProfileTabEditState();
}

class ProfileTabEditState extends State<ProfileTabEdit> {
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;
    final bio = data.extraInfo?.bio ?? '';
    _bioController = TextEditingController(text: bio);
  }

  @override
  void didUpdateWidget(ProfileTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      final data = widget.editedData ?? widget.candidateData;
      final bio = data.extraInfo?.bio ?? '';
      _bioController.text = bio;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  // Method to upload pending files (required by dashboard pattern)
  Future<void> uploadPendingFiles() async {
    // Profile doesn't have file uploads, so this is a no-op
    debugPrint('📤 [Profile] No pending files to upload');
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
            Text(
              AppLocalizations.of(context)!.profileDetails,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              SizedBox(
                height: 120, // Fixed height for bio input
                child: TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.bio,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.lightbulb, color: Colors.amber),
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
                      tooltip: AppLocalizations.of(context)!.useDemoBio,
                    ),
                  ),
                  maxLines: 3,
                  onChanged: widget.onBioChange,
                ),
              )
            else
              Text(
                bio.isNotEmpty ? bio : AppLocalizations.of(context)!.noBioAvailable,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}

