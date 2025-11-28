@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Force UTF-8 output safely
powershell -NoLogo -NoProfile -Command ^
  "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8"

REM =================================================
REM JANMAT ANDROID DEPLOYMENT SCRIPT (UTF-8 VERSION)
REM Version: 1.0.3+6
REM Last Updated: November 29, 2025
REM =================================================

echo =============================================
echo Starting JanMat Android Deployment...
echo =============================================

REM Check Flutter
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter SDK not found. Install Flutter and add to PATH.
    pause
    exit /b 1
)

echo Flutter SDK OK.

REM =================================================
REM VERSION MANAGEMENT
REM =================================================
echo Reading current version...

for /f "tokens=2 delims=: " %%a in ('findstr "version:" pubspec.yaml') do set CURRENT_VERSION=%%a

echo Current version: %CURRENT_VERSION%
echo.

set /p NEW_VERSION=Enter new version (Press Enter to keep %CURRENT_VERSION%):

if "%NEW_VERSION%"=="" (
    set NEW_VERSION=%CURRENT_VERSION%
)

echo Using version: %NEW_VERSION%
echo Creating backup pubspec.yaml.backup...
copy /y pubspec.yaml pubspec.yaml.backup >nul

REM Update version using PowerShell
powershell -Command "(Get-Content pubspec.yaml) -replace 'version:.*', 'version: %NEW_VERSION%' | Set-Content pubspec.yaml"

echo Version updated.
findstr "version:" pubspec.yaml
echo.

pause

REM =================================================
REM ANDROID SETUP VERIFICATION
REM =================================================
echo Checking Android setup...

REM Check Java
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Java JDK not found. Install at:
    echo https://adoptium.net/temurin/releases/
    pause
    exit /b 1
)
echo Java OK.

REM Check Android SDK
flutter doctor --android-licenses >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Android SDK not configured.
    echo Check ANDROID_HOME and Android Studio.
    pause
    exit /b 1
)
echo Android SDK OK.

REM =================================================
REM CLEAN AND GET PACKAGES
REM =================================================

echo Cleaning Flutter...
flutter clean

echo Getting dependencies...
flutter pub get

REM =================================================
REM SIGNING SETUP
REM =================================================

if not exist android\app\keystore.jks (
    echo WARNING: Keystore not found at android\app\keystore.jks
    echo.
    echo Create keystore with:
    echo keytool -genkey -v -keystore android\app\keystore.jks ^
    echo   -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 ^
    echo   -alias upload
    echo.
    set /p keystore_confirm=Press Enter after creating keystore...
) else (
    echo Keystore found.
)

REM =================================================
REM ANDROID BUILD
REM =================================================

echo Choose build type:
echo [1] APK (Universal - testing/beta)
echo [2] App Bundle (Google Play - recommended)
echo [3] Split APK (Multiple architectures)
echo.

set /p build_choice=Enter choice (1-3):

if "%build_choice%"=="1" (
    echo Building Universal APK...
    flutter build apk --release
    set build_file=build\app\outputs\flutter-apk\app-release.apk
    set build_desc=Universal APK
) else if "%build_choice%"=="2" (
    echo Building App Bundle for Google Play...
    flutter build appbundle --release
    set build_file=build\app\outputs\bundle\release\app-release.aab
    set build_desc=App Bundle (.aab)
) else if "%build_choice%"=="3" (
    echo Building Split APKs...
    flutter build apk --release --split-per-abi
    set build_file=build\app\outputs\flutter-apk\
    set build_desc=Split APKs (multiple files)
) else (
    echo Invalid choice. Using Universal APK.
    flutter build apk --release
    set build_file=build\app\outputs\flutter-apk\app-release.apk
    set build_desc=Universal APK
)

if %errorlevel% neq 0 (
    echo ERROR: Android build failed!
    echo Check Flutter errors and Android setup.
    pause
    exit /b 1
)

echo Build completed.
echo.

REM =================================================
REM BUILD VERIFICATION
REM =================================================

if "%build_choice%"=="3" (
    if exist build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk (
        echo Split APKs created:
        dir /b build\app\outputs\flutter-apk\*.apk
    ) else (
        echo ERROR: Split APK build failed.
        pause
        exit /b 1
    )
) else (
    if exist "%build_file%" (
        echo Build file created: %build_file%
        for %%A in ("%build_file%") do set file_size=%%~zA
        set /a file_size_mb=file_size/1024/1024
        echo File size: ~%file_size_mb% MB
    ) else (
        echo ERROR: Build file not found.
        pause
        exit /b 1
    )
)

REM =================================================
REM DISTRIBUTION INFO
REM =================================================

if "%build_choice%"=="2" (
    echo READY FOR GOOGLE PLAY STORE:
    echo.
    echo File: %build_file%
    echo.
    echo Upload steps:
    echo 1. Go to Google Play Console
    echo 2. Select JanMat app
    echo 3. Release - Production/Internal/Beta
    echo 4. Create new release
    echo 5. Upload the .aab file
    echo 6. Add release notes
    echo 7. Save and rollout
    echo.
) else (
    echo APK READY FOR DISTRIBUTION:
    echo.
    echo File: %build_file%
    echo.
    echo Distribution options:
    echo 1. Direct install: Transfer to device
    echo 2. ADB install: adb install %build_file%
    echo 3. Beta testing via Firebase
    echo 4. Google Play Store upload
    echo.
)

echo =============================================
echo Android Build Completed Successfully
echo =============================================
echo Build Type: %build_desc%
if not "%build_choice%"=="3" (
    echo Build File: %build_file%
)
echo Version: %NEW_VERSION%
echo For testing: Install on Android device/emulator
echo.

pause
