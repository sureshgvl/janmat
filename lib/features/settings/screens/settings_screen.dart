import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/settings/settings_localizations.dart';
import '../../../services/language_service.dart';
import 'device_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en'; // Default to English
  bool _isChangingLanguage = false;

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
      debugPrint('Error loading stored language: $e');
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
              color: Colors.black.withOpacity(0.5),
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
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.devices),
          title: Text(SettingsLocalizations.of(context)?.translate('deviceManagement') ?? 'Device Management'),
          subtitle: Text(SettingsLocalizations.of(context)?.translate('manageYourActiveDevices') ?? 'Manage your active devices'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Get.to(() => const DeviceManagementScreen());
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: Text(
            AppLocalizations.of(context)?.notifications ?? 'Notifications',
          ),
          trailing: Switch(
            value: true, // You can connect this to actual settings
            onChanged: (value) {
              // Handle notification toggle
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: Text(AppLocalizations.of(context)?.darkMode ?? 'Dark Mode'),
          trailing: Switch(
            value: false, // You can connect this to actual settings
            onChanged: (value) {
              // Handle dark mode toggle
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: Text(AppLocalizations.of(context)?.about ?? 'About'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to about screen
          },
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

      // Change app locale
      final locale = Locale(languageCode);
      Get.updateLocale(locale);

      // Wait for locale change to take effect
      await Future.delayed(const Duration(milliseconds: 500));

      // Force app restart to ensure complete locale update
      if (mounted) {
        // Show confirmation message
        Get.snackbar(
          'Success',
          languageCode == 'en'
              ? (SettingsLocalizations.of(context)?.translate('languageChangedToEnglish') ?? 'Language changed to English. Restarting app...')
              : (SettingsLocalizations.of(context)?.translate('languageChangedToMarathi') ?? 'भाषा मराठीमध्ये बदलली. अॅप रीस्टार्ट होत आहे...'),
          duration: const Duration(seconds: 2),
        );

        // Delay to show the message, then restart
        await Future.delayed(const Duration(seconds: 2));

        // Force complete app restart by navigating to root and rebuilding
        if (mounted) {
          // Clear all routes and go to home
          Get.offAllNamed('/home');

          // Force a complete rebuild by recreating the app context
          await Future.delayed(const Duration(milliseconds: 100));
          Get.forceAppUpdate();

          // Additional restart mechanism - reload the entire app
          SchedulerBinding.instance.addPostFrameCallback((_) {
            // This will trigger a complete rebuild of the app
            (context as Element).markNeedsBuild();
          });
        }
      }
    } catch (e) {
      debugPrint('Error changing language: $e');

      // Revert to previous language on error
      if (mounted) {
        setState(() {
          _selectedLanguage = previousLanguage;
          _isChangingLanguage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              previousLanguage == 'en'
                  ? (SettingsLocalizations.of(context)?.translate('failedToChangeLanguageEnglish') ?? 'Failed to change language. Please try again.')
                  : (SettingsLocalizations.of(context)?.translate('failedToChangeLanguageMarathi') ?? 'भाषा बदलण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.'),
            ),
            duration: const Duration(seconds: 2),
          ),
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
}
