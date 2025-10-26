# JanMat Localization Implementation Guide

## 🎯 Overview

JanMat supports **English** and **Marathi (मराठी)** languages with instant language switching without app restart. This document explains the complete localization implementation using Flutter's internationalization framework and GetX for reactive state management.

## 📁 Files Structure

```
lib/
├── l10n/
│   ├── app_en.arb                    # English translations (main)
│   ├── app_mr.arb                    # Marathi translations
│   ├── app_localization_en.dart      # Generated English localization class
│   ├── app_localization_mr.dart      # Generated Marathi localization class
│   ├── app_localizations.dart        # Main localization delegate & factory
│   └── features/                     # Feature-specific localizations
│       └── settings/
│           └── settings_localizations.dart
├── controllers/
│   └── language_controller.dart      # Reactive language management
├── services/
│   └── language_service.dart         # SharedPreferences persistence
└── main.dart                         # App initialization with locale binding
```

## 🚀 Implementation Details

### 1. ARB Translation Files

#### English (app_en.arb)
```json
{
  "settings": "Settings",
  "language": "Language",
  "home": "Home",
  "profile": "Profile",
  "@profile": {
    "description": "User profile title"
  }
}
```

#### Marathi (app_mr.arb)
```json
{
  "settings": "सेटिंग्ज",
  "language": "भाषा",
  "home": "मुख्यपृष्ठ",
  "profile": "प्रोफाइल"
}
```

### 2. Optimized Language Controller

#### `lib/controllers/language_controller.dart`
```dart
class LanguageController extends GetxController {
  final LanguageService _languageService = LanguageService();

  // 🔄 Reactive locale bound to MaterialApp
  final Rx<Locale> currentLocale = const Locale('en').obs;

  Future<bool> changeLanguage(String languageCode) async {
    try {
      print('🔄 LANGUAGE CHANGE START: $languageCode');

      // 1. Persist to SharedPreferences
      await _languageService.setLanguage(languageCode);

      // 2. Update reactive locale - MaterialApp rebuilds automatically
      currentLocale.value = Locale(languageCode);

      print('⚡ MaterialApp rebuilds instantly (no app restart needed)');

      return true;
    } catch (e) {
      return false;
    }
  }

  String get currentLanguageCode => currentLocale.value.languageCode;
}
```

### 3. Language Service (Persistence)

#### `lib/services/language_service.dart`
```dart
class LanguageService {
  static const String _languageKey = 'selected_language';

  Future<String?> getStoredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
}
```

### 4. App Initialization

#### `lib/main.dart`
```dart
void main() async {
  // Initialize controllers early
  Get.put<LanguageController>(LanguageController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        return Obx(() {
          final languageController = Get.find<LanguageController>();
          return GetMaterialApp(
            title: 'JanMat',
            // 🔄 Reactive locale binding - changes instantly
            locale: languageController.currentLocale.value,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              // Include other feature delegates
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: '/home',
            getPages: AppRoutes.getPages,
          );
        });
      },
    );
  }
}
```

### 5. Smooth App Initialization

#### `lib/main.dart`
```dart
return Obx(() {
  final languageController = Get.find<LanguageController>();
  final currentLocale = languageController.currentLocale.value;

  // ✨ Smooth 300ms fade transition on language change
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: GetMaterialApp(
      key: ValueKey(currentLocale.languageCode), // Unique key for smooth animation
      // ⚡ Reactive locale binding - instant updates
      locale: currentLocale,
      // ... other MaterialApp properties
    ),
  );
});
```

### 6. Settings Screen Implementation

#### `lib/features/settings/screens/settings_screen.dart`
```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Scaffold(
      body: Column(
        children: [
          Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
          // Individual Obx wrappers for reactive UI
          Obx(() => RadioListTile<String>(
            title: Text(SettingsLocalizations.of(context)?.translate('english') ?? 'English'),
            value: 'en',
            groupValue: languageController.currentLanguageCode, // 🔄 Reactive
            onChanged: (value) => languageController.changeLanguage(value!),
          )),
          Obx(() => RadioListTile<String>(
            title: Text(SettingsLocalizations.of(context)?.translate('marathi') ?? 'मराठी'),
            value: 'mr',
            groupValue: languageController.currentLanguageCode, // 🔄 Reactive
            onChanged: (value) => languageController.changeLanguage(value!),
          )),
        ],
      ),
    );
  }
}
```

## 🔧 Setup Commands

### Initial Setup
```bash
# Generate localization classes
flutter pub get
flutter pub run intl_utils:generate

# For subsequent translation updates
flutter pub run intl_utils:generate
```

### Pubspec.yaml Configuration
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

# Add to dev_dependencies for ARB file generation
dev_dependencies:
  intl_utils: ^2.8.5
  flutter_gen: ^5.0.0

