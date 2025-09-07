import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/language_service.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
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
                // App Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                const Text(
                  'Welcome to JanMat',
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
                  'Please select your preferred language',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Language Options
                _buildLanguageOption(
                  title: 'English',
                  subtitle: 'Continue in English',
                  flag: '🇺🇸',
                  languageCode: 'en',
                  isSelected: _selectedLanguage == 'en',
                ),
                const SizedBox(height: 20),

                _buildLanguageOption(
                  title: 'मराठी',
                  subtitle: 'मराठीमध्ये सुरू ठेवा',
                  flag: '🇮🇳',
                  languageCode: 'mr',
                  isSelected: _selectedLanguage == 'mr',
                ),
                const SizedBox(height: 60),

                // Continue Button
                SizedBox(
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
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: Text(
                      _selectedLanguage == 'en' ? 'Continue' : 'सुरू ठेवा',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
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
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
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
    // Save selected language
    await _languageService.setLanguage(_selectedLanguage);

    // Mark first time as complete
    await _languageService.markFirstTimeComplete();

    // Update app locale
    final locale = Locale(_selectedLanguage);
    Get.updateLocale(locale);

    // Navigate to login screen
    Get.offAllNamed('/login');
  }
}