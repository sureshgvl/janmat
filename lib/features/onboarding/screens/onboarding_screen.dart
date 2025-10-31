import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/onboarding/onboarding_localizations.dart';
import '../../language/services/language_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final LanguageService _languageService = LanguageService();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      titleKey: 'welcomeTitle',
      subtitleKey: 'welcomeSubtitle',
      icon: Icons.waving_hand,
      color: const Color(0xFF1E3A8A), // Blue
    ),
    OnboardingPageData(
      titleKey: 'candidatesTitle',
      subtitleKey: 'candidatesSubtitle',
      icon: Icons.people,
      color: const Color(0xFFFF9933), // Saffron
    ),
    OnboardingPageData(
      titleKey: 'chatTitle',
      subtitleKey: 'chatSubtitle',
      icon: Icons.chat,
      color: const Color(0xFF138808), // Green
    ),
    OnboardingPageData(
      titleKey: 'pollsTitle',
      subtitleKey: 'pollsSubtitle',
      icon: Icons.poll,
      color: const Color(0xFF1E3A8A), // Blue
    ),
    OnboardingPageData(
      titleKey: 'locationTitle',
      subtitleKey: 'locationSubtitle',
      icon: Icons.location_on,
      color: const Color(0xFFFF9933), // Saffron
    ),
    OnboardingPageData(
      titleKey: 'premiumTitle',
      subtitleKey: 'premiumSubtitle',
      icon: Icons.star,
      color: const Color(0xFF138808), // Green
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = OnboardingLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], localizations);
            },
          ),

          // Skip button
          Positioned(
            top: 50,
            right: 24,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                localizations?.translate('skip') ?? 'Skip',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Bottom navigation
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page indicators
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),

                // Next/Get Started button
                ElevatedButton(
                  onPressed: _currentPage == _pages.length - 1
                      ? _completeOnboarding
                      : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _pages[_currentPage].color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? (localizations?.translate('getStarted') ?? 'Get Started')
                        : (localizations?.translate('next') ?? 'Next'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, OnboardingLocalizations? localizations) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            pageData.color,
            pageData.color.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pageData.icon,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                localizations?.translate(pageData.titleKey) ?? pageData.titleKey,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                localizations?.translate(pageData.subtitleKey) ?? pageData.subtitleKey,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    await _languageService.markOnboardingCompleted();

    // Navigate to login
    Get.offAllNamed('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPageData {
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;

  const OnboardingPageData({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.color,
  });
}
