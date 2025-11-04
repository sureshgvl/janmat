@echo off
echo Wireless ADB Setup Instructions:
echo ================================
echo 1. Connect your Android devices via USB
echo 2. Enable Developer Options and USB Debugging on each device
echo 3. Run: adb devices (to verify USB connection)
echo.
echo Press any key when devices are connected via USB...
pause > nul

echo.
echo 4. Enabling wireless debugging on connected devices...
adb tcpip 5555

echo.
echo 5. Now disconnect the USB cables from your devices
echo 6. Find device IP addresses from: Settings > About > Status > IP Address
echo.
echo Press any key after disconnecting USB and noting IP addresses...
pause > nul

echo.
echo 7. Connect wirelessly using: adb connect ^<device_ip^>:5555
echo    Example: adb connect 192.168.1.100:5555
echo.
echo Run the above command for each device, replacing ^<device_ip^> with actual IP
echo Then run: adb devices (to verify wireless connection)
echo.
echo Press any key to check connected devices...
pause > nul

adb devices

echo.
echo If devices are connected wirelessly, you can now install the APK
echo Run: adb install -r build\app\outputs\flutter-apk\app-release.apk
echo Or run this script for each device: install_release_apk.bat
