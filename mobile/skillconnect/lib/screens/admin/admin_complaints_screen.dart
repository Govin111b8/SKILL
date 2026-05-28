import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> with SingleTickerProviderStateMixin {
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
      final res = await ApiService.get('/admin/complaints', auth: true, queryParams: {'status': _status});
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['complaints'] as List? ?? const [])
              : const [];
      _items[_status] = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolve(Map<String, dynamic> complaint) async {
    final noteController = TextEditingController();
    String action = 'warn_user';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Resolve complaint', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            RadioListTile<String>(title: const Text('Warn user'), value: 'warn_user', groupValue: action, onChanged: (v) => setSheetState(() => action = v!)),
            RadioListTile<String>(title: const Text('Suspend account'), value: 'suspend_account', groupValue: action, onChanged: (v) => setSheetState(() => action = v!)),
            RadioListTile<String>(title: const Text('Dismiss'), value: 'dismiss', groupValue: action, onChanged: (v) => setSheetState(() => action = v!)),
            RadioListTile<String>(title: const Text('Escalate'), value: 'escalate', groupValue: action, onChanged: (v) => setSheetState(() => action = v!)),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Admin note'), maxLines: 3),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                try {
                  await ApiService.put('/admin/complaints/${complaint['id']}/resolve', {'action': action, 'admin_note': noteController.text.trim()}, auth: true);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint resolved.')));
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not resolve complaint: $e')));
                }
              },
              child: const Text('Submit action'),
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
        title: const Text('Admin Complaints'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Open'), Tab(text: 'Resolved'), Tab(text: 'Escalated')]),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [EmptyStateWidget(icon: Icons.report_outlined, iconColor: Colors.red, title: 'Could not load complaints', subtitle: _error!, actionLabel: 'Retry', onAction: _load)])
                : current.isEmpty
                    ? ListView(children: const [EmptyStateWidget(icon: Icons.report_outlined, title: 'No complaints found', subtitle: 'No complaints match the selected status.')])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: current.length,
                        itemBuilder: (context, index) {
                          final complaint = current[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(complaint['category']?.toString() ?? 'Complaint', style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text('Complainant: ${complaint['complainant'] ?? complaint['complainant_name'] ?? '—'}'),
                              Text('Accused: ${complaint['accused'] ?? complaint['accused_name'] ?? '—'}'),
                              Text('Date: ${complaint['date'] ?? complaint['created_at'] ?? ''}'),
                              const SizedBox(height: 8),
                              Text(complaint['description']?.toString() ?? 'No description provided'),
                              if (_status == 'open') ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(onPressed: () => _resolve(complaint), child: const Text('Resolve')),
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
