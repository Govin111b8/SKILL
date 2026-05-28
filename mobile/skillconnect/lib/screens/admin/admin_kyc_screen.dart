import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class AdminKYCScreen extends StatefulWidget {
  const AdminKYCScreen({super.key});

  @override
  State<AdminKYCScreen> createState() => _AdminKYCScreenState();
}

class _AdminKYCScreenState extends State<AdminKYCScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, List<Map<String, dynamic>>> _items = {'pending': [], 'approved': [], 'rejected': []};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _status => ['pending', 'approved', 'rejected'][_tabController.index];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/admin/kyc', auth: true, queryParams: {'status': _status});
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['submissions'] as List? ?? const [])
              : const [];
      _items[_status] = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(String id) async {
    try {
      await ApiService.put('/admin/kyc/$id/approve', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC approved.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not approve KYC: $e')));
    }
  }

  Future<void> _reject(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ApiService.put('/admin/kyc/$id/reject', {'reason': reason}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC rejected.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not reject KYC: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _items[_status] ?? const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Review'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Rejected')]),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(icon: Icons.badge_outlined, iconColor: Colors.red, title: 'Could not load KYC', subtitle: _error!, actionLabel: 'Retry', onAction: _load),
                  ])
                : current.isEmpty
                    ? ListView(children: const [EmptyStateWidget(icon: Icons.inventory_2_outlined, title: 'No submissions', subtitle: 'No KYC records found for this status.')])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: current.length,
                        itemBuilder: (context, index) {
                          final item = current[index];
                          final preview = (item['document_preview'] ?? item['document_url'] ?? '').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(item['professional_name']?.toString() ?? 'Professional', style: const TextStyle(fontWeight: FontWeight.w700))),
                                Text(item['submitted_date']?.toString() ?? item['created_at']?.toString() ?? ''),
                              ]),
                              const SizedBox(height: 6),
                              Text(item['document_type']?.toString() ?? 'Document'),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: preview.isEmpty
                                    ? Container(height: 160, color: Theme.of(context).colorScheme.primaryContainer, child: const Center(child: Icon(Icons.description_outlined, size: 48)))
                                    : CachedNetworkImage(imageUrl: preview, height: 160, width: double.infinity, fit: BoxFit.cover, placeholder: (_, __) => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())), errorWidget: (_, __, ___) => Container(height: 160, color: Theme.of(context).colorScheme.primaryContainer, child: const Center(child: Icon(Icons.broken_image_outlined)))),
                              ),
                              if (_status == 'pending') ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: OutlinedButton(onPressed: () => _reject((item['id'] ?? '').toString()), child: const Text('Reject'))),
                                  const SizedBox(width: 12),
                                  Expanded(child: FilledButton(onPressed: () => _approve((item['id'] ?? '').toString()), child: const Text('Approve'))),
                                ]),
                              ],
                            ]),
                          );
                        },
                      ),
      ),
    );
  }
}
