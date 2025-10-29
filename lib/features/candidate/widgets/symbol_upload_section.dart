import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
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
          const SizedBox(height: 16),

          // Symbol Image Upload
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const Text(
                      '**Note:** For independent candidates, symbol image is mandatory for proper display.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '**Upload an image for your party symbol**',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supported formats: JPG, PNG. Maximum file size: 5MB.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Image size 256 x 256 for visibility',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Image Preview
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Obx(() => controller.isUploadingImage.value
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : controller.selectedSymbolImage.value != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    controller.selectedSymbolImage.value!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 30,
                                      );
                                    },
                                  ),
                                )
                              : controller.symbolImageUrl.value != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        controller.symbolImageUrl.value!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: 30,
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                    )),
                    ),
                    const SizedBox(width: 16),
                    // Upload Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.isUploadingImage.value
                            ? null
                            : () {
                                controller.pickSymbolImage(context);
                              },
                        icon: Obx(() => controller.isUploadingImage.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload)),
                        label: Obx(() => Text(
                          controller.isUploadingImage.value
                              ? 'Uploading...'
                              : localizations.uploadSymbolImage,
                        )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isUploadingImage.value
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Obx(() => controller.symbolImageUrl.value != null
                    ? const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Image uploaded successfully',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      );
    });
  }
}
