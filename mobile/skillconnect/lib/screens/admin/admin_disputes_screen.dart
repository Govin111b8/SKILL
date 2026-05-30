import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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
    _tabController.addListener(() { if (!_tabController.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  String get _status => ['open', 'resolved', 'escalated'][_tabController.index];

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/disputes', auth: true, queryParams: {'status': _status});
      final data = res['data'];
      final list = data is List ? data : data is Map<String, dynamic> ? (data['items'] as List? ?? data['disputes'] as List? ?? const []) : const [];
      _items[_status] = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolve(Map<String, dynamic> dispute) async {
    final noteController = TextEditingController();
    String action = 'refund_customer';
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: PremiumGlassCard(
          child: StatefulBuilder(
            builder: (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSpacing.lg),
              const Text('Resolve Dispute', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: AppSpacing.lg),
              ...['refund_customer', 'release_to_pro', 'partial_refund'].map((v) => RadioListTile<String>(
                value: v,
                groupValue: action,
                onChanged: (nv) => setS(() => action = nv!),
                title: Text(v.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase()), style: const TextStyle(fontWeight: FontWeight.w600)),
                contentPadding: EdgeInsets.zero,
              )),
              TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Admin note', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: AppSpacing.lg),
              PremiumGradientButton(
                label: 'Resolve',
                icon: Icons.gavel_rounded,
                onPressed: () async {
                  try {
                    await ApiService.put('/admin/disputes/${dispute['id']}/resolve', {'resolution': action, 'admin_note': noteController.text.trim()}, auth: true);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute resolved.'), backgroundColor: AppColors.success));
                    await _load();
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static const _tabColors = [AppColors.error, AppColors.success, AppColors.warning];
  static const _tabLabels = ['Open', 'Resolved', 'Escalated'];

  @override
  Widget build(BuildContext context) {
    final items = _items[_status] ?? [];
    return PremiumScrollScaffold(
      child: Column(
        children: [
          PremiumAppBar(title: 'Disputes', gradient: const [Color(0xFF4F46E5), Color(0xFF6366F1)]),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PremiumGlassCard(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                indicator: BoxDecoration(
                  gradient: LinearGradient(colors: [_tabColors[_tabController.index], _tabColors[_tabController.index].withAlpha(200)]),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                tabs: List.generate(3, (i) => Tab(text: _tabLabels[i])),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? PremiumLoadingList(itemCount: 5, itemHeight: 130)
                : _error != null
                    ? PremiumEmptyState(icon: Icons.error_outline, title: 'Error', subtitle: _error!, actionLabel: 'Retry', onAction: _load)
                    : items.isEmpty
                        ? PremiumEmptyState(icon: Icons.gavel_rounded, title: 'No ${_status} disputes', subtitle: 'Disputes with this status appear here.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final d = items[i];
                              return PremiumGlassCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text('Case #${d['id']?.toString().substring(0, 8) ?? '?'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                                    if (d['amount'] != null) Text('₹${d['amount']}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  ]),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text('${d['customer_name'] ?? 'Customer'} vs ${d['pro_name'] ?? 'Professional'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  if (d['reason'] != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(d['reason'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: AppSpacing.md),
                                  Row(children: [
                                    PremiumStatusPill(label: _status, color: _tabColors[_tabController.index]),
                                    if (_status == 'open') ...[
                                      const Spacer(),
                                      PremiumGradientButton(label: 'Resolve', icon: Icons.gavel_rounded, colors: const [AppColors.primary, AppColors.accent], onPressed: () { HapticFeedback.mediumImpact(); _resolve(d); }, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                    ],
                                  ]),
                                ]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
