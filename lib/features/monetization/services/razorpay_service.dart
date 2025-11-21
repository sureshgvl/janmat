import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import '../controllers/monetization_controller.dart';
import '../../../utils/app_logger.dart';

// Conditional import for web service - uses stub on non-web platforms
import 'razorpay_web_service_stub.dart' if (dart.library.html) 'razorpay_web_service.dart';

class RazorpayService extends GetxService {
  late Razorpay _razorpay;
  RazorpayWebService? _webService;

  // Razorpay keys - Replace with your actual keys
  static const String razorpayKeyId = 'rzp_test_RJP3bsiM4dz0Aa'; // Test key
  static const String razorpayKeySecret = 'k9tGXewq28ileCC6Nba0PgdT'; // Test secret

  // Production keys (uncomment for production)
  // static const String razorpayKeyId = 'rzp_live_your_key_id';
  // static const String razorpayKeySecret = 'your_key_secret';

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
    AppLogger.razorpay('Initializing Razorpay service...');
    _razorpay = Razorpay();
    AppLogger.razorpay('Razorpay instance created');

    _setupEventListeners();
    AppLogger.razorpay('Event listeners setup complete');

    AppLogger.razorpay('Razorpay service initialized successfully');
    AppLogger.razorpay('Test Mode: ${isTestMode()}');
    AppLogger.razorpay('Key ID: ${razorpayKeyId.substring(0, 15)}...');
  }

  void _setupEventListeners() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    AppLogger.razorpay('PAYMENT SUCCESS!');
    AppLogger.razorpay('Payment ID: ${response.paymentId}');
    AppLogger.razorpay('Order ID: ${response.orderId}');
    AppLogger.razorpay('Signature: ${response.signature}');

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
    AppLogger.razorpayError('PAYMENT ERROR!');
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
    AppLogger.razorpay('STARTING RAZORPAY PAYMENT PROCESS (Mobile)');
    AppLogger.razorpay('Amount: ₹${amount / 100} ($amount paisa)');

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
      successCallback: (String paymentId, String orderId, String signature) {
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

  // Create order on your backend (placeholder - implement actual API call)
  Future<String?> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
   AppLogger.razorpay('CREATING PAYMENT ORDER');
   AppLogger.razorpay('Amount: ₹${amount / 100} ($amount paisa)');

   try {
     // For test mode, skip order creation to avoid API issues
     AppLogger.razorpay('Test mode: Skipping order creation');
     AppLogger.razorpay('Using direct payment without order ID');

     // Return null to indicate no order ID (Razorpay will handle this)
     return null;
   } catch (e) {
     AppLogger.razorpayError('ERROR CREATING ORDER: $e');
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
