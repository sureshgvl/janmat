# JanMat - Election Democracy Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-4.2.0-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**JanMat** is a comprehensive Flutter application for election democracy, empowering candidates, voters, and communities in the democratic process. Built with modern architecture and optimized for performance.

## 📱 Overview

JanMat provides a complete ecosystem for electoral participation including candidate profiles, manifesto management, voter engagement, real-time analytics, and community discussions. The app features advanced configuration management and build optimizations for enterprise-grade deployment.

## ✨ Key Features

### 🎯 Core Functionality
- **Candidate Management**: Complete profiles with manifesto, events, and analytics
- **Voter Engagement**: Interactive polls, surveys, and community discussions
- **Real-time Analytics**: Performance tracking and engagement metrics
- **Election Monitoring**: Live results and transparency features
- **Multi-language Support**: Hindi, English, and regional languages

### 🚀 Technical Features
- **Multi-environment Support**: Development, Staging, Production flavors
- **Advanced Logging**: Environment-based log levels and file rotation
- **Performance Monitoring**: Real-time performance tracking and optimization
- **Offline Capability**: Comprehensive offline functionality
- **Push Notifications**: Firebase Cloud Messaging integration
- **Analytics Integration**: Firebase Analytics and custom tracking

### 🔧 Advanced Optimizations

#### Performance Enhancements (From ChatGPT Optimizations)
- **Smart Splash Timing**: Min 2 seconds OR Firebase auth ready
- **WidgetsFlutterBinding Optimization**: Explicit binding initialization
- **IndexedStack for Better Performance**: Efficient tab navigation
- **Lazy Loading**: Background service initialization
- **Memory Management**: Advanced caching and cleanup
- **App Lifecycle Observers**: Background/foreground activity tracking

#### Architecture Improvements
- **Clean Architecture**: Separation of concerns with repositories and services
- **Dependency Injection**: GetX for state management and DI
- **Environment Configuration**: 100+ configurable environment variables
- **Build Flavors**: Advanced flavor management with Flutter Flavorizr
- **Centralized Routing**: Typed route management with constants

## 🏗️ Architecture

### Project Structure
```
lib/
├── core/                 # Core functionality
│   ├── services/        # App startup and configuration
│   ├── bindings/        # Dependency injection
│   └── routes/          # Centralized routing
├── features/            # Feature modules
│   ├── auth/           # Authentication
│   ├── candidate/      # Candidate management
│   ├── chat/           # Real-time messaging
│   └── analytics/      # Data visualization
├── services/            # Shared services
├── utils/              # Utilities and helpers
└── l10n/               # Localization
```

### Build Flavors

| Flavor | Description | App ID | Log Level |
|--------|-------------|--------|-----------|
| Development | Local testing | `com.janmat.app.dev` | Verbose |
| Staging | QA & testing | `com.janmat.app.staging` | Info |
| Production | End users | `com.janmat.app` | Warning |

## 🛠️ Technology Stack

### Core Technologies
- **Flutter 3.8.1** - Cross-platform UI framework
- **Dart 3.x** - Programming language
- **Firebase 4.x** - Backend services

### State Management
- **GetX** - Reactive state management and dependency injection

### Networking & APIs
- **Firebase Firestore** - Real-time database
- **Firebase Auth** - Authentication
- **Firebase Storage** - File uploads
- **Firebase Messaging** - Push notifications
- **HTTP Client** - REST API communication

### UI & UX
- **Material Design 3** - Modern design system
- **Google Fonts** - Typography
- **Flutter Localizations** - Internationalization
- **Custom Loading States** - Enhanced UX

### Development Tools
- **Flutter Flavorizr** - Advanced build flavors
- **Environment Config** - Runtime configuration
- **Custom Logger** - Structured logging with levels
- **Performance Monitor** - Real-time metrics

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.8.1+
- Android Studio / VS Code
- Firebase project setup
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/janmat.git
   cd janmat
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   ```bash
   # Copy and configure environment files
   cp .env.development .env.development.local
   cp .env.staging .env.staging.local
   cp .env.production .env.production.local
   ```

4. **Firebase Configuration**
   - Update Firebase configs in environment files
   - Download `google-services.json` for Android
   - Configure iOS Firebase settings

## 🏭 Build Instructions

