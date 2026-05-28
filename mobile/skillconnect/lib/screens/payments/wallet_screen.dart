import 'package:flutter/material.dart';
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
        title: Text(topup ? 'Add Money' : 'Withdraw'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹', labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())), child: const Text('Continue')),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      await ApiService.post(topup ? '/wallet/topup' : '/wallet/withdraw', {'amount': amount}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(topup ? 'Top-up initiated.' : 'Withdrawal requested.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet action failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance ?? const <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(icon: Icons.account_balance_wallet_outlined, iconColor: Colors.red, title: 'Could not load wallet', subtitle: _error!, actionLabel: 'Retry', onAction: _load),
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
                          const Text('Available balance', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(_currency.format(((balance['available_balance'] ?? balance['balance'] ?? 0) as num).toDouble()), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: FilledButton.tonal(onPressed: () => _moneyAction(topup: true), child: const Text('Add Money'))),
                            const SizedBox(width: 12),
                            Expanded(child: FilledButton.tonal(onPressed: () => _moneyAction(topup: false), child: const Text('Withdraw'))),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Escrow', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('Funds held for active bookings: ${_currency.format(((balance['escrow_balance'] ?? 0) as num).toDouble())}'),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Text('Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (_transactions.isEmpty)
                        const EmptyStateWidget(icon: Icons.receipt_long_outlined, title: 'No transactions yet', subtitle: 'Wallet activity will show here after your first payment.')
                      else
                        ..._transactions.map((txn) {
                          final type = (txn['type'] ?? 'credit').toString();
                          final color = type == 'debit' ? Colors.red : Colors.green;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                            child: Row(children: [
                              CircleAvatar(backgroundColor: color.withAlpha(20), child: Icon(type == 'debit' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(txn['description']?.toString() ?? type, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(txn['date']?.toString() ?? txn['created_at']?.toString() ?? ''),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(_currency.format(((txn['amount'] ?? 0) as num).toDouble()), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text((txn['status'] ?? 'completed').toString()),
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
