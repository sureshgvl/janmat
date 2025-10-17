import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/change_party_symbol_controller.dart';

class UpdateButton extends StatelessWidget {
  final ChangePartySymbolController controller;
  final GlobalKey<FormState> formKey;

  const UpdateButton({
    super.key,
    required this.controller,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Obx(() {
      // Check if current party and selected party are different
      final currentPartyId = controller.currentCandidate.value?.party;
      final selectedPartyId = controller.selectedParty.value?.id;
      final hasPartyChanges = currentPartyId != selectedPartyId;

      // For independent candidates, also check if symbol name or image has changed
      final isIndependent = controller.isIndependent.value;
      final currentSymbolName = controller.currentCandidate.value?.symbolName ?? '';
      final currentSymbolImageUrl = controller.currentCandidate.value?.extraInfo?.media
          ?.firstWhere(
            (item) => item['type'] == 'symbolImage',
            orElse: () => <String, dynamic>{},
          )['url'] as String? ?? '';

      final hasSymbolChanges = isIndependent && (
        controller.symbolNameController.text.trim() != currentSymbolName ||
        controller.symbolImageUrl.value != currentSymbolImageUrl
      );

      final hasChanges = hasPartyChanges || hasSymbolChanges;
      final isEnabled = !controller.isLoading.value && hasChanges;

      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? () async {
            if (formKey.currentState!.validate()) {
              final success = await controller.updatePartyAndSymbol(context);
              if (success) {
                Get.back(result: controller.currentCandidate.value);
              }
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Obx(() => controller.isLoading.value
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      localizations.updatingText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isEnabled ? theme.colorScheme.onPrimary : Colors.white70,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save,
                      color: isEnabled ? Colors.white : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      localizations.updateButton,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isEnabled ? theme.colorScheme.onPrimary : Colors.white70,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )),
        ),
      );
    });
  }
}