// Web-specific Razorpay service using JS interop
//dart:js is automatically available on web platform

import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';

class RazorpayWebService {
  // Razorpay keys - Loaded from environment variables for security
  static String get razorpayKeyId {
    // Try environment variable first, fallback to live key for testing
    final key = const String.fromEnvironment('RAZORPAY_KEY_ID',
        defaultValue: 'rzp_live_RjD86XHWEf5MN5');

    // Debug logging (remove in production)
    debugPrint('🌐 Web Razorpay Key ID: ${key.substring(0, 15)}... (${key.startsWith('rzp_live') ? 'PRODUCTION' : 'TEST'})');

    return key;
  }

  static String get razorpayKeySecret {
    // Try environment variable first, fallback to live secret for testing
    final secret = const String.fromEnvironment('RAZORPAY_KEY_SECRET',
        defaultValue: 'S4ZUIZBAVKTUUcy2PVQkuJVX');

    // Debug logging (remove in production)
    debugPrint('🌐 Web Razorpay Secret: ${secret.substring(0, 10)}... (${secret.length > 20 ? 'LOADED' : 'DEFAULT'})');

    return secret;
  }

  // Success and error callbacks for web JS integration
  Function(String paymentId, String orderId, String signature)? _successCallback;
  Function(String errorCode, String errorMessage)? _errorCallback;

  // Initialize Razorpay for web
  void initialize() {
    final now = DateTime.now();
    AppLogger.razorpay('⚠️ WEB: Razorpay web service initialized (JS SDK loaded via HTML) at ${now.toIso8601String()}');
    AppLogger.razorpay('Test Mode: ${isTestMode()}');
    AppLogger.razorpay('Key ID: ${isTestMode() ? razorpayKeyId : razorpayKeyId.substring(0, 15)}...');
    if (isTestMode()) {
      AppLogger.razorpay('🔑 TEST KEY CONFIRMED: Razorpay integration is using test environment');
    }
  }

  // Start payment on web using JS SDK
  void startPayment({
    required int amount, // Amount in paisa
    required String description,
    required String contact,
    required String email,
    String? prefillName,
    Map<String, dynamic>? notes,
    required Function(String, String, String) successCallback,
    required Function(String, String) errorCallback,
  }) {
    AppLogger.razorpay('WEB PAYMENT: Starting Razorpay checkout on web platform');
    AppLogger.razorpay('Amount: ₹${amount / 100} ($amount paisa)');

    // Store callbacks
    _successCallback = successCallback;
    _errorCallback = errorCallback;

    // Verify Razorpay JS SDK is loaded
    if (!js.context.hasProperty('Razorpay')) {
      AppLogger.razorpayError('❌ Razorpay JS SDK not loaded!');
      errorCallback('JS_SDK_NOT_LOADED', 'Razorpay JavaScript SDK not available');
      return;
    }

    // Create options object for Razorpay
    final options = js.JsObject.jsify({
      'key': razorpayKeyId,
      'amount': amount,
      'currency': 'INR',
      'name': 'Janmat',
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
        if (prefillName != null) 'name': prefillName,
      },
      'config': {
        'display': {
          'language': 'en',
          'hide': [
            {'method': 'paylater'},
          ],
          'preferences': {
            'show_default_blocks': true,
          },
        },
      },
      'external': {
        'wallets': ['paytm']
      },
      'handler': _createSuccessHandler(),
      'modal': {
        'confirm_close': true,
        'ondismiss': _createDismissHandler(),
        'animation': true,
      },
      'retry': {
        'enabled': false,
      },
      'timeout': 300, // 5 minutes
      'remember_customer': false,
      'readonly': {
        'email': false,
        'contact': false,
        'name': false,
      },
    });

    try {
      AppLogger.razorpay('Creating Razorpay instance...');

      // Create Razorpay instance
      final razorpayInstance = js.JsObject(js.context['Razorpay'], [options]);

      AppLogger.razorpay('Opening Razorpay checkout...');

      // Open Razorpay checkout
      razorpayInstance.callMethod('open');

      AppLogger.razorpay('✅ Razorpay checkout opened successfully on web');
    } catch (e) {
      AppLogger.razorpayError('❌ ERROR STARTING WEB RAZORPAY PAYMENT: $e');
      errorCallback('INIT_ERROR', e.toString());
    }
  }

  // Create success handler function for JS
  js.JsFunction _createSuccessHandler() {
    return js.JsFunction.withThis((js.JsObject thisArg, js.JsObject response) {
      final now = DateTime.now();
      // Extract payment details from JS response
      final paymentId = response['razorpay_payment_id']?.toString() ?? '';
      final orderId = response['razorpay_order_id']?.toString() ?? '';
      final signature = response['razorpay_signature']?.toString() ?? '';

      AppLogger.razorpay('✅ WEB PAYMENT SUCCESS at ${now.toIso8601String()}!');
      AppLogger.razorpay('Payment ID: $paymentId');
      AppLogger.razorpay('Order ID: $orderId');
      AppLogger.razorpay('Signature: $signature');

      if (isTestMode()) {
        AppLogger.razorpay('🔍 TEST PAYMENT VALIDATION: ${paymentId.startsWith('pay_test_') ? '✅ Valid test payment' : '⚠️ Unexpected payment format'}');
      }

      // Call the stored success callback
      if (_successCallback != null) {
        _successCallback!(paymentId, orderId, signature);
      }
    });
  }

  // Create dismiss handler for when user closes modal
  js.JsFunction _createDismissHandler() {
    return js.JsFunction.withThis((js.JsObject thisArg) {
      AppLogger.razorpay('⚠️ User dismissed Razorpay modal');
      if (_errorCallback != null) {
        _errorCallback!('USER_CANCELLED', 'Payment was cancelled by user');
      }
    });
  }

  // Create order - For web, we can still create order on backend if needed
  Future<String?> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    AppLogger.razorpay('📝 CREATING PAYMENT ORDER (Web)');
    AppLogger.razorpay('Amount: ₹${amount / 100} ($amount paisa)');

    // For web test mode, create a mock order ID
    // In production, this should be created on backend
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderId = 'order_web_$timestamp';

    AppLogger.razorpay('✅ Mock order created for web: $orderId');
    return orderId;
  }

  // Verify payment signature
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      // TODO: Implement payment verification on backend
      AppLogger.razorpay('Verifying payment (web): paymentId=$paymentId, orderId=$orderId');

      // For testing, return true
      return true;
    } catch (e) {
      AppLogger.razorpayError('Error verifying web payment: $e');
      return false;
    }
  }

  // Check if using test keys
  bool isTestMode() {
    return razorpayKeyId.contains('test');
  }

  // Handle modal close (automatic dismissal detection)
  // Note: Razorpay web doesn't have explicit close callbacks like mobile
  // The dismiss handler above handles user-initiated closes
}
