import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/candidate_model.dart';
import '../../controllers/candidate_data_controller.dart';
import 'manifesto_content_builder.dart';

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

  late final CandidateDataController? _dataController;
  final ScrollController _scrollController = ScrollController();

  // Current user
  String? _currentUserId;


  @override
  void initState() {
    super.initState();
    if (widget.isOwnProfile) {
      _dataController = Get.find<CandidateDataController>();
    } else {
      _dataController = null;
    }

    // Get current user ID
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

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

