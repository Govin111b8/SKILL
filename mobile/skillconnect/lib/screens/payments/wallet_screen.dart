import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final balanceRes = await ApiService.get('/wallet/balance', auth: true);
      final txnRes = await ApiService.get('/wallet/transactions', auth: true);
      _balance = Map<String, dynamic>.from((balanceRes['data'] as Map?) ?? const {});
      final data = txnRes['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['transactions'] as List? ?? const [])
              : const [];
      _transactions = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _moneyAction({required bool topup}) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(topup ? 'Add Money' : 'Withdraw'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '₹',
            labelText: 'Amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      await ApiService.post(topup ? '/wallet/topup' : '/wallet/withdraw', {'amount': amount}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(topup ? 'Top-up initiated.' : 'Withdrawal requested.'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Wallet action failed: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance ?? const <String, dynamic>{};
    final availableBalance = ((balance['available_balance'] ?? balance['balance'] ?? 0) as num).toDouble();
    final escrowBalance = ((balance['escrow_balance'] ?? 0) as num).toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: _loading
                ? _buildLoading()
                : _error != null
                    ? _buildError()
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                              child: Row(
                                children: const [
                                  Expanded(
                                    child: Text(
                                      'Wallet',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.surfaceDark,
                                        letterSpacing: -0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: _WalletHeroCard(
                                currency: _currency,
                                availableBalance: availableBalance,
                                escrowBalance: escrowBalance,
                                onAddMoney: () => _moneyAction(topup: true),
                                onWithdraw: () => _moneyAction(topup: false),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PremiumMetricCard(
                                      label: 'Available',
                                      value: _currency.format(availableBalance),
                                      icon: Icons.account_balance_wallet_rounded,
                                      color: AppColors.tileWallet,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: PremiumMetricCard(
                                      label: 'Escrow',
                                      value: _currency.format(escrowBalance),
                                      icon: Icons.lock_clock_rounded,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                              child: PremiumGlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quick actions',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.surfaceDark,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _QuickAction(
                                            icon: Icons.add_rounded,
                                            label: 'Add Money',
                                            color: AppColors.primary,
                                            onTap: () => _moneyAction(topup: true),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _QuickAction(
                                            icon: Icons.arrow_upward_rounded,
                                            label: 'Withdraw',
                                            color: AppColors.accent,
                                            onTap: () => _moneyAction(topup: false),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _QuickAction(
                                            icon: Icons.receipt_long_rounded,
                                            label: 'History',
                                            color: AppColors.secondary,
                                            onTap: _noop,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (escrowBalance > 0)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                                child: PremiumGlassCard(
                                  gradient: [AppColors.warningLight.withAlpha(235), Colors.white.withAlpha(190)],
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withAlpha(18),
                                          borderRadius: BorderRadius.circular(AppRadius.lg),
                                        ),
                                        child: const Icon(Icons.lock_rounded, color: AppColors.warning),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Escrow hold',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_currency.format(escrowBalance)} held for active bookings',
                                              style: const TextStyle(
                                                color: Color(0xFFB45309),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: PremiumSectionTitle(
                              title: 'Recent transactions',
                              subtitle: 'Every movement in your SkillConnect wallet, beautifully tracked.',
                            ),
                          ),
                          if (_transactions.isEmpty)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                child: PremiumEmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'No transactions yet',
                                  subtitle: 'Wallet activity will show here after your first payment, top-up, or withdrawal.',
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) {
                                  final txn = _transactions[i];
                                  return Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      AppSpacing.lg,
                                      0,
                                      AppSpacing.lg,
                                      i == _transactions.length - 1 ? AppSpacing.xxxl : AppSpacing.md,
                                    ),
                                    child: _TransactionItem(
                                      txn: txn,
                                      currency: _currency,
                                      isLast: i == _transactions.length - 1,
                                    ),
                                  );
                                },
                                childCount: _transactions.length,
                              ),
                            ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Column(
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.tileWallet, AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SkeletonContainer(height: 120, borderRadius: 24),
              const SizedBox(height: AppSpacing.md),
              const SkeletonContainer(height: 88, borderRadius: 20),
              const SizedBox(height: AppSpacing.md),
              const SkeletonContainer(height: 88, borderRadius: 20),
              const SizedBox(height: AppSpacing.md),
              const SkeletonContainer(height: 88, borderRadius: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: PremiumEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Unable to load wallet',
            subtitle: _error!,
            actionLabel: 'Retry',
            onAction: _load,
            gradient: AppColors.warmGradient,
          ),
        ),
      ],
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  final NumberFormat currency;
  final double availableBalance;
  final double escrowBalance;
  final VoidCallback onAddMoney;
  final VoidCallback onWithdraw;

  const _WalletHeroCard({
    required this.currency,
    required this.availableBalance,
    required this.escrowBalance,
    required this.onAddMoney,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), AppColors.tileWallet, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.xl(AppColors.tileWallet.withAlpha(150)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: Colors.white.withAlpha(35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Protected',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'SkillConnect Wallet',
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: availableBalance),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => Text(
              currency.format(val),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            escrowBalance > 0
                ? '${currency.format(escrowBalance)} currently secured in escrow'
                : 'Ready for payouts, top-ups, and smooth service payments',
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAddMoney,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.tileWallet, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Money',
                          style: TextStyle(
                            color: AppColors.tileWallet,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: onWithdraw,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: Colors.white.withAlpha(55)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Withdraw',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withAlpha(34), color.withAlpha(16)]),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> txn;
  final NumberFormat currency;
  final bool isLast;

  const _TransactionItem({
    required this.txn,
    required this.currency,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final type = (txn['type'] ?? 'credit').toString();
    final isDebit = type == 'debit';
    final color = isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final amount = ((txn['amount'] ?? 0) as num).toDouble();
    final description = txn['description']?.toString() ?? type;
    final date = txn['date']?.toString() ?? txn['created_at']?.toString() ?? '';
    final status = (txn['status'] ?? 'completed').toString();

    return PremiumGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withAlpha(28), color.withAlpha(10)]),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.surfaceDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date.isNotEmpty ? date.substring(0, math.min(10, date.length)) : '',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    if (status != 'completed') ...[
                      const SizedBox(width: AppSpacing.sm),
                      PremiumStatusPill(label: status, color: AppColors.warning),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${isDebit ? '-' : '+'}${currency.format(amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
