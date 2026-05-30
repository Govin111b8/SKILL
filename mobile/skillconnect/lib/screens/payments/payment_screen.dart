import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/razorpay_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: [
                    _TopActionButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.surfaceDark,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.accent, Color(0xFF312E81)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: AppShadows.xl(AppColors.primary.withAlpha(160)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(24),
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: Colors.white.withAlpha(40)),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                                ),
                                const Spacer(),
                                const PremiumStatChip(
                                  label: 'Secure checkout',
                                  icon: Icons.verified_user_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              '₹${widget.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Paying ${widget.professionalName}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: const [
                                Expanded(
                                  child: _HeroDetail(
                                    label: 'Currency',
                                    value: 'INR',
                                    icon: Icons.currency_rupee_rounded,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _HeroDetail(
                                    label: 'Speed',
                                    value: 'Instant',
                                    icon: Icons.flash_on_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const PremiumSectionTitle(
                        title: 'Choose payment method',
                        subtitle: 'Designed for fast, trusted Indian payments.',
                      ),
                      _PaymentOption(
                        icon: Icons.qr_code_2_rounded,
                        label: 'UPI (GPay / PhonePe / Paytm)',
                        subtitle: 'Recommended — instant and seamless',
                        selected: _selectedMethod == 'upi',
                        onTap: () => setState(() => _selectedMethod = 'upi'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PaymentOption(
                        icon: Icons.credit_card_rounded,
                        label: 'Razorpay (Cards / Net Banking)',
                        subtitle: 'Cards, UPI, wallets, and net banking',
                        selected: _selectedMethod == 'razorpay',
                        onTap: () => setState(() => _selectedMethod = 'razorpay'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PaymentOption(
                        icon: Icons.payments_outlined,
                        label: 'Cash on Service',
                        subtitle: 'Pay after the job is completed',
                        selected: _selectedMethod == 'cash',
                        onTap: () => setState(() => _selectedMethod = 'cash'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PremiumGlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(18),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: const Icon(Icons.lock_rounded, color: AppColors.success),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              child: Text(
                                'Your payment is protected with secure verification and trusted checkout flows.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        PremiumGlassCard(
                          gradient: [AppColors.error.withAlpha(28), Colors.white.withAlpha(220)],
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _processing ? null : _initiatePayment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: AppShadows.lg(AppColors.primary),
                        ),
                        child: Center(
                          child: _processing
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                )
                              : Text(
                                  _payButtonLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        colors: const [Color(0xFFF7FAFF), Color(0xFFEFFCF6), Color(0xFFF3F1FF)],
        child: SafeArea(
          child: Stack(
            children: [
              ...List.generate(
                14,
                (index) {
                  final left = 18.0 + (index * 23.0) % 320;
                  final top = 32.0 + (index * 41.0) % 420;
                  final size = 8.0 + (index % 4) * 6.0;
                  final colors = [
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.success,
                    AppColors.warning,
                  ];
                  return Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length].withAlpha(90),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: PremiumGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.successGradient),
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.xl(AppColors.success),
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Text(
                          'Payment Successful',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.surfaceDark,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '₹${widget.amount.toStringAsFixed(0)} paid to ${widget.professionalName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: const [
                            Expanded(
                              child: _SuccessMetric(label: 'Status', value: 'Confirmed'),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _SuccessMetric(label: 'Mode', value: 'Secure'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        SizedBox(
                          width: double.infinity,
                          child: PremiumGradientButton(
                            label: 'Done',
                            icon: Icons.arrow_forward_rounded,
                            colors: AppColors.successGradient,
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(210),
          shape: BoxShape.circle,
          boxShadow: AppShadows.sm(AppColors.primary.withAlpha(60)),
        ),
        child: Icon(icon, color: AppColors.surfaceDark, size: 18),
      ),
    );
  }
}

class _HeroDetail extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroDetail({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withAlpha(185), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SuccessMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.surfaceDark)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [AppColors.primary.withAlpha(24), AppColors.accent.withAlpha(16)],
                )
              : LinearGradient(
                  colors: [Colors.white.withAlpha(220), Colors.white.withAlpha(180)],
                ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: selected ? AppColors.primary.withAlpha(140) : Colors.white.withAlpha(180),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected ? AppShadows.md(AppColors.primary.withAlpha(80)) : AppShadows.sm(Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: AppColors.primaryGradient)
                    : LinearGradient(colors: [Colors.white.withAlpha(220), Colors.white.withAlpha(180)]),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: selected ? AppColors.primary : AppColors.surfaceDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppDurations.normal,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(color: selected ? AppColors.primary : const Color(0xFFCBD5E1), width: 2),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
      ),
    );
  }
}
