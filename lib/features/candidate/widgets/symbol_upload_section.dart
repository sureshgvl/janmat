import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../../core/widgets/file_upload_section.dart';
import '../../../../core/models/unified_file.dart';
import '../controllers/change_party_symbol_controller.dart';

class SymbolUploadSection extends StatelessWidget {
  final ChangePartySymbolController controller;
  final GlobalKey<FormState> formKey;

  const SymbolUploadSection({
    super.key,
    required this.controller,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Obx(() {
      if (!controller.isIndependent.value) return const SizedBox.shrink();

      return Column(
        children: [
          // Symbol Name Field
          TextFormField(
            controller: controller.symbolNameController,
            decoration: InputDecoration(
              labelText: localizations.symbolNameLabel,
              hintText: localizations.symbolNameHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.label),
            ),
            validator: (value) {
              if (controller.isIndependent.value &&
                  (value == null || value.trim().isEmpty)) {
                return localizations.symbolNameValidation;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Symbol Image Upload using cross-platform ImageUploadSection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and size limit badge
                Row(
                  children: [
                    Text(
                      localizations.symbolImageOptional,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Max 5MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Important notice
                const Text(
                  '**Note:** For independent candidates, symbol image is mandatory for proper display.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),

                // Cross-platform Image Upload Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.symbolImageDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supported formats: JPG, PNG. Image size 256 x 256 for visibility.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Use our cross-platform ImageUploadSection
                    ImageUploadSection(
                      title: localizations.uploadSymbolImage,
                      storagePath: 'candidate_symbols',
                      existingImageUrl: controller.symbolImageUrl.value,
                      onImageSelected: (String? uploadedUrl) {
                        if (uploadedUrl != null) {
                          controller.symbolImageUrl.value = uploadedUrl;
                        }
                      },
                      maxFileSize: 5, // 5MB limit
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
