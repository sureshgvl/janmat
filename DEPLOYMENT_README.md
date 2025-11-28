# 🚀 JanMat Deployment Guide

## 📋 Pre-Deployment Checklist

### ✅ Version Management
**Update version before each release:**
- **pubspec.yaml**: Increment version (e.g., `1.0.3+6`)
- **build/web/version.json**: Update app versions
- Commit version changes: `git commit -m "Version 1.0.3"`

### 🔧 flutter clean Usage
**Recommended**: Always run `flutter clean` before major builds
- **When required**: After dependency changes, pubspec updates, major UI changes
- **When optional**: For release builds, to ensure clean cache
- **Performance**: Clean builds take longer but ensure reliability

---

## 🌐 Web Deployment

### Prerequisites
```bash
# Required tools
flutter --version  # Check Flutter SDK
firebase --version # Check Firebase CLI
node --version     # Check Node.js

# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Step-by-Step Web Deployment

#### 1. **Version Update**
```bash
# Update pubspec.yaml version
# Example: version: 1.0.3+6

# Update build version (optional for web)
# build/web/version.json: {"version": "1.0.3", "build_number": "6"}
```

#### 2. **Clean & Get Dependencies**
```bash
flutter clean                    # Clean cache (recommended)
flutter pub get                  # Get dependencies
flutter pub outdated             # Check for updates (optional)
```

#### 3. **Build Web Release**
```bash
# Standard build
flutter build web --release

# With WASM warnings disabled
flutter build web --release --no-wasm-dry-run

# Verify build
ls -la build/web/
```

#### 4. **Deploy to Firebase Hosting**
```bash
# Deploy to hosting
firebase deploy --only hosting

# Deploy to specific project (if using multiple)
firebase deploy --only hosting -P project-id

# Check deployment status
firebase hosting:sites:list
```

#### 5. **Post-Deployment Verification**
```bash
# Check live version
curl -I https://janmat-official.web.app/version.json

# Test PWA update
# Open incognito mode
# Clear PWA storage if needed
# Check for update popup: "New version available. Reload now?"
```

### Web Build Directory Structure
```
build/web/
├── assets/
├── canvaskit/
├── icons/
├── flutter_service_worker.js  # ⚠️ Auto-update enabled
├── main.dart.js              # ⚠️ Built code
├── index.html                # ⚠️ Modified with update listener
└── manifest.json
```

### Web Service Worker Auto-Updates
- ✅ **Auto PWA updates**: Shows "New version available" popup
- ✅ **Cache management**: Automatically clears old caches
- ✅ **Version detection**: Based on `version.json` changes
- ✅ **User-friendly**: Asks before reloading

---

## 📱 Android Deployment

### Prerequisites
```bash
# Android Studio SDK
# Java JDK 11+
# Android SDK API 33+

# Check Android setup
flutter doctor --android-licenses
```

### Step-by-Step Android Deployment

#### 1. **Version Update**
```yaml
# pubspec.yaml
version: 1.0.3+6  # +6 is Android versionCode

# Optional: Update app version names
# android/app/build.gradle (update versionName/versionCode)
```

#### 2. **Clean & Build APK**
```bash
# Clean builds (recommended before release)
flutter clean

# Get dependencies
flutter pub get

# Build APK for release
flutter build apk --release

# Or build app bundle (Google Play recommended)
flutter build appbundle --release

# Build for specific architecture
flutter build apk --release --split-per-abi
```

#### 3. **Sign APK (for Play Store)**
```gradle
# android/app/build.gradle - Configure signing
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 4. **Generate Signed Bundle/APK**
```bash
# Generate signed app bundle (recommended)
flutter build appbundle --release

# Or generate signed APK
flutter build apk --release
```

#### 5. **Upload to Google Play Console**
1. 🚀 **Go to Google Play Console**
2. 📦 **Release** → **Production/Testing**
3. 📤 **Upload bundle** (`build/app/outputs/bundle/release/app-release.aab`)
4. 🏷️ **Version Code**: Auto-incremented
5. 📋 **Release Notes**: Update changelist
6. 🚀 **Save & Release**

### Android Build Outputs
```
build/app/outputs/
├── apk/release/           # APK files
│   ├── app-release.apk      # Universal APK
│   ├── app-armeabi-v7a-release.apk  # Split APKs
│   ├── app-arm64-v8a-release.apk
│   └── app-x86_64-release.apk
└── bundle/release/        # App Bundle
    └── app-release.aab      # Google Play Bundle
```

---

## 🔄 Combined Web + Android Release

### Production Release Checklist
- [ ] **Update version** in pubspec.yaml (+1 build number)
- [ ] **Update changelog** and release notes
- [ ] **Test on physical devices** (Android + Web)
- [ ] **Build & deploy web** first (firebase deploy --only hosting)
- [ ] **Build & upload Android** to Play Store
- [ ] **Verify auto-updates** work on web PWA
- [ ] **Confirm all features** working post-deployment

### Automated Release Scripts (Windows)

Four automated deployment scripts are available in the project root:

