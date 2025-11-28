@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Force UTF-8 output safely
powershell -NoLogo -NoProfile -Command ^
  "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8"

REM =================================================
REM JANMAT FULL RELEASE SCRIPT
REM Web + Android Deployment Automation
REM Version: 1.0.3+6
REM Last Updated: November 29, 2025
REM =================================================

echo =============================================
echo Starting JanMat Full Release (Web + Android)
echo =============================================

REM Check prerequisites
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter SDK not found. Install Flutter and add to PATH.
    pause
    exit /b 1
)

firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found. Install with:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Java JDK not found. Required for Android builds.
    pause
    exit /b 1
)

echo All prerequisites OK.

REM =================================================
REM VERSION MANAGEMENT
REM =================================================
echo Reading current version...

for /f "tokens=2 delims=: " %%a in ('findstr "version:" pubspec.yaml') do set CURRENT_VERSION=%%a

echo Current version: %CURRENT_VERSION%
echo.

set /p NEW_VERSION="Enter new version (e.g., 1.0.4+7) or press Enter to use %CURRENT_VERSION%: "

if "%NEW_VERSION%"=="" (
    set NEW_VERSION=%CURRENT_VERSION%
)

echo Using version: %NEW_VERSION%
echo Creating backup pubspec.yaml.backup...
copy /y pubspec.yaml pubspec.yaml.backup >nul

powershell -Command "(Get-Content pubspec.yaml) -replace 'version:.*', 'version: %NEW_VERSION%' | Set-Content pubspec.yaml"

echo Version updated.
findstr "version:" pubspec.yaml

echo.
echo This version will be used for:
echo - Android versionCode (+buildnumber from pubspec)
echo - iOS build number
echo - Web cache busting
echo - Firebase deployment versioning
echo.
echo Recommended commit: git commit -m "Version %NEW_VERSION%"
echo.
set /p version_confirm="Press Enter when ready to proceed..."

REM =================================================
REM WEB DEPLOYMENT
REM =================================================
echo Starting Web Deployment...

echo Cleaning web build...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building web release...
flutter build web --release --no-wasm-dry-run

if %errorlevel% neq 0 (
    echo ERROR: Web build failed!
    echo Check Flutter errors above and fix before continuing.
    pause
    exit /b 1
)

echo Deploying to Firebase Hosting...
firebase deploy --only hosting

if %errorlevel% neq 0 (
    echo ERROR: Firebase deployment failed!
    echo Check Firebase login and project permissions.
    pause
    exit /b 1
)

echo Web deployment successful!

REM =================================================
REM ANDROID DEPLOYMENT
REM =================================================
echo Starting Android Deployment...

echo Choose Android build type:
echo [1] APK (Universal - testing/beta)
echo [2] App Bundle (Google Play Store - recommended)
echo [3] Skip Android deployment
echo.

set /p android_choice=Enter choice (1-3):

if "%android_choice%"=="3" (
    echo Skipping Android deployment.
    goto :release_summary
)

if "%android_choice%"=="1" (
    echo Building Universal APK...
    flutter build apk --release
    set android_file=build\app\outputs\flutter-apk\app-release.apk
    set android_type=APK
    set upload_dest=Local/Beta Testing
) else if "%android_choice%"=="2" (
    echo Building App Bundle for Google Play...
    flutter build appbundle --release
    set android_file=build\app\outputs\bundle\release\app-release.aab
    set android_type=App Bundle
    set upload_dest=Google Play Console
) else (
    echo Invalid choice. Skipping Android deployment.
    goto :release_summary
)

if %errorlevel% neq 0 (
    echo ERROR: Android build failed!
    echo Continuing with web-only deployment...
    goto :release_summary
)

echo Android build successful!

REM =================================================
REM RELEASE SUMMARY
REM =================================================
:release_summary

echo.
echo =============================================
echo JANMAT RELEASE COMPLETED!
echo =============================================
echo.
echo DEPLOYMENT SUMMARY:
echo.

echo WEB DEPLOYMENT:
echo Hosted at: https://janmat-official.web.app
echo Auto-updates: ENABLED
echo Mobile users will see update popup on refresh

if "%android_choice%"=="1" (
    echo.
    echo ANDROID DEPLOYMENT:
    echo Build Type: %android_type% (Universal APK)
    echo File: %android_file%
    echo For: %upload_dest%
    echo Install: adb install %android_file%
) else if "%android_choice%"=="2" (
    echo.
    echo ANDROID DEPLOYMENT:
    echo Build Type: %android_type%
    echo File: %android_file%
    echo For: %upload_dest% (when ready)
    echo Upload to: https://play.google.com/console
)

echo.
echo VERSION INFO:
findstr "version:" pubspec.yaml

echo.
echo TESTING CHECKLIST:
echo - Web: Test on mobile browser
echo - Web: Check manifesto edit UI
echo - Web: PWA update popup works
echo - Android: Install and test APK
echo - Android: Test manifesto functionality
echo - Web PWA: Confirm auto-updates work

echo.
echo READY FOR NEXT RELEASE:
echo Increment version in pubspec.yaml and run again
echo.

pause
