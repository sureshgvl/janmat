import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';
import 'device_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en'; // Default to English

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get current locale
    final locale = Localizations.localeOf(context);
    setState(() {
      _selectedLanguage = locale.languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildLanguageSection(context),
          const Divider(),
          _buildOtherSettings(context),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        RadioListTile<String>(
          title: const Text('English'),
          value: 'en',
          groupValue: _selectedLanguage,
          onChanged: (value) => _changeLanguage(value!),
        ),
        RadioListTile<String>(
          title: const Text('मराठी (Marathi)'),
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
          title: const Text('Device Management'),
          subtitle: const Text('Manage your active devices'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Get.to(() => const DeviceManagementScreen());
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: Text(AppLocalizations.of(context)?.notifications ?? 'Notifications'),
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

  void _changeLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });

    // Change app locale
    final locale = Locale(languageCode);
    Get.updateLocale(locale);

    // Show confirmation using ScaffoldMessenger instead of Get.snackbar
    // to avoid ticker issues
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language changed to ${languageCode == 'en' ? 'English' : 'Marathi'}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}