### Development Build
```bash
# Run development version
flutter run --flavor development

# Build APK
flutter build apk --flavor development
```

### Staging Build
```bash
# Run staging version
flutter run --flavor staging

# Build app bundle
flutter build appbundle --flavor staging
```

### Production Build
```bash
# Build production release
flutter build appbundle --flavor production

# Build for different platforms
flutter build apk --flavor production --target-platform android-arm64
flutter build ios --flavor production
```

### Advanced Flavorizr Usage
```bash
# Generate flavor-specific files
flutter pub run flutter_flavorizr

# This creates separate main files and native configurations
```

## ⚙️ Configuration Management

### Environment Variables

The app uses **100+ configurable environment variables** organized by category:

#### App Configuration
```env
APP_NAME=JanMat
APP_ENVIRONMENT=development
ENABLE_DEBUG_LOGGING=true
SUPPORT_EMAIL=support@janmat.com
```

#### Feature Flags
```env
ENABLE_CHAT=true
ENABLE_VIDEO_PROCESSING=true
ENABLE_ADMOB=true
ENABLE_AI_FEATURES=false
```

#### Performance Settings
```env
LOG_LEVEL=verbose
CACHE_MAX_SIZE_MB=100
ENABLE_PERFORMANCE_MONITORING=true
```

### Log Levels
- **Verbose**: Maximum logging for development debugging
- **Debug**: Detailed development information
- **Info**: General application flow (Staging default)
- **Warning**: Only warnings and errors (Production default)
- **Error**: Only errors
- **Fatal**: Only critical failures

## 📊 Performance Optimizations

### ChatGPT-Recommended Enhancements Implemented

#### 1. Architecture & Structure
- ✅ **AppStartupService**: Centralized initialization
- ✅ **kReleaseMode Usage**: Proper release detection
- ✅ **Fallback Locale**: Robust localization

#### 2. Performance & Optimization
- ✅ **WidgetsFlutterBinding**: Explicit binding
- ✅ **Smart Splash Timing**: Auth-aware loading
- ✅ **Lazy Background Loading**: Non-blocking initialization
- ✅ **kReleaseMode Flags**: Optimized builds

#### 3. Logging & Monitoring
- ✅ **File Rotation**: 1MB limit with auto-cleanup
- ✅ **Log Levels**: Environment-based verbosity
- ✅ **AppLifecycle Observers**: Activity tracking
- ✅ **Centralized Route Names**: Type-safe routing

#### 4. Firebase & Security
- ✅ **Environment-based AppCheck**: Development vs Production
- ✅ **Conditional Settings**: Development relaxation

#### 5. UI/UX Improvements
- ✅ **Splash-to-App Transition**: Smart timing
- ✅ **IndexedStack Navigation**: Performance optimization

## 🔒 Security Features

- **Firebase App Check**: Device verification
- **SSL Pinning**: Certificate validation
- **Encryption**: Data and storage security
- **Secure Storage**: Sensitive data protection
- **Biometric Auth**: Optional authentication
- **Session Management**: Secure timeouts

## 🌍 Localization & Accessibility

Supported Languages:
- English (en)
- Hindi (hi)
- Marathi (mr)
- Telugu (te)
- Tamil (ta)
- Bengali (bn)
- Gujarati (gu)
- Odia (or)
- Assamese (as)

## 🧪 Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Code coverage
flutter test --coverage
```

## 📦 Release Process

### Version Management
- Use semantic versioning (major.minor.patch)
- Update version in `pubspec.yaml`
- Tag releases in git

### Environment Checklist
- [ ] Production Firebase keys configured
- [ ] Analytics tracking IDs updated
- [ ] Payment gateway keys verified
- [ ] Push notification certificates
- [ ] Icon and splash screens updated

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ChatGPT Optimizations**: Implemented numerous performance and architecture improvements
- **Flutter Community**: Outstanding framework and ecosystem
- **Firebase Team**: Excellent backend services
- **Open Source Contributors**: Various packages and tools

## 📞 Support

- **Email**: support@janmat.com
- **Issues**: [GitHub Issues](https://github.com/sureshgvl/janmat/issues)
- **Documentation**: [Project Wiki](https://github.com/sureshgvl/janmat/wiki)

---

**JanMat** - Empowering Democracy Through Technology 🚀
