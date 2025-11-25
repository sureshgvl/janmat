import 'package:get/get.dart';
import '../models/candidate_model.dart';

class CandidateSelectionController extends GetxController {
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedCandidateIds = <String>{}.obs;
  final RxList<Candidate> selectedCandidates = <Candidate>[].obs;

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      clearSelection();
    }
  }

  void toggleCandidateSelection(Candidate candidate) {
    if (selectedCandidateIds.contains(candidate.candidateId)) {
      selectedCandidateIds.remove(candidate.candidateId);
      selectedCandidates.removeWhere((c) => c.candidateId == candidate.candidateId);
    } else {
      selectedCandidateIds.add(candidate.candidateId);
      selectedCandidates.add(candidate);
    }
  }

  bool isCandidateSelected(String candidateId) {
    return selectedCandidateIds.contains(candidateId);
  }

  void clearSelection() {
    selectedCandidateIds.clear();
    selectedCandidates.clear();
  }

  bool get canCompare => selectedCandidates.length >= 2;

  void startComparison() {
    if (canCompare) {
      Get.toNamed('/candidate-comparison', arguments: selectedCandidates.toList());
      // Don't clear selection immediately, let user go back
    }
  }

  @override
  void onClose() {
    clearSelection();
    isSelectionMode.value = false;
    super.onClose();
  }
}