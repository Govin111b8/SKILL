import 'package:flutter/material.dart';
import 'api_service.dart';

/// Razorpay payment service.
///
/// Integration architecture:
/// 1. Customer taps "Pay via Razorpay"
/// 2. App calls backend POST /payments/create-order → gets Razorpay order_id
/// 3. App opens Razorpay checkout with order_id
/// 4. On success, Razorpay SDK returns payment_id + signature
/// 5. App calls backend POST /payments/verify → backend verifies signature
/// 6. On failure, show error with retry option
///
/// NOTE: Uncomment Razorpay SDK imports when razorpay_flutter is properly configured:
/// import 'package:razorpay_flutter/razorpay_flutter.dart';
class RazorpayService {
  static const _razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: 'rzp_test_placeholder',
  );

  static void Function(String paymentId, String orderId, String signature)? onSuccess;
  static void Function(String message, int code)? onFailure;
  static void Function(String walletName)? onExternalWallet;

  static Future<void> openCheckout({
    required BuildContext context,
    required String bookingId,
    required double amount,
    required String professionalName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final res = await ApiService.post('/payments/create-order', {
        'booking_id': bookingId,
        'amount': amount,
        'currency': 'INR',
      }, auth: true);

      final orderId = res['data']?['order_id']?.toString();
      if (orderId == null) throw Exception('Failed to create payment order');

      if (context.mounted) {
        await _showRazorpayPlaceholder(
          context,
          orderId,
          amount,
          bookingId,
          professionalName,
          customerName,
          customerEmail,
          customerPhone,
        );
      }
    } on ApiException catch (e) {
      onFailure?.call(e.message, e.statusCode);
    } catch (_) {
      onFailure?.call('Payment initialization failed. Please try again.', 0);
    }
  }

  static Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String bookingId,
  }) async {
    try {
      final res = await ApiService.post('/payments/verify', {
        'payment_id': paymentId,
        'order_id': orderId,
        'signature': signature,
        'booking_id': bookingId,
      }, auth: true);
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showRazorpayPlaceholder(
    BuildContext context,
    String orderId,
    double amount,
    String bookingId,
    String professionalName,
    String customerName,
    String customerEmail,
    String customerPhone,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Razorpay Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Merchant key: $_razorpayKey',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Paying $professionalName for booking $bookingId',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'In production, this opens the Razorpay SDK checkout screen for cards, net banking, and wallets.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              'Prefill: $customerName · $customerEmail · $customerPhone',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onFailure?.call('Payment cancelled', 2);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSuccess?.call('pay_test_$orderId', orderId, 'test_signature');
            },
            child: const Text('Simulate Success'),
          ),
        ],
      ),
    );
  }
}
