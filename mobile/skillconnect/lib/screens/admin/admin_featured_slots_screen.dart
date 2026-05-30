import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class AdminFeaturedSlotsScreen extends StatefulWidget {
  const AdminFeaturedSlotsScreen({super.key});
  @override
  State<AdminFeaturedSlotsScreen> createState() => _AdminFeaturedSlotsScreenState();
}

class _AdminFeaturedSlotsScreenState extends State<AdminFeaturedSlotsScreen> {
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/featured-slots', auth: true);
      final data = res['data'];
      final list = data is List ? data : data is Map ? (data['items'] as List? ?? data['slots'] as List? ?? const []) : const [];
      _slots = list.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(String id) async {
    try {
      await ApiService.put('/admin/featured-slots/$id/approve', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot approved.'), backgroundColor: AppColors.success));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _reject(String id) async {
    try {
      await ApiService.put('/admin/featured-slots/$id/reject', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot rejected.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      child: Column(
        children: [
          PremiumAppBar(title: 'Featured Slots', gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)], actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () { HapticFeedback.mediumImpact(); _load(); }),
          ]),
          Expanded(
            child: _loading
                ? PremiumLoadingList(itemCount: 4, itemHeight: 150)
                : _error != null
                    ? PremiumEmptyState(icon: Icons.error_outline, title: 'Error', subtitle: _error!, actionLabel: 'Retry', onAction: _load)
                    : _slots.isEmpty
                        ? const PremiumEmptyState(icon: Icons.star_rounded, title: 'No featured slots', subtitle: 'Featured slot requests will appear here.')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
                              itemCount: _slots.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final s = _slots[i];
                                final id = s['id']?.toString() ?? '';
                                final status = s['status']?.toString();
                                final isPending = status == null || status == 'pending';
                                return PremiumGlassCard(
                                  gradient: isPending ? [const Color(0xFFFFF7ED), const Color(0xFFFFF7ED)] : null,
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Container(
                                        width: 42, height: 42,
                                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(AppRadius.md)),
                                        child: const Icon(Icons.star_rounded, color: Colors.white),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(s['professional_name']?.toString() ?? 'Professional', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                        Text(s['slot_type']?.toString() ?? 'Featured', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                      ])),
                                      PremiumStatusPill(label: status ?? 'pending', color: _statusColor(status)),
                                    ]),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(children: [
                                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Text('${s['start_date'] ?? '?'} → ${s['end_date'] ?? '?'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                      const Spacer(),
                                      if (s['amount_paid'] != null) Text('₹${s['amount_paid']}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
                                    ]),
                                    if (isPending) ...[
                                      const SizedBox(height: AppSpacing.md),
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
          ),
        ],
      ),
    );
  }
}
