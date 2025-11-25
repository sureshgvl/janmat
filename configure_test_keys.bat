@echo off
echo Configuring Firebase Functions for TEST environment...
echo.

echo Setting Razorpay TEST keys...
firebase functions:config:set razorpay.key_id="rzp_test_RiMWsU7GNxKFqz"
firebase functions:config:set razorpay.key_secret="cThh9upiy1NtnaHdO6cWr99I"
firebase functions:config:set razorpay.webhook_secret="wh_sec_mySecretKey123"

echo.
echo Deploying Firebase Functions with TEST keys...
firebase deploy --only functions

echo.
echo TEST environment configured successfully!
echo Razorpay Key ID: rzp_test_RiMWsU7GNxKFqz
echo Webhook URL: https://us-central1-janmat-8e831.cloudfunctions.net/razorpayWebhook
echo.
echo Next steps:
echo 1. Update .env file with test keys
echo 2. Build APK: flutter build apk --dart-define-from-file=.env --release
echo 3. Install APK: adb install build/app/outputs/flutter-apk/app-release.apk
echo 4. Test payments with test UPI ID: success@razorpay
pause