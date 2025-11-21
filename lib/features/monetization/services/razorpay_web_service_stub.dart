// Stub implementation for non-web platforms (mobile)
class RazorpayWebService {
  // Empty implementation for platforms that don't support dart:js
  void initialize() {}

  void startPayment({
    required int amount,
    required String description,
    required String contact,
    required String email,
    String? prefillName,
    Map<String, dynamic>? notes,
    required Function(String paymentId, String orderId, String signature) successCallback,
    required Function(String errorCode, String errorMessage) errorCallback,
  }) {
    // No-op on non-web platforms - this should never be called
    errorCallback('PLATFORM_NOT_SUPPORTED', 'Web payments not available on this platform');
  }

  Future<String?> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    return null;
  }

  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    return false;
  }

  bool isTestMode() => true;
}
