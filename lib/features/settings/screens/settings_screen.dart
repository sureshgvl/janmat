import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/settings/settings_localizations.dart';
import '../../../controllers/theme_controller.dart';
import '../../../controllers/background_color_controller.dart';
import '../../../core/app_theme.dart';
import '../../language/controller/language_controller.dart';
import '../../notifications/screens/notification_preferences_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(SettingsLocalizations.of(context)?.translate('aboutJanMat') ?? 'About JanMat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(SettingsLocalizations.of(context)?.translate('versionLabel', args: {'version': '1.0.0'}) ?? 'Version: 1.0.0'),
            const SizedBox(height: 8),
            Text(SettingsLocalizations.of(context)?.translate('janMatDescription') ?? 'JanMat is a platform connecting citizens with political candidates and fostering democratic engagement.'),
            const SizedBox(height: 16),
            Text(SettingsLocalizations.of(context)?.translate('features') ?? 'Features:'),
            const SizedBox(height: 4),
            Text(SettingsLocalizations.of(context)?.translate('featureCandidateProfiles') ?? '• Candidate profiles and information'),
            Text(SettingsLocalizations.of(context)?.translate('featureRealTimeChat') ?? '• Real-time chat and discussions'),
            Text(SettingsLocalizations.of(context)?.translate('featureElectionUpdates') ?? '• Election updates and notifications'),
            Text(SettingsLocalizations.of(context)?.translate('featureMultiLanguage') ?? '• Multi-language support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(SettingsLocalizations.of(context)?.translate('close') ?? 'Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final backgroundColorController = Get.find<BackgroundColorController>();
    final languageController = Get.find<LanguageController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      backgroundColor: AppTheme.homeBackgroundColor,
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Language Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppLocalizations.of(context)?.language ?? 'Language',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // English Radio Button - Wrapped individually
              Obx(() => RadioListTile<String>(
                title: Text(SettingsLocalizations.of(context)?.translate('english') ?? 'English'),
                value: 'en',
                groupValue: languageController.currentLanguageCode,
                onChanged: (value) async {
                  if (value != null) {
                    await languageController.changeLanguage(value);
                  }
                },
              )),
              // Marathi Radio Button - Wrapped individually
              Obx(() => RadioListTile<String>(
                title: Text(SettingsLocalizations.of(context)?.translate('marathi') ?? 'मराठी (Marathi)'),
                value: 'mr',
                groupValue: languageController.currentLanguageCode,
                onChanged: (value) async {
                  if (value != null) {
                    await languageController.changeLanguage(value);
                  }
                },
              )),
            ],
          ),
          const Divider(),
          // Other Settings
          Column(
            children: [
              // Theme Selection Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  SettingsLocalizations.of(context)?.translate('theme') ?? 'Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() => RadioListTile<AppThemeType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: themeController.getThemePrimaryColor(AppThemeType.patriotic),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(SettingsLocalizations.of(context)?.translate('patrioticTheme') ?? 'Patriotic'),
                  ],
                ),
                subtitle: Text(SettingsLocalizations.of(context)?.translate('patrioticDescription') ?? 'Saffron & Green - National spirit'),
                value: AppThemeType.patriotic,
                groupValue: themeController.currentThemeType.value,
                onChanged: (value) => themeController.changeTheme(value!),
              )),
              Obx(() => RadioListTile<AppThemeType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: themeController.getThemePrimaryColor(AppThemeType.parliamentary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(SettingsLocalizations.of(context)?.translate('parliamentaryTheme') ?? 'Parliamentary'),
                  ],
                ),
                subtitle: Text(SettingsLocalizations.of(context)?.translate('parliamentaryDescription') ?? 'Blue & White - Parliamentary elections'),
                value: AppThemeType.parliamentary,
                groupValue: themeController.currentThemeType.value,
                onChanged: (value) => themeController.changeTheme(value!),
              )),
              Obx(() => RadioListTile<AppThemeType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: themeController.getThemePrimaryColor(AppThemeType.assembly),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(SettingsLocalizations.of(context)?.translate('assemblyTheme') ?? 'Assembly'),
                  ],
                ),
                subtitle: Text(SettingsLocalizations.of(context)?.translate('assemblyDescription') ?? 'Green & White - State Assembly'),
                value: AppThemeType.assembly,
                groupValue: themeController.currentThemeType.value,
                onChanged: (value) => themeController.changeTheme(value!),
              )),
              Obx(() => RadioListTile<AppThemeType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: themeController.getThemePrimaryColor(AppThemeType.localBody),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(SettingsLocalizations.of(context)?.translate('localBodyTheme') ?? 'Local Body'),
                  ],
                ),
                subtitle: Text(SettingsLocalizations.of(context)?.translate('localBodyDescription') ?? 'Orange & Brown - Local governance'),
                value: AppThemeType.localBody,
                groupValue: themeController.currentThemeType.value,
                onChanged: (value) => themeController.changeTheme(value!),
              )),
              const Divider(),
              // Background Color Selection Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Background Color',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Obx(() => RadioListTile<BackgroundColorType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: backgroundColorController.getBackgroundColor(BackgroundColorType.light),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(backgroundColorController.getBackgroundColorDisplayName(BackgroundColorType.light)),
                  ],
                ),
                subtitle: Text(backgroundColorController.getBackgroundColorDescription(BackgroundColorType.light)),
                value: BackgroundColorType.light,
                groupValue: backgroundColorController.currentBackgroundColorType.value,
                onChanged: (value) => backgroundColorController.changeBackgroundColor(value!),
              )),
              Obx(() => RadioListTile<BackgroundColorType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: backgroundColorController.getBackgroundColor(BackgroundColorType.cream),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(backgroundColorController.getBackgroundColorDisplayName(BackgroundColorType.cream)),
                  ],
                ),
                subtitle: Text(backgroundColorController.getBackgroundColorDescription(BackgroundColorType.cream)),
                value: BackgroundColorType.cream,
                groupValue: backgroundColorController.currentBackgroundColorType.value,
                onChanged: (value) => backgroundColorController.changeBackgroundColor(value!),
              )),
              Obx(() => RadioListTile<BackgroundColorType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: backgroundColorController.getBackgroundColor(BackgroundColorType.blue),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(backgroundColorController.getBackgroundColorDisplayName(BackgroundColorType.blue)),
                  ],
                ),
                subtitle: Text(backgroundColorController.getBackgroundColorDescription(BackgroundColorType.blue)),
                value: BackgroundColorType.blue,
                groupValue: backgroundColorController.currentBackgroundColorType.value,
                onChanged: (value) => backgroundColorController.changeBackgroundColor(value!),
              )),
              Obx(() => RadioListTile<BackgroundColorType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: backgroundColorController.getBackgroundColor(BackgroundColorType.green),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(backgroundColorController.getBackgroundColorDisplayName(BackgroundColorType.green)),
                  ],
                ),
                subtitle: Text(backgroundColorController.getBackgroundColorDescription(BackgroundColorType.green)),
                value: BackgroundColorType.green,
                groupValue: backgroundColorController.currentBackgroundColorType.value,
                onChanged: (value) => backgroundColorController.changeBackgroundColor(value!),
              )),
              Obx(() => RadioListTile<BackgroundColorType>(
                title: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: backgroundColorController.getBackgroundColor(BackgroundColorType.gray),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(backgroundColorController.getBackgroundColorDisplayName(BackgroundColorType.gray)),
                  ],
                ),
                subtitle: Text(backgroundColorController.getBackgroundColorDescription(BackgroundColorType.gray)),
                value: BackgroundColorType.gray,
                groupValue: backgroundColorController.currentBackgroundColorType.value,
                onChanged: (value) => backgroundColorController.changeBackgroundColor(value!),
              )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(AppLocalizations.of(context)?.notifications ?? 'Notifications'),
                subtitle: Text(SettingsLocalizations.of(context)?.translate('manageNotificationPreferences') ?? 'Manage notification preferences'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Get.to(() => const NotificationPreferencesScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(AppLocalizations.of(context)?.about ?? 'About'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
