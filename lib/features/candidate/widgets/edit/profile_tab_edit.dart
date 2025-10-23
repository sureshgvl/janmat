import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../demo_data_modal.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_logger.dart';

// Main ProfileTabEdit Widget
class ProfileTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;

  const ProfileTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
  });

  @override
  State<ProfileTabEdit> createState() => ProfileTabEditState();
}

class ProfileTabEditState extends State<ProfileTabEdit> {
  // Bio field removed from model - no longer needed

  // Method to upload pending files (required by dashboard pattern)
  Future<void> uploadPendingFiles() async {
    // Profile doesn't have file uploads, so this is a no-op
    AppLogger.candidate('📤 [Profile] No pending files to upload');
  }

  @override
  Widget build(BuildContext context) {
    // Bio field removed from model - showing empty profile details
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
            Text(
              'Profile details section - bio field removed from model',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

