import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../common/file_upload_tile.dart';
import '../../../controllers/upload_controller.dart';
import '../../../models/candidate_model.dart';
import '../../../../monetization/services/plan_service.dart';
import '../../../../common/upgrade_plan_dialog.dart';

/// Clean manifesto file section using the new architecture
/// Compatible with existing manifesto_edit.dart interface
class ManifestoFileSection extends StatelessWidget {
  final Candidate candidate;
  final String? existingPdfUrl;
  final String? existingImageUrl;
  final String? existingVideoUrl;
  final Function(String)? onPdfUrlChange;
  final Function(String)? onImageUrlChange;
  final Function(String)? onVideoUrlChange;

  const ManifestoFileSection({
    super.key,
    required this.candidate,
    this.existingPdfUrl,
    this.existingImageUrl,
    this.existingVideoUrl,
    this.onPdfUrlChange,
    this.onImageUrlChange,
    this.onVideoUrlChange,
  });

  /// Check if user can upload images (premium feature)
  Future<bool> _canUploadImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final plan = await PlanService.getUserPlan(currentUser.uid);
    return plan != null && plan.dashboardTabs?.manifesto.enabled == true;
  }

  /// Check if user can upload videos (premium feature)
  Future<bool> _canUploadVideo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final plan = await PlanService.getUserPlan(currentUser.uid);
    if (plan == null || plan.dashboardTabs?.manifesto.enabled != true) return false;

    // Check specific video upload permission
    return plan.dashboardTabs!.manifesto.features.videoUpload;
  }

  /// Handle image selection with plan restrictions
  Future<void> _pickImageWithPlanCheck(BuildContext context) async {
    if (await _canUploadImage()) {
      final c = Get.find<UploadController>();
      await c.pickImage();
    } else {
      await UpgradePlanDialog.showImageUploadRestricted(context: context);
    }
  }

  /// Handle video selection with plan restrictions
  Future<void> _pickVideoWithPlanCheck(BuildContext context) async {
    if (await _canUploadVideo()) {
      final c = Get.find<UploadController>();
      await c.pickVideo();
    } else {
      await UpgradePlanDialog.showVideoUploadRestricted(context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controller with existing URLs
    final c = Get.put(UploadController());

    // Initialize uploaded URLs if not already set
    if (c.uploadedUrls.isEmpty && (existingPdfUrl != null || existingImageUrl != null || existingVideoUrl != null)) {
      if (existingPdfUrl != null && existingPdfUrl!.isNotEmpty) {
        c.uploadedUrls["pdf"] = existingPdfUrl!;
      }
      if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
        c.uploadedUrls["image"] = existingImageUrl!;
      }
      if (existingVideoUrl != null && existingVideoUrl!.isNotEmpty) {
        c.uploadedUrls["video"] = existingVideoUrl!;
      }
    }

    return Obx(() => Column(
      children: [
        FileUploadTile(
          type: "pdf",
          label: "PDF",
          uploadedUrl: c.uploadedUrls["pdf"],
          localFile: c.localFiles.firstWhereOrNull((x) => x.type == "pdf"),
          onPick: c.pickPdf,
          onDelete: () async {
            final url = c.uploadedUrls["pdf"];
            if (url != null && url.isNotEmpty) {
              await c.deleteFile(url, "pdf");
              onPdfUrlChange?.call("");
            }
          },
        ),

        FileUploadTile(
          type: "image",
          label: "Image",
          uploadedUrl: c.uploadedUrls["image"],
          localFile: c.localFiles.firstWhereOrNull((x) => x.type == "image"),
          onPick: () => _pickImageWithPlanCheck(context),
          onDelete: () async {
            final url = c.uploadedUrls["image"];
            if (url != null && url.isNotEmpty) {
              await c.deleteFile(url, "image");
              onImageUrlChange?.call("");
            }
          },
          thumbnailBuilder: () {
            final imageFile = c.localFiles.firstWhereOrNull((x) => x.type == "image");
            if (imageFile != null) {
              return Image.memory(
                imageFile.bytes,
                fit: BoxFit.cover,
              );
            }
            return const SizedBox.shrink();
          },
        ),

        FileUploadTile(
          type: "video",
          label: "Video",
          uploadedUrl: c.uploadedUrls["video"],
          localFile: c.localFiles.firstWhereOrNull((x) => x.type == "video"),
          onPick: () => _pickVideoWithPlanCheck(context),
          onDelete: () async {
            final url = c.uploadedUrls["video"];
            if (url != null && url.isNotEmpty) {
              await c.deleteFile(url, "video");
              onVideoUrlChange?.call("");
            }
          },
        ),

        const SizedBox(height: 12),

        // Files are uploaded during save, not here
        // This button now just indicates files are ready for upload
        if (c.localFiles.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${c.localFiles.length} file${c.localFiles.length > 1 ? 's' : ''} ready to upload on save',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

      ],
    ));
  }
}
