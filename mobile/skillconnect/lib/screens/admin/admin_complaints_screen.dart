import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;
  String? _error;
  String _status = 'open';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/complaints', auth: true, queryParams: {'status': _status});
      final data = res['data'];
      final list = data is List ? data : data is Map ? (data['items'] as List? ?? data['complaints'] as List? ?? const []) : const [];
      _complaints = list.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolve(String id) async {
    final noteCtl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Resolve Complaint', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(controller: noteCtl, decoration: const InputDecoration(labelText: 'Resolution note'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          PremiumGradientButton(label: 'Resolve', onPressed: () => Navigator.pop(ctx, true), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.put('/admin/complaints/$id/resolve', {'resolution': noteCtl.text.trim()}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint resolved.'), backgroundColor: AppColors.success));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'fraud': return Icons.warning_rounded;
      case 'harassment': return Icons.report_rounded;
      case 'spam': return Icons.block_rounded;
      case 'poor_service': return Icons.thumb_down_rounded;
      default: return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      child: Column(
        children: [
          PremiumAppBar(title: 'Complaints', gradient: const [Color(0xFF4F46E5), Color(0xFF6366F1)]),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(children: [
              for (final s in [('open','Open'),('resolved','Resolved'),('all','All')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _status = s.$1); _load(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _status == s.$1 ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]) : null,
                        color: _status == s.$1 ? null : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: _status == s.$1 ? Colors.transparent : Colors.grey.shade200),
                      ),
                      child: Text(s.$2, style: TextStyle(color: _status == s.$1 ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: _loading
                ? PremiumLoadingList(itemCount: 5, itemHeight: 120)
                : _error != null
                    ? PremiumEmptyState(icon: Icons.error_outline, title: 'Error', subtitle: _error!, actionLabel: 'Retry', onAction: _load)
                    : _complaints.isEmpty
                        ? const PremiumEmptyState(icon: Icons.flag_rounded, title: 'No complaints', subtitle: 'All complaints with this status appear here.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                            itemCount: _complaints.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final c = _complaints[i];
                              final id = c['id']?.toString() ?? '';
                              final type = c['complaint_type']?.toString() ?? c['type']?.toString();
                              final isOpen = (c['status']?.toString() ?? 'open') == 'open';
                              return PremiumGlassCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.error.withAlpha(15), borderRadius: BorderRadius.circular(AppRadius.md)), child: Icon(_typeIcon(type), color: AppColors.error, size: 18)),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c['reporter_name']?.toString() ?? 'Reporter', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text('Reports: ${c['reported_name'] ?? 'User'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ])),
                                    PremiumStatusPill(label: c['status']?.toString() ?? 'open', color: isOpen ? AppColors.error : AppColors.success),
                                  ]),
                                  if (c['description'] != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(c['description'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  if (isOpen) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    PremiumGradientButton(label: 'Resolve', icon: Icons.check_rounded, onPressed: () { HapticFeedback.mediumImpact(); _resolve(id); }, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
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
