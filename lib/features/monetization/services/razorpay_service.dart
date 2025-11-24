import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../controllers/monetization_controller.dart';
import '../../../utils/app_logger.dart';

// Conditional import for web service - uses stub on non-web platforms
import 'razorpay_web_service_stub.dart' if (dart.library.html) 'razorpay_web_service.dart';

class RazorpayService extends GetxService {
  late Razorpay _razorpay;
  RazorpayWebService? _webService;

  // Razorpay keys - Replace with your actual keys
  static const String razorpayKeyId = 'rzp_test_RiMWsU7GNxKFqz'; // Test key
  static const String razorpayKeySecret = 'cThh9upiy1NtnaHdO6cWr99I'; // Test secret

  // // Production keys (uncomment for production)
  // static const String razorpayKeyId = 'rzp_live_RjD86XHWEf5MN5';
  // static const String razorpayKeySecret = 'S4ZUIZBAVKTUUcy2PVQkuJVX';

  @override
  void onInit() {
    super.onInit();
    if (kIsWeb) {
      _webService = RazorpayWebService();
      _webService?.initialize();
    } else {
      _initializeRazorpay();
    }
  }

  @override
  void onClose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.onClose();
  }

  void _initializeRazorpay() {
    final now = DateTime.now();
    AppLogger.razorpay('Initializing Razorpay service at ${now.toIso8601String()}...');
    _razorpay = Razorpay();
    AppLogger.razorpay('Razorpay instance created');

    _setupEventListeners();
    AppLogger.razorpay('Event listeners setup complete');

    AppLogger.razorpay('Razorpay service initialized successfully');
    AppLogger.razorpay('Test Mode: ${isTestMode()}');
    AppLogger.razorpay('Key ID: ${isTestMode() ? razorpayKeyId : razorpayKeyId.substring(0, 15)}...');
    if (isTestMode()) {
      AppLogger.razorpay('🔑 TEST KEY CONFIRMED: Razorpay integration is using test environment');
      AppLogger.razorpay('💳 TEST PAYMENT METHODS ENABLED: UPI (Google Pay/PhonePe), Cards, Net Banking, Wallets');
      AppLogger.razorpay('📱 For Google Pay testing: Use UPI ID "success@razorpay" for successful test payments');
    }
  }

  void _setupEventListeners() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final now = DateTime.now();
    AppLogger.razorpay('PAYMENT SUCCESS at ${now.toIso8601String()}!');
    AppLogger.razorpay('Payment ID: ${response.paymentId}');
    AppLogger.razorpay('Order ID: ${response.orderId}');
    AppLogger.razorpay('Signature: ${response.signature}');

    if (isTestMode()) {
      AppLogger.razorpay('🔍 TEST PAYMENT VALIDATION: ${response.paymentId?.startsWith('pay_test_') == true ? '✅ Valid test payment' : '⚠️ Unexpected payment format'}');
    }

    Fluttertoast.showToast(
      msg: 'Payment Successful! Payment ID: ${response.paymentId}',
      toastLength: Toast.LENGTH_LONG,
    );

    AppLogger.razorpay('Notifying MonetizationController about successful payment...');
    // Notify listeners about successful payment
    Get.find<MonetizationController>().handlePaymentSuccess(response);
    AppLogger.razorpay('Payment success notification sent to controller');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final now = DateTime.now();
    AppLogger.razorpayError('PAYMENT ERROR at ${now.toIso8601String()}!');

    if (isTestMode()) {
      AppLogger.razorpay('🔍 TEST MODE: Payment error occurred while using test key');
    }

    AppLogger.razorpayError('Error Code: ${response.code}');
    AppLogger.razorpayError('Error Message: ${response.message}');
    AppLogger.razorpayError('Error Data: ${response.toString()}');

    String errorMessage = 'Payment Failed';

    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = 'Payment was cancelled by user';
      AppLogger.razorpay('PAYMENT CANCELLED: User cancelled the payment');
    } else if (response.code == Razorpay.NETWORK_ERROR) {
      errorMessage = 'Network error occurred';
      AppLogger.razorpayError('Reason: Network connectivity issue');
    } else {
      errorMessage = response.message ?? 'Unknown payment error';
      AppLogger.razorpayError('Reason: ${response.message ?? 'Unknown error'}');
    }

    AppLogger.razorpay('Showing error toast: $errorMessage');
    Fluttertoast.showToast(
      msg: errorMessage,
      toastLength: Toast.LENGTH_LONG,
    );

    AppLogger.razorpay('Notifying MonetizationController about payment error...');
    // Notify listeners about payment failure
    Get.find<MonetizationController>().handlePaymentError(response);
    AppLogger.razorpay('Payment error notification sent to controller');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.razorpay('External Wallet: ${response.walletName}');
    Fluttertoast.showToast(
      msg: 'Redirecting to ${response.walletName}',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void startPayment({
    String? orderId,
    required int amount, // Amount in paisa (1 INR = 100 paisa)
    required String description,
    required String contact,
    required String email,
    String? prefillName,
    Map<String, dynamic>? notes,
  }) {
    if (kIsWeb) {
      _startWebPayment(amount, description, contact, email, prefillName);
    } else {
      _startMobilePayment(amount, description, contact, email, prefillName);
    }
  }

  void _startMobilePayment(
    int amount,
    String description,
    String contact,
    String email,
    String? prefillName,
  ) {
    final now = DateTime.now();
    AppLogger.razorpay('STARTING RAZORPAY PAYMENT PROCESS (Mobile) at ${now.toIso8601String()}');
    AppLogger.razorpay('Amount: ₹${amount / 100} ($amount paisa)');
    AppLogger.razorpay('Test Mode Active: ${isTestMode()}');

    // Get the stored orderId from the MonetizationController if available
    final monetizationController = Get.find<MonetizationController>();
    final paymentData = monetizationController.getLastPaymentData();
    final orderId = paymentData?['orderId'];

    var options = {
      'key': razorpayKeyId,
      'amount': amount,
      'name': 'Janmat',
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
        if (prefillName != null) 'name': prefillName,
      },
      'method': {
        'upi': true,  // Enable UPI for Google Pay, PhonePe, etc.
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    // Add order_id to options if we have one (this enables auto-capture via webhooks)
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
      AppLogger.razorpay('✅ Including order_id in payment: $orderId');
    } else {
      AppLogger.razorpay('⚠️ No order_id available - payment will be authorized only');
    }

    try {
      AppLogger.razorpay('Opening Razorpay checkout...');
      _razorpay.open(options);
      AppLogger.razorpay('Razorpay checkout opened successfully');
    } catch (e) {
      AppLogger.razorpayError('ERROR STARTING RAZORPAY PAYMENT: $e');
      Fluttertoast.showToast(
        msg: 'Error starting payment: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _startWebPayment(
    int amount,
    String description,
    String contact,
    String email,
    String? prefillName,
  ) {
    if (_webService == null) return;

    _webService!.startPayment(
      amount: amount,
      description: description,
      contact: contact,
      email: email,
      prefillName: prefillName,
      successCallback: (String paymentId, String orderIdParam, String signature) {
        // For web, create an orderId that includes the planId if available from notes
        // First check if we have stored payment data from the controller
        final monetizationController = Get.find<MonetizationController>();
        final paymentData = monetizationController.getLastPaymentData();

        String orderId = orderIdParam;
        if (paymentData != null) {
          // Reconstruct orderId with plan data for consistency
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          orderId = 'order_${paymentData['planId']}_${paymentData['electionType'] ?? ''}_${paymentData['validityDays'] ?? 0}_$timestamp';
        }

        // Create a response object compatible with mobile handlers
        PaymentSuccessResponse response = PaymentSuccessResponse.fromMap({
          'paymentId': paymentId,
          'orderId': orderId,
          'signature': signature,
        });
        _handlePaymentSuccess(response);
      },
      errorCallback: (String errorCode, String errorMessage) {
        // Create a response object compatible with mobile handlers
        PaymentFailureResponse response = PaymentFailureResponse.fromMap({
          'code': int.tryParse(errorCode) ?? Razorpay.NETWORK_ERROR,
          'message': errorMessage,
        });
        _handlePaymentError(response);
      },
    );
  }

  // Create order using Firebase Functions
  Future<String?> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    AppLogger.razorpay('CREATING PAYMENT ORDER VIA FIREBASE FUNCTIONS');
    AppLogger.razorpay('Amount: ₹${amount / 100} ($amount paisa)');

    try {
      // For web, we'll handle this differently - no server-side order creation
      if (kIsWeb) {
        AppLogger.razorpay('Web platform: Using direct Razorpay (no server-side order creation)');
        return null;
      }

      final functions = FirebaseFunctions.instance;

      AppLogger.razorpay('Calling createRazorpayOrder Firebase Function...');

      final result = await functions
          .httpsCallable('createRazorpayOrder')
          .call({
            'amount': amount,
            'currency': currency,
            'receipt': receipt,
            'notes': notes,
            'payment_capture': 0, // Manual capture, will be done via webhook
          });

      if (result.data['success'] == true) {
        final orderId = result.data['order']['id'];
        AppLogger.razorpay('✅ Order created successfully: $orderId');
        return orderId;
      } else {
        AppLogger.razorpayError('❌ Order creation failed: ${result.data}');
        return null;
      }
    } catch (error) {
      AppLogger.razorpayError('ERROR CREATING ORDER VIA FIREBASE: $error');

      // Fallback to null for web or if Firebase Functions fail
      AppLogger.razorpay('Falling back to direct payment without order ID');
      return null;
    }
  }

  // Verify payment signature (implement on backend)
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
   try {
     // TODO: Implement payment verification
     // This should be done on your backend for security

     AppLogger.razorpay('Verifying payment: paymentId=$paymentId, orderId=$orderId');

     // For testing, return true
     // In production, verify signature on backend
     return true;
   } catch (e) {
     AppLogger.razorpayError('Error verifying payment: $e');
     return false;
   }
 }

  // Check if using test keys
  bool isTestMode() {
    return razorpayKeyId.contains('test');
  }

  // Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': true,
      'testMode': isTestMode(),
      'keyId': '${razorpayKeyId.substring(0, 10)}...', // Partial key for security
    };
  }
}
