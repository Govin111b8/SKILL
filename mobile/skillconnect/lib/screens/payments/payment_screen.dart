import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// UPI-first payment screen.
/// Lightweight UPI intent flow (no webview needed).
/// Supports UPI apps like GPay, PhonePe, Paytm.
class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String currency;
  final String professionalName;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    this.currency = 'INR',
    required this.professionalName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'upi';
  bool _processing = false;
  bool _success = false;
  String? _error;

  Future<void> _initiatePayment() async {
    setState(() { _processing = true; _error = null; });
    try {
      final res = await ApiService.post('/payments/initiate', {
        'booking_id': widget.bookingId,
        'amount': widget.amount,
        'currency': widget.currency,
        'method': _selectedMethod,
      }, auth: true);

      // For UPI, the backend returns a UPI deep link / intent URL
      final paymentId = res['data']?['payment_id'];
      if (paymentId != null) {
        // In production, launch UPI intent here
        // For now, confirm payment
        await _confirmPayment(paymentId.toString());
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Payment failed. Please try again.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _confirmPayment(String paymentId) async {
    try {
      await ApiService.post('/payments/$paymentId/confirm', {}, auth: true);
      setState(() => _success = true);
    } catch (_) {
      setState(() => _error = 'Payment confirmation failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Amount to Pay', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'to ${widget.professionalName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment methods
            Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _PaymentOption(
              icon: Icons.account_balance,
              label: 'UPI (GPay / PhonePe / Paytm)',
              subtitle: 'Recommended — Instant',
              selected: _selectedMethod == 'upi',
              onTap: () => setState(() => _selectedMethod = 'upi'),
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              icon: Icons.money,
              label: 'Cash on Service',
              subtitle: 'Pay after job is done',
              selected: _selectedMethod == 'cash',
              onTap: () => setState(() => _selectedMethod = 'cash'),
            ),
            const Spacer(),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
              ),

            FilledButton(
              onPressed: _processing ? null : _initiatePayment,
              child: _processing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_selectedMethod == 'cash' ? 'Confirm Cash Payment' : 'Pay ₹${widget.amount.toStringAsFixed(0)} via UPI'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
            const SizedBox(height: 16),
            Text('Payment Successful! ✅', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('₹${widget.amount.toStringAsFixed(0)} paid to ${widget.professionalName}'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Theme.of(context).colorScheme.primary.withAlpha(15) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: selected ? Theme.of(context).colorScheme.primary : null)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
