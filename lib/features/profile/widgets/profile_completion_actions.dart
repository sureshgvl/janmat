import 'package:flutter/material.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../widgets/custom_button.dart';
import '../controllers/profile_completion_controller.dart';

class ProfileCompletionActions extends StatelessWidget {
  final ProfileCompletionController controller;

  const ProfileCompletionActions({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return Column(
      children: [
        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CustomButton(
            text: localizations.completeProfile,
            onPressed: () => controller.saveProfile(context),
            isLoading: controller.isLoading,
          ),
        ),

        const SizedBox(height: 5),

        // Info Text
        Text(
          localizations.requiredFields,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

