import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/profile/profile_localizations.dart';
import '../../../utils/theme_constants.dart';
import '../../../features/common/loading_overlay.dart';
import '../controllers/profile_completion_controller.dart';
import '../widgets/profile_completion_form.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = ProfileLocalizations.of(context)!;

    return GetBuilder<ProfileCompletionController>(
      init: ProfileCompletionController(),
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: Text(localizations.completeYourProfile),
          automaticallyImplyLeading: false, // Prevent back button
        ),
        body: LoadingOverlay(
          isLoading: controller.isLoading,
          child: Container(
            color: AppColors.background,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ProfileCompletionForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

