import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  List<Map<String, dynamic>> _subscriptions = [];
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
      final res = await ApiService.get('/subscriptions', auth: true);
      final data = res['data'];
      final items = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['subscriptions'] as List? ?? const [])
              : const [];
      _subscriptions = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pauseAll() async {
    try {
      await ApiService.post('/subscriptions/vacation', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vacation mode enabled.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pause subscriptions: $e')));
    }
  }

  Future<void> _replaceProvider(String id) async {
    try {
      await ApiService.post('/subscriptions/$id/replace-provider', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider replacement requested.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not replace provider: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/search'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Subscription'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonBookingCard(),
                )),
              )
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.wifi_off_rounded,
                      iconColor: Colors.red,
                      title: 'Could not load subscriptions',
                      subtitle: _error!,
                      actionLabel: 'Try again',
                      onAction: _load,
                    ),
                  ])
                : _subscriptions.isEmpty
                    ? ListView(children: const [
                        EmptyStateWidget(
                          icon: Icons.autorenew_rounded,
                          title: 'No active plans',
                          subtitle: 'Create your first recurring service subscription to keep home services on autopilot.',
                        ),
                      ])
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          FilledButton.icon(
                            onPressed: _pauseAll,
                            icon: const Icon(Icons.beach_access_rounded),
                            label: const Text('Pause (Vacation Mode)'),
                          ),
                          const SizedBox(height: 16),
                          ..._subscriptions.map((subscription) {
                            final status = (subscription['status'] ?? 'active').toString();
                            final amount = (subscription['monthly_amount'] ?? subscription['amount'] ?? 0) as num;
                            final nextBilling = DateTime.tryParse((subscription['next_billing_date'] ?? subscription['next_billing_at'] ?? '').toString());
                            final professional = (subscription['professional_name'] ?? subscription['provider_name'] ?? 'Assigned provider').toString();
                            final service = (subscription['service_type'] ?? subscription['category_name'] ?? subscription['title'] ?? 'Service plan').toString();
                            final chipColor = switch (status) {
                              'paused' => Colors.orange,
                              'cancelled' => Colors.red,
                              _ => Colors.green,
                            };
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(service, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: chipColor.withAlpha(20),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: chipColor.withAlpha(80)),
                                        ),
                                        child: Text(
                                          status.replaceAll('_', ' '),
                                          style: TextStyle(color: chipColor, fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Professional: $professional'),
                                  const SizedBox(height: 6),
                                  Text('Next billing: ${nextBilling != null ? DateFormat('dd MMM yyyy').format(nextBilling) : 'TBD'}'),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Monthly amount: ${_currency.format(amount)}',
                                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _replaceProvider((subscription['id'] ?? '').toString()),
                                      icon: const Icon(Icons.swap_horiz_rounded),
                                      label: const Text('Replace Provider'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
      ),
    );
  }
}
