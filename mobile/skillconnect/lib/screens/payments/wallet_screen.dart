import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

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
      backgroundColor: const Color(0xFFF1F5F9),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF6366F1),
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : CustomScrollView(
                    slivers: [
                      // Hero balance card as a SliverAppBar
                      SliverToBoxAdapter(
                        child: _WalletHeroCard(
                          currency: _currency,
                          availableBalance: availableBalance,
                          escrowBalance: escrowBalance,
                          onAddMoney: () => _moneyAction(topup: true),
                          onWithdraw: () => _moneyAction(topup: false),
                        ),
                      ),

                      // Quick actions
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quick Actions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  )),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _QuickAction(
                                    icon: Icons.add_rounded,
                                    label: 'Add Money',
                                    color: const Color(0xFF6366F1),
                                    onTap: () => _moneyAction(topup: true),
                                  ),
                                  _QuickAction(
                                    icon: Icons.arrow_upward_rounded,
                                    label: 'Withdraw',
                                    color: const Color(0xFF8B5CF6),
                                    onTap: () => _moneyAction(topup: false),
                                  ),
                                  _QuickAction(
                                    icon: Icons.receipt_long_rounded,
                                    label: 'History',
                                    color: const Color(0xFF06B6D4),
                                    onTap: () {},
                                  ),
                                  _QuickAction(
                                    icon: Icons.local_offer_rounded,
                                    label: 'Offers',
                                    color: const Color(0xFFF59E0B),
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Escrow info card
                      if (escrowBalance > 0)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withAlpha(40),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock_rounded,
                                        color: Color(0xFFD97706), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Escrow Hold',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF92400E),
                                                fontSize: 13)),
                                        Text(
                                          '${_currency.format(escrowBalance)} held for active bookings',
                                          style: const TextStyle(
                                              color: Color(0xFFB45309), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Transactions section header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Recent Transactions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  )),
                              Text('View All',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6366F1).withAlpha(220),
                                  )),
                            ],
                          ),
                        ),
                      ),

                      // Transaction list
                      if (_transactions.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_long_outlined,
                                      size: 40, color: Color(0xFF6366F1)),
                                ),
                                const SizedBox(height: 16),
                                const Text('No transactions yet',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF0F172A))),
                                const SizedBox(height: 6),
                                Text('Wallet activity will show here\nafter your first payment.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final txn = _transactions[i];
                              return _TransactionItem(
                                txn: txn,
                                currency: _currency,
                                isLast: i == _transactions.length - 1,
                              );
                            },
                            childCount: _transactions.length,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 260,
          margin: EdgeInsets.zero,
          color: const Color(0xFF4338CA),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(4, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonContainer(height: 72, borderRadius: 16),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SkillConnect Wallet',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('Active',
                            style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Balance
              Text(
                'Available Balance',
                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
              ),
              const SizedBox(height: 8),
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

              const SizedBox(height: 28),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onAddMoney,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: Color(0xFF4338CA), size: 20),
                            SizedBox(width: 6),
                            Text('Add Money',
                                style: TextStyle(
                                    color: Color(0xFF4338CA),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: onWithdraw,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(60)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text('Withdraw',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
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

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, isLast ? 0 : 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      date.isNotEmpty ? date.substring(0, math.min(10, date.length)) : '',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                    if (status != 'completed') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status,
                            style: const TextStyle(
                                color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isDebit ? '-' : '+'}${currency.format(amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
