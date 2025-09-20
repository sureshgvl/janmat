import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../features/monetization/controllers/monetization_controller.dart';

class RazorpayService extends GetxService {
  late Razorpay _razorpay;

  // Razorpay keys - Replace with your actual keys
  static const String razorpayKeyId = 'rzp_test_RJP3bsiM4dz0Aa'; // Test key
  static const String razorpayKeySecret = 'k9tGXewq28ileCC6Nba0PgdT'; // Test secret

  // Production keys (uncomment for production)
  // static const String razorpayKeyId = 'rzp_live_your_key_id';
  // static const String razorpayKeySecret = 'your_key_secret';

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  void _initializeRazorpay() {
    debugPrint('🔧 Initializing Razorpay service...');
    _razorpay = Razorpay();
    debugPrint('✅ Razorpay instance created');

    _setupEventListeners();
    debugPrint('✅ Event listeners setup complete');

    debugPrint('💳 Razorpay service initialized successfully');
    debugPrint('   Test Mode: ${isTestMode()}');
    debugPrint('   Key ID: ${razorpayKeyId.substring(0, 15)}...');
  }

  void _setupEventListeners() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ PAYMENT SUCCESS!');
    debugPrint('   Payment ID: ${response.paymentId}');
    debugPrint('   Order ID: ${response.orderId}');
    debugPrint('   Signature: ${response.signature}');

    Fluttertoast.showToast(
      msg: 'Payment Successful! Payment ID: ${response.paymentId}',
      toastLength: Toast.LENGTH_LONG,
    );

    debugPrint('🔄 Notifying MonetizationController about successful payment...');
    // Notify listeners about successful payment
    Get.find<MonetizationController>().handlePaymentSuccess(response);
    debugPrint('✅ Payment success notification sent to controller');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ PAYMENT ERROR!');
    debugPrint('   Error Code: ${response.code}');
    debugPrint('   Error Message: ${response.message}');
    debugPrint('   Error Data: ${response.toString()}');

    String errorMessage = 'Payment Failed';

    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = 'Payment was cancelled by user';
      debugPrint('   ✅ PAYMENT CANCELLED: User cancelled the payment');
    } else if (response.code == Razorpay.NETWORK_ERROR) {
      errorMessage = 'Network error occurred';
      debugPrint('   Reason: Network connectivity issue');
    } else {
      errorMessage = response.message ?? 'Unknown payment error';
      debugPrint('   Reason: ${response.message ?? 'Unknown error'}');
    }

    debugPrint('🔔 Showing error toast: $errorMessage');
    Fluttertoast.showToast(
      msg: errorMessage,
      toastLength: Toast.LENGTH_LONG,
    );

    debugPrint('🔄 Notifying MonetizationController about payment error...');
    // Notify listeners about payment failure
    Get.find<MonetizationController>().handlePaymentError(response);
    debugPrint('✅ Payment error notification sent to controller');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('💳 External Wallet: ${response.walletName}');
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
    debugPrint('🚀 STARTING RAZORPAY PAYMENT PROCESS');
    debugPrint('   Amount: ₹${amount / 100} (${amount} paisa)');

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
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      debugPrint('🔓 Opening Razorpay checkout...');
      _razorpay.open(options);
      debugPrint('✅ Razorpay checkout opened successfully');
    } catch (e) {
      debugPrint('❌ ERROR STARTING RAZORPAY PAYMENT: $e');
      Fluttertoast.showToast(
        msg: 'Error starting payment: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  // Create order on your backend (placeholder - implement actual API call)
  Future<String?> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    debugPrint('📝 CREATING PAYMENT ORDER');
    debugPrint('   Amount: ₹${amount / 100} (${amount} paisa)');

    try {
      // For test mode, skip order creation to avoid API issues
      debugPrint('⚠️ Test mode: Skipping order creation');
      debugPrint('✅ Using direct payment without order ID');

      // Return null to indicate no order ID (Razorpay will handle this)
      return null;
    } catch (e) {
      debugPrint('❌ ERROR CREATING ORDER: $e');
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

      debugPrint('🔐 Verifying payment: paymentId=$paymentId, orderId=$orderId');

      // For testing, return true
      // In production, verify signature on backend
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
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
      'keyId': razorpayKeyId.substring(0, 10) + '...', // Partial key for security
    };
  }
}
