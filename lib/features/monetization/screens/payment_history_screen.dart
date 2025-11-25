import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../../../core/app_theme.dart';
import '../../../utils/snackbar_utils.dart';
import '../controllers/monetization_controller.dart';
import '../widgets/payment_history_section.dart';
import '../../common/loading_overlay.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late MonetizationController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    AppLogger.monetization('📱 PaymentHistoryScreen: initState called');
    _controller = Get.find<MonetizationController>();
    // Delay loading significantly to ensure no build conflicts
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadPaymentHistory();
      }
    });
  }

  Future<void> _loadPaymentHistory() async {
    try {
      AppLogger.monetization('🔄 PaymentHistoryScreen: Loading payment history...');
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        AppLogger.monetization('👤 User found: ${currentUser.uid}');
        await _controller.loadUserPaymentHistory(currentUser.uid);
        AppLogger.monetization('✅ Payment history loaded successfully');
      } else {
        AppLogger.monetization('❌ No authenticated user found');
        SnackbarUtils.showError('Please login to view payment history');
        Get.back();
      }
    } catch (e) {
      AppLogger.monetization('❌ Error loading payment history: $e');
      SnackbarUtils.showError('Failed to load payment history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadPaymentHistory,
          ),
        ],
      ),
      backgroundColor: AppTheme.homeBackgroundColor,
      body: LoadingOverlay(
        isLoading: _controller.isLoading.value,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header info
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Payment History',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View all your purchases and payment transactions',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Payment History Section
              PaymentHistorySection(),
            ],
          ),
        ),
      ),
    );
  }
}
