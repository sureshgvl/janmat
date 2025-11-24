import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../language/services/language_service.dart';
import '../../language/controller/language_controller.dart';
import '../../../l10n/features/auth/auth_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final LanguageService _languageService = LanguageService();
  String _selectedLanguage = 'en'; // Default to English

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Blue
              Color(0xFF3B82F6), // Lighter blue
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 60),
                _buildLanguageOptions(),
                const SizedBox(height: 60),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // App Logo/Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.language,
            size: 60,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 40),

        // Title
        Text(
          AuthLocalizations.of(context)?.translate('welcomeToJanMat') ?? 'Welcome to JanMat',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Subtitle
        Text(
          AuthLocalizations.of(context)?.translate('pleaseSelectYourPreferredLanguage') ?? 'Please select your preferred language',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLanguageOptions() {
    return Column(
      children: [
        // Language Options
        _buildLanguageOption(
          title: AuthLocalizations.of(context)?.translate('english') ?? 'English',
          subtitle: AuthLocalizations.of(context)?.translate('continueInEnglish') ?? 'Continue in English',
          flag: '🇺🇸',
          languageCode: 'en',
          isSelected: _selectedLanguage == 'en',
        ),
        const SizedBox(height: 20),

        _buildLanguageOption(
          title: AuthLocalizations.of(context)?.translate('marathi') ?? 'मराठी',
          subtitle: AuthLocalizations.of(context)?.translate('continueInMarathi') ?? 'मराठीमध्ये सुरू ठेवा',
          flag: '🇮🇳',
          languageCode: 'mr',
          isSelected: _selectedLanguage == 'mr',
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _continueToLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        ),
        child: Text(
          AuthLocalizations.of(context)?.translate('continue') ?? 'Continue',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String flag,
    required String languageCode,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectLanguage(languageCode),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  Future<void> _continueToLogin() async {
    // Save selected language using language service
    await _languageService.setLanguage(_selectedLanguage);

    // Mark first time as complete
    await _languageService.markFirstTimeComplete();

    // Update language controller's reactive locale if available
    try {
      final languageController = Get.find<LanguageController>();
      languageController.currentLocale.value = Locale(_selectedLanguage);
    } catch (e) {
      // Language controller not available, use Get.updateLocale as fallback
      Get.updateLocale(Locale(_selectedLanguage));
    }

    // Navigate to onboarding screen
    Get.offAllNamed('/onboarding');
  }
}
