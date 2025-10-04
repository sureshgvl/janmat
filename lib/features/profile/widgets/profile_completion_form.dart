import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../utils/theme_constants.dart';
import '../controllers/profile_completion_controller.dart';
import 'personal_info_section.dart';
import 'location_selection_section.dart';
import 'profile_completion_actions.dart';

class ProfileCompletionForm extends GetView<ProfileCompletionController> {
  const ProfileCompletionForm({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context) ?? ProfileLocalizations.current;

    return GetBuilder<ProfileCompletionController>(
      builder: (controller) => Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Text(
              localizations.welcomeCompleteYourProfile,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final currentUser = FirebaseAuth.instance.currentUser;
                String loginMethod = localizations.autoFilledFromAccount;

                if (currentUser?.providerData.isNotEmpty ?? false) {
                  final provider = currentUser!.providerData.first;
                  if (provider.providerId == 'google.com') {
                    loginMethod = 'Google account';
                  } else if (provider.providerId == 'phone') {
                    loginMethod = 'phone number';
                  }
                }

                return Text(
                  localizations.preFilledFromAccount(loginMethod),
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                );
              },
            ),
            const SizedBox(height: 16),

            // Personal Info Section
            PersonalInfoSection(controller: controller),
            const SizedBox(height: 16),

            // Location Selection Section
            LocationSelectionSection(controller: controller),
            const SizedBox(height: 16),

            // Actions Section
            ProfileCompletionActions(controller: controller),
          ],
        ),
      ),
      ),
    );
  }
}

