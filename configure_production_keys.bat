@echo off
echo Configuring Firebase Functions for PRODUCTION environment...
echo.

echo Setting Razorpay PRODUCTION keys...
firebase functions:config:set razorpay.key_id="rzp_live_RjD86XHWEf5MN5"
firebase functions:config:set razorpay.key_secret="S4ZUIZBAVKTUUcy2PVQkuJVX"
firebase functions:config:set razorpay.webhook_secret="wh_sec_mySecretKey123"

echo.
echo Deploying Firebase Functions with PRODUCTION keys...
firebase deploy --only functions

echo.
echo PRODUCTION environment configured successfully!
echo Razorpay Key ID: rzp_live_RjD86XHWEf5MN5
echo Webhook URL: https://us-central1-janmat-8e831.cloudfunctions.net/razorpayWebhook
echo.
echo WARNING: This is PRODUCTION - Real money will be charged!
echo.
echo Next steps:
echo 1. Update .env file with production keys
echo 2. Build APK: flutter build apk --dart-define-from-file=.env --release
echo 3. Install APK: adb install build/app/outputs/flutter-apk/app-release.apk
echo 4. Test with small amounts first!
pause