import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, List<Map<String, dynamic>>> _items = {'open': [], 'resolved': [], 'escalated': []};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _status => ['open', 'resolved', 'escalated'][_tabController.index];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/admin/disputes', auth: true, queryParams: {'status': _status});
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['disputes'] as List? ?? const [])
              : const [];
      _items[_status] = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolve(Map<String, dynamic> dispute) async {
    final noteController = TextEditingController();
    String action = 'refund_customer';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Resolve dispute', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            RadioListTile<String>(title: const Text('Refund customer'), value: 'refund_customer', groupValue: action, onChanged: (v) => setSheetState(() => action = v!)),
            RadioListTile<String>(title: const Text('Release to pro'), value: 'release_to_pro', groupValue: action, onChanged: (v) => setSheetState(() => action = v!)),
            RadioListTile<String>(title: const Text('Partial refund'), value: 'partial_refund', groupValue: action, onChanged: (v) => setSheetState(() => action = v!)),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Admin note'), maxLines: 3),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                try {
                  await ApiService.put('/admin/disputes/${dispute['id']}/resolve', {'resolution': action, 'admin_note': noteController.text.trim()}, auth: true);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute resolved.')));
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not resolve dispute: $e')));
                }
              },
              child: const Text('Submit resolution'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _items[_status] ?? const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Disputes'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Open'), Tab(text: 'Resolved'), Tab(text: 'Escalated')]),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [EmptyStateWidget(icon: Icons.balance_outlined, iconColor: Colors.red, title: 'Could not load disputes', subtitle: _error!, actionLabel: 'Retry', onAction: _load)])
                : current.isEmpty
                    ? ListView(children: const [EmptyStateWidget(icon: Icons.balance_outlined, title: 'No disputes found', subtitle: 'No disputes match the selected status.')])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: current.length,
                        itemBuilder: (context, index) {
                          final dispute = current[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Booking #${dispute['booking_id'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text('Customer: ${dispute['customer_name'] ?? '—'}'),
                              Text('Professional: ${dispute['professional_name'] ?? '—'}'),
                              Text('Reason: ${dispute['reason'] ?? 'Not provided'}'),
                              Text('Amount: ₹${dispute['amount'] ?? 0}'),
                              Text('Filed: ${dispute['date_filed'] ?? dispute['created_at'] ?? ''}'),
                              if (_status == 'open') ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(onPressed: () => _resolve(dispute), child: const Text('Resolve')),
                                ),
                              ],
                            ]),
                          );
                        },
                      ),
      ),
    );
  }
}
