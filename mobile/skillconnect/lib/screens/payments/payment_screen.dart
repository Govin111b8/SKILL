import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/razorpay_service.dart';

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

  Future<bool> _launchUpiIntent(String upiUrl) async {
    final uri = Uri.parse(upiUrl);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      if (_selectedMethod == 'upi') {
        final res = await ApiService.post('/payments/initiate', {
          'booking_id': widget.bookingId,
          'amount': widget.amount,
          'currency': widget.currency,
          'method': 'upi',
        }, auth: true);

        final data = res['data'] as Map<String, dynamic>? ?? {};
        final upiUrl = data['upi_url']?.toString();
        final paymentRef = data['payment_ref']?.toString() ??
            data['payment_id']?.toString() ??
            widget.bookingId;

        if (upiUrl != null && upiUrl.isNotEmpty) {
          final launched = await _launchUpiIntent(upiUrl);
          if (!launched && mounted) {
            await _showManualUpiDialog(paymentRef);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('UPI app opened. Complete the payment there.'),
              ),
            );
          }
        } else if (mounted) {
          await _showManualUpiDialog(paymentRef);
        }
      } else if (_selectedMethod == 'razorpay') {
        final auth = context.read<AuthService>();
        final user = auth.user ?? const <String, dynamic>{};

        RazorpayService.onSuccess = (paymentId, orderId, signature) async {
          final verified = await RazorpayService.verifyPayment(
            paymentId: paymentId,
            orderId: orderId,
            signature: signature,
            bookingId: widget.bookingId,
          );
          if (!mounted) return;
          setState(() {
            _processing = false;
            _success = verified;
            _error = verified ? null : 'Payment verification failed. Please contact support.';
          });
        };
        RazorpayService.onFailure = (message, _) {
          if (!mounted) return;
          setState(() {
            _processing = false;
            _error = message;
          });
        };
        RazorpayService.onExternalWallet = (walletName) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Continuing with $walletName...')),
          );
        };

        await RazorpayService.openCheckout(
          context: context,
          bookingId: widget.bookingId,
          amount: widget.amount,
          professionalName: widget.professionalName,
          customerName: user['name']?.toString() ?? 'SkillConnect Customer',
          customerEmail: user['email']?.toString() ?? 'customer@skillconnect.in',
          customerPhone: user['phone']?.toString() ?? '',
        );
      } else {
        await ApiService.post('/payments/initiate', {
          'booking_id': widget.bookingId,
          'amount': widget.amount,
          'currency': widget.currency,
          'method': 'cash',
        }, auth: true);
        if (!mounted) return;
        setState(() => _success = true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Payment failed. Please try again.';
      });
    } finally {
      if (mounted && _selectedMethod != 'razorpay') {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _showManualUpiDialog(String paymentRef) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay via UPI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No UPI app found. Please open your UPI app manually and pay to:'),
            const SizedBox(height: 12),
            const SelectableText(
              'skillconnect@upi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reference: $paymentRef',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: paymentRef));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Payment reference copied')),
                );
              }
            },
            child: const Text('Copy Ref'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _confirmPayment(paymentRef);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('I have paid'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment(String paymentId) async {
    try {
      await ApiService.post('/payments/$paymentId/confirm', {}, auth: true);
      if (!mounted) return;
      setState(() => _success = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Payment confirmation failed.');
    }
  }

  String get _payButtonLabel {
    if (_selectedMethod == 'cash') return 'Confirm Cash Payment';
    if (_selectedMethod == 'razorpay') {
      return 'Pay ₹${widget.amount.toStringAsFixed(0)} with Razorpay';
    }
    return 'Pay ₹${widget.amount.toStringAsFixed(0)} via UPI';
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
              icon: Icons.credit_card_rounded,
              label: 'Razorpay (Cards/Net Banking)',
              subtitle: 'Cards, UPI, wallets, and net banking',
              selected: _selectedMethod == 'razorpay',
              onTap: () => setState(() => _selectedMethod = 'razorpay'),
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
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_payButtonLabel),
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
