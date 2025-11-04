@echo off
echo Installing Release APK to Connected Devices
echo ===========================================
echo.

echo Checking connected devices...
adb devices

echo.
echo Installing APK to all connected devices...
echo APK Path: build\app\outputs\flutter-apk\app-release.apk
echo.

adb install -r build\app\outputs\flutter-apk\app-release.apk

echo.
echo Installation complete!
echo.
echo If you have multiple devices and want to install to a specific device,
echo use: adb -s ^<device_id^> install -r build\app\outputs\flutter-apk\app-release.apk
echo.
echo You can find device IDs from the 'adb devices' command output above.
echo.
pause
