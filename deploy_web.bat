@echo off
REM =================================================
REM JANMAT WEB DEPLOYMENT SCRIPT
REM Version: 1.0.3+6
REM Last Updated: November 29, 2025
REM =================================================

echo =============================================
echo Starting JanMat Web Deployment...
echo =============================================
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH.
    echo Install Flutter from: https://flutter.dev
    pause
    exit /b 1
)
echo Flutter OK.

where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found.
    echo Install with: npm install -g firebase-tools
    pause
    exit /b 1
)
echo Firebase OK.
echo.

REM =================================================
REM VERSION MANAGEMENT
REM =================================================

echo Reading current version from pubspec.yaml...
for /f "tokens=2 delims=: " %%a in ('findstr "version:" pubspec.yaml') do set CURRENT_VERSION=%%a
echo Current version: %CURRENT_VERSION%
echo.

set /p NEW_VERSION=Enter new version (Press Enter to keep %CURRENT_VERSION%):
if "%NEW_VERSION%"=="" set NEW_VERSION=%CURRENT_VERSION%
echo Using version: %NEW_VERSION%

echo Creating backup...
copy /y pubspec.yaml pubspec.yaml.backup >nul

echo Updating version in pubspec.yaml...
powershell -Command "(Get-Content pubspec.yaml) -replace 'version:.*', 'version: %NEW_VERSION%' | Set-Content pubspec.yaml"
echo Version updated.
echo.
echo Please wait... Proceeding to clean and build...
timeout /t 2 >nul

REM =================================================
REM CLEAN & BUILD
REM =================================================

echo Preparing environment...
echo Clearing VS Code Flutter arguments...

REM Completely isolate Flutter environment
setlocal enabledelayedexpansion

REM Clear Flutter environment variables
set "DART_FLUTTER_ADDITIONAL_ARGS="
set "DART_FLUTTER_RUN_ADDITIONAL_ARGS="
set "FLUTTER_ROOT="
set "FLUTTER_IMPELLER="

echo Environment cleared. Starting Flutter cleaning...

echo Running: flutter --no-version-check clean
flutter --no-version-check clean
if %errorlevel% neq 0 (
    echo WARNING: Flutter clean failed, continuing anyway...
)
echo Clean completed.

echo Running: flutter --no-version-check pub get
flutter --no-version-check pub get
if %errorlevel% neq 0 (
    echo ERROR: Dependencies failed!
    pause
    exit /b 1
)
echo Dependencies OK.

endlocal

echo Running: flutter build web --release --no-wasm-dry-run
flutter build web --release --no-wasm-dry-run
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo Build completed.

REM =================================================
REM DEPLOYMENT
REM =================================================

echo Deploying to Firebase Hosting...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ERROR: Deployment failed!
    pause
    exit /b 1
)
echo Deployment successful!

REM =================================================
REM SUMMARY
REM =================================================

echo =============================================
echo DEPLOYMENT COMPLETE!
echo =============================================
echo Hosting URL: https://janmat-official.web.app
echo Version deployed: %NEW_VERSION%
echo.

pause
