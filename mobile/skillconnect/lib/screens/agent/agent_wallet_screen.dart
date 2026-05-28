import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

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

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet ?? const <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Wallet')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.red,
                      title: 'Could not load wallet',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Total balance', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(_currency.format(((wallet['balance'] ?? 0) as num).toDouble()), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 16),
                          FilledButton.tonal(onPressed: _requestPayout, child: const Text('Request Payout')),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _SummaryCard(label: 'This month', value: _currency.format(((wallet['this_month'] ?? 0) as num).toDouble()))),
                        const SizedBox(width: 12),
                        Expanded(child: _SummaryCard(label: 'Last month', value: _currency.format(((wallet['last_month'] ?? 0) as num).toDouble()))),
                      ]),
                      const SizedBox(height: 12),
                      _SummaryCard(label: 'Total earned', value: _currency.format(((wallet['total_earned'] ?? 0) as num).toDouble())),
                      const SizedBox(height: 20),
                      Text('Commission earnings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (_earnings.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.receipt_long_outlined,
                          title: 'No commissions yet',
                          subtitle: 'Commission activity will show up here after your first successful referral.',
                        )
                      else
                        ..._earnings.map((item) {
                          final status = (item['status'] ?? 'pending').toString();
                          final color = status == 'credited' ? Colors.green : Colors.orange;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['booking_reference']?.toString() ?? item['booking_id']?.toString() ?? 'Booking', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(item['date']?.toString() ?? item['created_at']?.toString() ?? ''),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(_currency.format(((item['commission_amount'] ?? item['amount'] ?? 0) as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(18)),
                                  child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ]),
                            ]),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
