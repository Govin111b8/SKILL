import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
// ignore: unused_import
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class AgentWalletScreen extends StatefulWidget {
  const AgentWalletScreen({super.key});

  @override
  State<AgentWalletScreen> createState() => _AgentWalletScreenState();
}

class _AgentWalletScreenState extends State<AgentWalletScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _earnings = [];
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
      final walletRes = await ApiService.get('/agents/me/wallet', auth: true);
      final earningsRes = await ApiService.get('/agents/me/earnings', auth: true);
      _wallet = Map<String, dynamic>.from((walletRes['data'] as Map?) ?? const {});
      final data = earningsRes['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['earnings'] as List? ?? const [])
              : const [];
      _earnings = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _requestPayout() async {
    try {
      await ApiService.post('/agents/me/payout', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout request submitted.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not request payout: $e')));
    }
  }

  Future<void> _openWithdrawSheet() async {
    HapticFeedback.mediumImpact();
    final balance = ((_wallet?['balance'] ?? 0) as num).toDouble();
    final controller = TextEditingController(text: balance > 0 ? balance.toStringAsFixed(0) : '');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: PremiumGlassCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            gradient: [Colors.white.withAlpha(235), Colors.white.withAlpha(190)],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Withdraw funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          SizedBox(height: AppSpacing.xs),
                          Text('Payouts are sent to your verified bank account on file.'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    filled: true,
                    fillColor: Colors.white.withAlpha(180),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: BorderSide(color: AppColors.primary.withAlpha(35)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: BorderSide(color: AppColors.primary.withAlpha(35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Available balance: ${_currency.format(balance)}',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: PremiumGradientButton(
                    label: 'Request payout',
                    icon: Icons.north_east_rounded,
                    colors: AppColors.primaryGradient,
                    onPressed: () async {
                      Navigator.pop(context);
                      await _requestPayout();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet ?? const <String, dynamic>{};
    final balance = ((wallet['balance'] ?? 0) as num).toDouble();
    final totalEarned = ((wallet['total_earned'] ?? 0) as num).toDouble();
    final withdrawn = ((wallet['total_withdrawn'] ?? 0) as num).toDouble();
    final pending = ((wallet['pending_amount'] ?? 0) as num).toDouble();

    return PremiumScrollScaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.huge, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agent Wallet',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Track your commissions, cash flow, and payout momentum.',
                                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _load();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(180),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_loading)
                      const PremiumLoadingList(itemCount: 4, itemHeight: 120)
                    else if (_error != null)
                      PremiumEmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Could not load wallet',
                        subtitle: _error!,
                        actionLabel: 'Retry',
                        onAction: _load,
                        gradient: const [AppColors.error, Color(0xFFF97316)],
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1B6EF3), Color(0xFF1558CC)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: AppShadows.xl(const Color(0xFF1B6EF3)),
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
                                    border: Border.all(color: Colors.white.withAlpha(38)),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 30),
                                ),
                                const Spacer(),
                                PremiumStatusPill(
                                  label: pending > 0 ? 'Pending payout' : 'Ready to withdraw',
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Available Balance',
                              style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _currency.format(balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Fast, secure transfers to your registered bank account.',
                              style: TextStyle(color: Colors.white.withAlpha(210), height: 1.45),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            PremiumGradientButton(
                              label: 'Withdraw now',
                              icon: Icons.arrow_upward_rounded,
                              colors: const [Color(0xFF60A5FA), Color(0xFF2563EB)],
                              onPressed: _openWithdrawSheet,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: _WalletMetricCard(
                              label: 'Total Earned',
                              value: _currency.format(totalEarned),
                              icon: Icons.trending_up_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _WalletMetricCard(
                              label: 'Withdrawn',
                              value: _currency.format(withdrawn),
                              icon: Icons.call_made_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _WalletMetricCard(
                              label: 'Pending',
                              value: _currency.format(pending),
                              icon: Icons.timelapse_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!_loading && _error == null) ...[
              SliverToBoxAdapter(
                child: PremiumSectionTitle(
                  title: 'Transactions',
                  subtitle: 'Every commission and payout update in one premium feed.',
                  trailing: PremiumStatusPill(
                    label: '${_earnings.length} entries',
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (_earnings.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: PremiumEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No commissions yet',
                    subtitle: 'Commission activity will show up here after your first successful referral.',
                    gradient: const [AppColors.primary, AppColors.accent],
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                    child: Column(
                      children: [
                        for (var index = 0; index < _earnings.length; index++) ...[
                          Builder(
                            builder: (context) {
                              final item = _earnings[index];
                              final status = (item['status'] ?? 'pending').toString();
                              final isCredited = status == 'credited';
                              final color = isCredited ? AppColors.success : AppColors.warning;
                              final amount = ((item['commission_amount'] ?? item['amount'] ?? 0) as num).toDouble();
                              final description = item['booking_reference']?.toString() ?? item['booking_id']?.toString() ?? 'Booking';
                              final dateText = _formatDate(item['date']?.toString() ?? item['created_at']?.toString());
                              return PremiumGlassCard(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(16),
                                        borderRadius: BorderRadius.circular(AppRadius.lg),
                                      ),
                                      child: Icon(
                                        isCredited ? Icons.south_west_rounded : Icons.schedule_rounded,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            description,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            dateText,
                                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          PremiumStatusPill(label: status, color: color),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _currency.format(amount),
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          isCredited ? 'Credit' : 'Processing',
                                          style: TextStyle(color: color, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (index != _earnings.length - 1) const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Date unavailable';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy • hh:mm a').format(parsed.toLocal());
  }
}

class _WalletMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WalletMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(16),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
