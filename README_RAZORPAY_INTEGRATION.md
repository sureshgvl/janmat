# Razorpay Integration Setup Guide

## 🎯 Overview

This guide documents the implementation of Razorpay payment integration for web and Android builds, with separate configurations for testing and production environments.

## 📋 What Was Implemented

### Files Added/Modified:
- ✅ `pubspec.yaml` - Added `js: ^0.6.7` dependency
- ✅ `web/index.html` - Added Razorpay JS SDK script
- ✅ `lib/features/monetization/services/razorpay_web_service.dart` - New web-specific service
- ✅ `lib/features/monetization/services/razorpay_service.dart` - Modified for platform branching
- ✅ `lib/features/monetization/controllers/monetization_controller.dart` - Payment mode configuration

### Platform Support:
- **Web**: ✅ Razorpay JavaScript SDK with `dart:js` interop
- **Android**: ✅ Existing `razorpay_flutter` package (unchanged)
- **iOS**: ✅ Existing `razorpay_flutter` package (ready, not tested)

## 🧪 Test Configuration

**File**: `lib/features/monetization/controllers/monetization_controller.dart`

### Enable Real Payments for Testing:
```dart
// Line ~49: Payment mode toggle
var useMockPayment = false.obs; // Real payments everywhere (for testing)
```

### Verify Test Setup:
- ✅ Razorpay test keys are used: `rzp_test_RJP3bsiM4dz0Aa`
- ✅ No real money charged
- ✅ Test payment IDs start with `pay_test_`

### Test UPI Credentials:
- **Success**: `success@razorpay`
- **Failure**: `failure@razorpay`

### Logging Verification:
Check console for these logs when purchasing:
```
⚠️ WEB: Razorpay web service initialized (JS SDK loaded via HTML)
WEB PAYMENT: Starting Razorpay checkout on web platform
PAYMENT SUCCESS! (or PAYMENT ERROR! for mobile)
✅ WEB PAYMENT SUCCESS!
```

## 🚀 Production Configuration

### Safe Production Setup (Recommended):
```dart
// Line ~49: Payment mode toggle
var useMockPayment = kIsWeb ? false.obs : true.obs;
// Web uses real payments, Android uses mock (safe default)
```

### Full Production Setup (After Testing):
```dart
// Line ~49: Payment mode toggle
var useMockPayment = false.obs; // Real payments everywhere
```

### Production Keys Setup:
Replace test keys with live keys in `razorpay_service.dart`:
```dart
// Change these from test to live keys:
// OLD:
static const String razorpayKeyId = 'rzp_test_RJP3bsiM4dz0Aa';
// NEW:
static const String razorpayKeyId = 'rzp_live_XXXXX'; // Your live key
static const String razorpayKeySecret = 'XXXXX'; // Your live secret
```

## 🔄 Quick Configuration Switch

### Switch to Testing Mode:
```dart
var useMockPayment = false.obs; // Test everything with real payments
```

### Switch to Production Safe Mode:
```dart
var useMockPayment = kIsWeb ? false.obs : true.obs;
```

### Switch to Full Production:
```dart
var useMockPayment = false.obs; // Real payments everywhere
```

## 📱 Platform-Specific Behavior

### Web Build (Flutter Web):
- Uses `RazorpayWebService` with JavaScript SDK
- Always requires internet connection
- Modal opens in browser
- Use `success@razorpay` for UPI testing

### Android Build:
- Uses `razorpay_flutter` package
- Can open native Razorpay app or web view
- Works offline-ready
- Respects Android back button

### iOS Build:
- Uses `razorpay_flutter` package
- Should work same as Android (not yet tested)

## 🔧 Testing Steps

### Web Testing:
1. `flutter run -d chrome --profile`
2. Login → Monetization section → Select plan
3. Check console: `"WEB PAYMENT: Starting Razorpay checkout"`
4. Pay with UPI: `success@razorpay`

### Android Testing:
1. `flutter run` (choose Android)
2. Login → Monetization section → Select plan
3. Check Android Studio logs: `"PAYMENT SUCCESS!"`
4. Pay with UPI: `success@razorpay`

## ⚠️ Important Safety Notes

### Money Handling:
- **Test Environment**: ₹0.01 to ₹1 transactions for safety
- **Production**: Only after thorough testing
- **Refunds**: Keep test amounts refundable

### Key Management:
- Never commit production keys to git
- Use environment variables for sensitive data
- Rotate keys periodically

### User Experience:
- Always show payment amount clearly
- Handle network failures gracefully
- Provide cancellation options
- Log errors for debugging

## 🚨 Troubleshooting

### Web Issues:
- **"Razorpay JS SDK not loaded"**: Check `web/index.html` script tag
- **"International cards not supported"**: Use UPI or domestic cards
- **"USER_CANCELLED"**: User closed payment modal

### Android Issues:
- **"Error starting payment"**: Check `razorpay_flutter` plugin
- **Permission errors**: Verify Android Manifest
- **Crash on payment**: Check ProGuard rules

### Common Issues:
```dart
// Check logs in monetization_controller.dart:
AppLogger.razorpay('Current platform: ${kIsWeb ? "Web" : "Mobile"}');
AppLogger.razorpay('Mock payment mode: ${useMockPayment.value}');
AppLogger.razorpay('Key ID: ${razorpayKeyId.substring(0, 15)}...');
```

## 📊 Log Reference

### Successful Web Payment:
```
⚠️ WEB: Razorpay web service initialized (JS SDK loaded via HTML)
WEB PAYMENT: Starting Razorpay checkout on web platform
✅ Razorpay checkout opened successfully on web
✅ WEB PAYMENT SUCCESS!
Payment ID: pay_test_xxxxxxxxxxxxxxxxxx
```

### Successful Mobile Payment:
```
PAYMENT SUCCESS!
Payment ID: pay_test_xxxxxxxxxxxxxxxxxx
Order ID: order_test_xxx
Signature: xxx
```

## 🎉 Verification Checklist

### After Setup:
- [ ] Web builds work with real payments
- [ ] Android builds work with mock/real payments
- [ ] Test keys return `pay_test_` prefixed IDs
- [ ] UPI `success@razorpay` works
- [ ] Console logs show platform-specific messages
- [ ] Payment completion triggers subscription creation
- [ ] Error handling doesn't crash app

### Production Ready:
- [ ] Live Razorpay keys configured
- [ ] Environment variables used for secrets
- [ ] HTTPS enabled everywhere
- [ ] Webhook endpoints configured in Razorpay dashboard
- [ ] Order creation moved to backend for security
- [ ] Payment signature verification implemented

---

## 📞 Support

For Razorpay dashboard issues:
- Visit: https://dashboard.razorpay.com
- Support: Razorpay customer care

For code issues:
- Check Flutter DevTools → Logging
- Verify API keys match environment
- Test with small amounts first

---

**Last Updated**: November 21, 2025
**Status**: ✅ Web Integration Complete | 🧪 Android Integration Tested
