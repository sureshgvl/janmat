import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransaction {
  final String id;
  final String paymentId; // Razorpay payment ID
  final String orderId; // Razorpay order ID
  final String signature; // Razorpay signature
  final String userId;
  final String planId;
  final String planName;
  final String planType;
  final int amountPaid; // in paisa (divide by 100 for rupees)
  final String currency;
  final String status; // 'success', 'failed', 'pending'
  final DateTime paymentDate;
  final String? electionType;
  final int? validityDays;
  final String? failureReason;
  final String paymentMethod; // 'razorpay'
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.paymentId,
    required this.orderId,
    required this.signature,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.planType,
    required this.amountPaid,
    required this.currency,
    required this.status,
    required this.paymentDate,
    this.electionType,
    this.validityDays,
    this.failureReason,
    required this.paymentMethod,
    this.metadata,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    DateTime paymentDate;
    if (json['paymentDate'] is Timestamp) {
      paymentDate = (json['paymentDate'] as Timestamp).toDate();
    } else if (json['paymentDate'] is String) {
      paymentDate = DateTime.parse(json['paymentDate']);
    } else {
      paymentDate = DateTime.now();
    }

    return PaymentTransaction(
      id: json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      orderId: json['orderId'] ?? '',
      signature: json['signature'] ?? '',
      userId: json['userId'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      planType: json['planType'] ?? '',
      amountPaid: json['amountPaid'] ?? 0,
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? 'pending',
      paymentDate: paymentDate,
      electionType: json['electionType'],
      validityDays: json['validityDays'],
      failureReason: json['failureReason'],
      paymentMethod: json['paymentMethod'] ?? 'razorpay',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'planType': planType,
      'amountPaid': amountPaid,
      'currency': currency,
      'status': status,
      'paymentDate': paymentDate.toIso8601String(),
      'electionType': electionType,
      'validityDays': validityDays,
      'failureReason': failureReason,
      'paymentMethod': paymentMethod,
      'metadata': metadata,
    };
  }

  double get amountInRupees => amountPaid / 100;

  String get displayAmount => '₹${amountInRupees.toStringAsFixed(2)}';
}