#### **⭐ RECOMMENDED: `deploy_web.ps1`** - PowerShell (Most Reliable)
```powershell
# Run Powershell script (bypasses VS Code conflicts)
deploy_web.ps1
```
**Features:**
- ✅ **Environment isolation** - Completely avoids VS Code Impeller conflicts
- ✅ **PowerShell native** - Better variable handling than batch files
- ✅ **Color-coded output** - Clear visual progress feedback
- ✅ Interactive version management with backups
- ✅ Complete web build and Firebase deployment
- ✅ Error handling with prompts

#### Legacy Scripts (Batch Files)

#### 1. **`deploy_web.bat`** - Web-only deployment
```bat
# Automated web deployment process
deploy_web.bat
```
**Features:**
- ✅ Prerequisites checking (Flutter, Firebase CLI)
- ✅ **Automatic version input** - Prompts user to enter new version
- ✅ **Auto-updates pubspec.yaml** and creates backup
- ✅ Version commit reminders with suggested message
- ✅ Clean build with dependency management
- ✅ Web build and Firebase deployment
- ✅ Post-deployment verification
- ✅ Comprehensive logging and error handling

#### 2. **`deploy_android.bat`** - Android-only deployment
```bat
# Automated Android deployment process
deploy_android.bat
```
**Features:**
- ✅ Prerequisites checking (Flutter, Java, Android SDK)
- ✅ Build type selection (APK/App Bundle/Split APK)
- ✅ Signing keystore verification
- ✅ Complete deployment instructions for Play Store

#### 3. **`deploy_full.bat`** - Complete release (Web + Android)
```bat
# Complete automated release process
deploy_full.bat
```
**Features:**
- ✅ Combines web + Android deployment
- ✅ Version management reminders
- ✅ Build type selection
- ✅ Comprehensive testing checklist
- ✅ Release summary and next steps

### Quick Commands Reference

#### Web Deploy
```cmd
# Using batch file (recommended)
deploy_web.bat

# Or manual commands
flutter clean && flutter pub get
flutter build web --release --no-wasm-dry-run
firebase deploy --only hosting
```

#### Android Deploy
```cmd
# Using batch file (recommended)
deploy_android.bat

# Or manual commands
flutter clean && flutter pub get
flutter build appbundle --release
# Upload to Google Play Console
```

#### Full Release
```cmd
# Single command for complete release
deploy_full.bat
```

### Release Branch Strategy
```
main (production) ← develop ← feature branches
    ↓
Release process:
1. git checkout develop
2. git pull origin develop
3. Update version, test
4. git checkout -b release/v1.0.3
5. Build & deploy
6. Merge to main: git checkout main && git merge release/v1.0.3
7. Tag release: git tag v1.0.3 && git push origin --tags
```

---

## 🐛 Troubleshooting

### Web Deployment Issues
```bash
# Force cache clear on Firebase
firebase hosting:cache:clear

# Check Firebase project
firebase projects:list

# Redeploy with cache busting
firebase deploy --only hosting --force
```

### Android Build Issues
```bash
# Clean Android build
flutter clean && cd android && ./gradlew clean && cd ..

# Force rebuild native code
flutter build apk --release --no-shrink

# Check signing config
keytool -list -v -keystore your-keystore.jks
```

### PWA Update Issues
**Force update for users:**
1. Update `build/web/version.json` with higher version
2. Deploy web app
3. Users will see update popup on refresh

**Debug service worker:**
```javascript
// In browser console
navigator.serviceWorker.getRegistrations().then(registrations => {
  registrations.forEach(reg => console.log(reg));
});
```

### Version Sync Issues
```bash
# Ensure versions match
grep version pubspec.yaml
cat build/web/version.json
grep versionCode android/app/build.gradle
```

---

## 📊 Rollback Plan

### Web Rollback
```bash
# Deploy previous version
firebase hosting:rollback
# Check rollback history
firebase hosting:histories:list

# Manual rollback
git checkout previous-tag
flutter build web --release
firebase deploy --only hosting
```

### Android Rollback
1. Google Play Console → Release dashboard
2. Rollback submission to previous version
3. Distribute previous APK/AAB

---

## 🎯 Quick Commands Reference

### Web Deploy
```bash
flutter clean && flutter pub get                                  # Clean
flutter build web --release --no-wasm-dry-run                  # Build
firebase deploy --only hosting                                  # Deploy
```

### Android Deploy
```bash
flutter clean && flutter pub get                               # Clean
flutter build appbundle --release                              # Build
# Upload to Play Store manually                               # Deploy
```

### Full Release
```bash
git checkout develop                                           # Branch
# Update version in pubspec.yaml                              # Version
flutter clean && flutter pub get                              # Clean

# Web
flutter build web --release --no-wasm-dry-run                 # Build web
firebase deploy --only hosting                                 # Deploy web

# Android
flutter build appbundle --release                             # Build Android
# Upload to Google Play Console                              # Deploy Android
```

---

**📝 Last Updated**: November 28, 2025
**🎯 Current Version**: 1.0.3+6
