import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/candidate/widgets/view/manifesto_content_builder.dart';
import 'package:janmat/services/analytics_data_collection_service.dart';

class ManifestoTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;
  final bool
  showVoterInteractions; // New parameter to control voter interactions

  const ManifestoTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
    this.showVoterInteractions =
        true, // Default to true for backward compatibility
  });

  @override
  State<ManifestoTabView> createState() => _ManifestoTabViewState();
}

class _ManifestoTabViewState extends State<ManifestoTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CandidateUserController? _dataController;
  final ScrollController _scrollController = ScrollController();

  // Current user
  String? _currentUserId;


  @override
  void initState() {
    super.initState();
    if (widget.isOwnProfile) {
      _dataController = CandidateUserController.to;
    } else {
      _dataController = null;
    }
// Get current user ID
_currentUserId = FirebaseAuth.instance.currentUser?.uid;

// Track manifesto view (only for other users, not the candidate themselves)
if (!widget.isOwnProfile && widget.candidate.candidateId != null) {
  _trackManifestoView();
}


  }

  // Track manifesto view for analytics
  Future<void> _trackManifestoView() async {
    try {
      await AnalyticsDataCollectionService().trackManifestoInteraction(
        candidateId: widget.candidate.candidateId!,
        interactionType: 'view',
        userId: _currentUserId,
        section: 'full_manifesto',
        metadata: {
          'viewedFrom': 'manifesto_tab',
          'hasStructuredData': widget.candidate.manifestoData?.promises?.isNotEmpty ?? false,
        },
      );
    } catch (e) {
      // Analytics tracking should not interrupt user experience
      // Silently fail
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Use reactive data for own profile, static data for others
    if (widget.isOwnProfile && _dataController != null) {
      return Obx(() {
        final candidate =
            _dataController.candidateData.value ?? widget.candidate;
        return _buildContent(candidate);
      });
    } else {
      return _buildContent(widget.candidate);
    }
  }

  Widget _buildContent(Candidate candidate) {
    return ManifestoContentBuilder(
      candidate: candidate,
      currentUserId: _currentUserId,
      showVoterInteractions: widget.showVoterInteractions,
    );
  }
}
