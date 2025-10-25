import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/settings/settings_localizations.dart';
import '../../../services/language_service.dart';
import '../../../controllers/theme_controller.dart';
import '../../notifications/screens/notification_preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en'; // Default to English
  bool _isChangingLanguage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load stored language preference
    _loadStoredLanguage();
  }

  Future<void> _loadStoredLanguage() async {
    try {
      final languageService = LanguageService();
      final storedLanguage = await languageService.getStoredLanguage();
      if (storedLanguage != null && mounted) {
        setState(() {
          _selectedLanguage = storedLanguage;
        });
      } else {
        // Fallback to current locale
        final locale = Localizations.localeOf(context);
        if (mounted) {
          setState(() {
            _selectedLanguage = locale.languageCode;
          });
        }
      }
    } catch (e) {
      AppLogger.uiError('Error loading stored language: $e');
      // Fallback to current locale
      final locale = Localizations.localeOf(context);
      if (mounted) {
        setState(() {
          _selectedLanguage = locale.languageCode;
        });
      }
    }
  }


  // Refresh language selection when locale changes
  void _refreshLanguageSelection() {
    final locale = Localizations.localeOf(context);
    if (mounted && _selectedLanguage != locale.languageCode) {
      setState(() {
        _selectedLanguage = locale.languageCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const SizedBox(height: 16),
              _buildLanguageSection(context),
              const Divider(),
              _buildOtherSettings(context),
            ],
          ),
          if (_isChangingLanguage)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            AppLocalizations.of(context)?.language ?? 'Language',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        RadioListTile<String>(
          title: Text(SettingsLocalizations.of(context)?.translate('english') ?? 'English'),
          value: 'en',
          groupValue: _selectedLanguage,
          onChanged: (value) => _changeLanguage(value!),
        ),
        RadioListTile<String>(
          title: Text(SettingsLocalizations.of(context)?.translate('marathi') ?? 'मराठी (Marathi)'),
          value: 'mr',
          groupValue: _selectedLanguage,
          onChanged: (value) => _changeLanguage(value!),
        ),
      ],
    );
  }

  Widget _buildOtherSettings(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Column(
      children: [
        // Theme Selection Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            SettingsLocalizations.of(context)?.translate('theme') ?? 'Theme',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
        ListTile(
          leading: const Icon(Icons.notifications),
          title: Text(
            AppLocalizations.of(context)?.notifications ?? 'Notifications',
          ),
          subtitle: Text(SettingsLocalizations.of(context)?.translate('manageNotificationPreferences') ?? 'Manage notification preferences'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            AppLogger.settings('🔍 Navigating to NotificationPreferencesScreen');
            Get.to(() => const NotificationPreferencesScreen());
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: Text(AppLocalizations.of(context)?.about ?? 'About'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _showAboutDialog,
        ),
      ],
    );
  }

  void _changeLanguage(String languageCode) async {
    if (_isChangingLanguage) return; // Prevent multiple calls

    final previousLanguage = _selectedLanguage;

    setState(() {
      _isChangingLanguage = true;
      _selectedLanguage = languageCode;
    });

    try {
      // Save language preference using LanguageService
      final languageService = LanguageService();
      await languageService.setLanguage(languageCode);

      // Change app locale without restarting app
      final locale = Locale(languageCode);
      Get.updateLocale(locale);

      // Wait for locale change to take effect
      await Future.delayed(const Duration(milliseconds: 300));

        // Show confirmation message - but check if widget is still mounted
        if (mounted) {
          Get.snackbar(
            SettingsLocalizations.of(context)?.translate('success') ?? 'Success',
            languageCode == 'en'
                ? 'Language changed to English'
                : 'भाषा मराठीमध्ये बदलली',
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
        }

      // Force UI refresh to update all localized text
      if (mounted) {
        setState(() {
          // Setting state will trigger rebuild with new locale
        });
      }

    } catch (e) {
      AppLogger.uiError('Error changing language: $e');

      // Revert to previous language on error
      if (mounted) {
        setState(() {
          _selectedLanguage = previousLanguage;
          _isChangingLanguage = false;
        });

        // Use Get.snackbar instead of ScaffoldMessenger to avoid mounted context issues
        Get.snackbar(
          'Error',
          previousLanguage == 'en'
              ? 'Failed to change language. Please try again.'
              : 'भाषा बदलण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingLanguage = false;
        });
      }
    }
  }



  void _showAboutDialog() {
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
}
