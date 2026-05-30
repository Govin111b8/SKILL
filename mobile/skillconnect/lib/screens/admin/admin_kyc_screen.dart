import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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
    _tabController.addListener(() { if (!_tabController.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  String get _status => ['pending', 'approved', 'rejected'][_tabController.index];

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/kyc', auth: true, queryParams: {'status': _status});
      final data = res['data'];
      final list = data is List ? data : data is Map<String, dynamic> ? (data['items'] as List? ?? data['submissions'] as List? ?? const []) : const [];
      _items[_status] = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(String id) async {
    try {
      await ApiService.put('/admin/kyc/$id/approve', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC approved.'), backgroundColor: AppColors.success));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not approve: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _reject(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Reject KYC', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          PremiumGradientButton(label: 'Reject', colors: const [AppColors.error, Color(0xFFDC2626)], onPressed: () => Navigator.pop(ctx, controller.text.trim()), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  static const _tabColors = [AppColors.warning, AppColors.success, AppColors.error];
  static const _tabLabels = ['Pending', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final items = _items[_status] ?? [];
    return PremiumScrollScaffold(
      child: Column(
        children: [
          PremiumAppBar(title: 'KYC Reviews', gradient: const [Color(0xFF4F46E5), Color(0xFF6366F1)]),
          // Glass tab bar
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
                ? PremiumLoadingList(itemCount: 4, itemHeight: 160)
                : _error != null
                    ? PremiumEmptyState(icon: Icons.error_outline, title: 'Error loading', subtitle: _error!, actionLabel: 'Retry', onAction: _load)
                    : items.isEmpty
                        ? PremiumEmptyState(icon: Icons.verified_user_rounded, title: 'No ${_status} submissions', subtitle: 'All KYC submissions with this status will appear here.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final item = items[i];
                              final id = item['id']?.toString() ?? '';
                              return PremiumGlassCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(item['user_name']?.toString() ?? 'User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text(item['document_type']?.toString() ?? 'Document', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                    ])),
                                    PremiumStatusPill(label: _status, color: _tabColors[_tabController.index]),
                                  ]),
                                  if (item['document_url'] != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      child: CachedNetworkImage(imageUrl: item['document_url'].toString(), height: 120, width: double.infinity, fit: BoxFit.cover, placeholder: (_, __) => Container(height: 120, color: Colors.grey.shade100)),
                                    ),
                                  ],
                                  if (_status == 'pending') ...[
                                    const SizedBox(height: AppSpacing.lg),
                                    Row(children: [
                                      Expanded(child: PremiumGradientButton(label: 'Approve', icon: Icons.check_rounded, colors: const [AppColors.success, Color(0xFF059669)], onPressed: () { HapticFeedback.mediumImpact(); _approve(id); })),
                                      const SizedBox(width: 8),
                                      Expanded(child: OutlinedButton.icon(
                                        onPressed: () { HapticFeedback.mediumImpact(); _reject(id); },
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                      )),
                                    ]),
                                  ],
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