flutter:
  generate: true  # Required for l10n generation

flutter_intl:
  enabled: true
  class_name: AppLocalizations
  main_locale: en
  arb_dir: lib/l10n
  output_dir: lib/l10n
```

## 🎯 Key Challenges Solved

### 1. **App Restart Prevention**
**Problem:** `Get.updateLocale()` forces Flutter engine restart causing crashes
**Solution:** Use reactive locale binding with `Get.forceAppUpdate()`

### 2. **GetX Obx Errors**
**Problem:** Improper Obx usage causing "inappropriate use" errors
**Solution:** Get controllers outside Obx, wrap individual widgets

### 3. **Localization Context Updates**
**Problem:** Locale changes but old context persists
**Solution:** Reactive `Obx` wrapper rebuilds `GetMaterialApp` automatically

### 4. **Persistent Language Choice**
**Problem:** Language resets on app restart
**Solution:** SharedPreferences persistence with async initialization

## 📱 Usage Examples

### Basic Localization
```dart
// Get localized string
String greeting = AppLocalizations.of(context)?.welcomeMessage ?? 'Welcome';

// With parameters (pluralization)
String messages = AppLocalizations.of(context)?.remainingMessages(5) ?? '5 messages';

// Feature-specific localization
String themeName = SettingsLocalizations.of(context)?.translate('patrioticTheme') ?? 'Patriotic';
```

### Language Change Trigger
```dart
// In any widget with access to LanguageController
final languageController = Get.find<LanguageController>();

// Change to Marathi
await languageController.changeLanguage('mr');

// Change to English
await languageController.changeLanguage('en');
```

## 🔍 Debug Information

### Check Current Locale
```dart
// Get current locale
Locale current = Get.find<LanguageController>().currentLocale.value;
print('Current locale: ${current.languageCode}');

// Check if localization delegate is available
bool supported = AppLocalizations.localizationsDelegates
    .any((delegate) => delegate is AppLocalizations);
```

### Console Debug Output
```
🔄 LANGUAGE CHANGE START: mr
📍 Current locale before: Locale(en, )
✅ New locale set: Locale(mr, )
⚡ MaterialApp rebuilds instantly (no app restart needed)
```

## 🎨 UI/UX Design Patterns

### Language Selection
- ⚡ **Instant switching** without app restart
- 🎯 **Radio buttons** for clear selection
- ✅ **Visual feedback** with success snackbar
- 💾 **Persistent choice** across app sessions

### Supported Languages
| Language | Code | Status | Script |
|----------|------|--------|---------|
| English | en | ✅ Complete | Latin |
| मराठी | mr | ✅ Complete | Devanagari |

## 🚀 Performance Considerations

### Memory Usage
- ARB files are compiled into app bundle (minimal impact)
- GetX controllers are singleton (efficient memory usage)
- SharedPreferences is async (non-blocking)

### Runtime Performance
- `AnimatedSwitcher` provides smooth 300ms transitions
- Reactive updates minimize unnecessary rebuilds
- Localization lookup is cached by Flutter framework

## 🐛 Troubleshooting Common Issues

### Marathi Text Not Showing
1. Check console for locale change logs
2. Verify `app_mr.arb` has correct Devanagari text
3. Check if AnimatedSwitcher is animating (watch for 300ms transition)
4. Ensure `currentLocale.value = Locale(languageCode)` is executed
5. Check if Marathi font is available in pubspec.yaml

### Locale Not Persisting
1. Verify SharedPreferences is initialized
2. Check `_initializeLanguage()` is called in `onInit()`
3. Test SharedPreferences storage manually

### Blank/English Text Showing
1. Check if `AppLocalizations.of(context)` returns null
2. Verify localization delegates are in MaterialApp
3. Ensure supported locales includes the target language

### GetX Obx Errors
1. Move `Get.find()` calls outside Obx builders
2. Wrap individual widgets with Obx, not parents
3. Use unique keys for Obx widgets when needed

## 📋 Maintenance Checklist

- [ ] Update ARB files for new strings
- [ ] Run `flutter pub run intl_utils:generate` after ARB changes
- [ ] Test both English and Marathi in emulator/device
- [ ] Verify persistence across app restarts
- [ ] Check performance impact with large translation files
- [ ] Update this documentation for structural changes

---

## 🎉 Summary

This localization implementation provides **professional-grade multi-language support** with:
- ✅ **Zero-crash instant language switching**
- ✅ **Persistent user preferences**
- ✅ **Reactively managed UI updates**
- ✅ **Maintainable & scalable architecture**
- ✅ **Production-ready performance**

The reactive approach using GetX ensures smooth UX while Flutter's official localization handles the heavy lifting of translation management.
