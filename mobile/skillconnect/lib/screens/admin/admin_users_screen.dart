import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _role = 'all';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) _loadMore();
  }

  Map<String, String> _query({required int page}) => {
    'page': '$page',
    'role': _role == 'all' ? '' : _role,
    'status': _status == 'all' ? '' : _status,
    if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
  };

  Future<void> _load({bool reset = true}) async {
    if (reset) setState(() { _loading = true; _page = 1; _hasMore = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/users', auth: true, queryParams: _query(page: reset ? 1 : _page));
      final data = res['data'];
      final list = data is List ? data : data is Map<String, dynamic> ? (data['items'] as List? ?? data['users'] as List? ?? const []) : const [];
      final parsed = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() { if (reset) _users = parsed; else _users.addAll(parsed); _hasMore = parsed.isNotEmpty; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() { _loadingMore = true; _page++; });
    try {
      final res = await ApiService.get('/admin/users', auth: true, queryParams: _query(page: _page));
      final data = res['data'];
      final list = data is List ? data : data is Map<String, dynamic> ? (data['items'] as List? ?? data['users'] as List? ?? const []) : const [];
      final parsed = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() { _users.addAll(parsed); _hasMore = parsed.isNotEmpty; _loadingMore = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _updateStatus(String userId, String status) async {
    try {
      await ApiService.put('/admin/users/$userId/status', {'status': status}, auth: true);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User $status'), backgroundColor: AppColors.success)); _load(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showUserActions(Map<String, dynamic> user) {
    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? 'User';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: PremiumGlassCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.lg),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.lg),
            _ActionTile(icon: Icons.check_circle_outline_rounded, label: 'Activate', color: AppColors.success, onTap: () { Navigator.pop(ctx); _updateStatus(id, 'active'); }),
            _ActionTile(icon: Icons.block_rounded, label: 'Suspend', color: AppColors.error, onTap: () { Navigator.pop(ctx); _updateStatus(id, 'suspended'); }),
            const SizedBox(height: AppSpacing.md),
          ]),
        ),
      ),
    );
  }

  static const _roleFilters = [('all','All'),('customer','Customer'),('professional','Professional'),('agent','Agent')];
  static const _statusFilters = [('all','All'),('active','Active'),('suspended','Suspended')];

  Color _roleColor(String role) {
    switch (role) {
      case 'professional': return AppColors.primary;
      case 'agent': return AppColors.warning;
      case 'admin': return AppColors.error;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      child: Column(
        children: [
          PremiumAppBar(title: 'Users', gradient: const [Color(0xFF4F46E5), Color(0xFF6366F1)], actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () { HapticFeedback.mediumImpact(); _load(); }),
          ]),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PremiumSearchField(
              hint: 'Search users...',
              controller: _searchController,
              onChanged: (_) => Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _load(); }),
            ),
          ),
          // Role chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _roleFilters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _role = f.$1); _load(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _role == f.$1 ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]) : null,
                      color: _role == f.$1 ? null : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: _role == f.$1 ? Colors.transparent : Colors.grey.shade200),
                    ),
                    child: Text(f.$2, style: TextStyle(color: _role == f.$1 ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _statusFilters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _status = f.$1); _load(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _status == f.$1 ? AppColors.primary.withAlpha(15) : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: _status == f.$1 ? AppColors.primary : Colors.grey.shade200),
                    ),
                    child: Text(f.$2, style: TextStyle(color: _status == f.$1 ? AppColors.primary : Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading && _users.isEmpty
                ? PremiumLoadingList(itemCount: 6, itemHeight: 80)
                : _error != null && _users.isEmpty
                    ? PremiumEmptyState(icon: Icons.error_outline, title: 'Failed to load', subtitle: _error!, actionLabel: 'Retry', onAction: _load)
                    : _users.isEmpty
                        ? const PremiumEmptyState(icon: Icons.people_outline_rounded, title: 'No users found', subtitle: 'Try adjusting your search filters.')
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                            itemCount: _users.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              if (i == _users.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                              final u = _users[i];
                              final role = u['role']?.toString() ?? 'customer';
                              final status = u['status']?.toString() ?? 'active';
                              final name = u['name']?.toString() ?? 'User';
                              return GestureDetector(
                                onTap: () { HapticFeedback.mediumImpact(); _showUserActions(u); },
                                child: PremiumGlassCard(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: _roleColor(role).withAlpha(20),
                                      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w800, fontSize: 16)),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Text(u['email']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      PremiumStatusPill(label: role, color: _roleColor(role)),
                                      const SizedBox(height: 4),
                                      PremiumStatusPill(label: status, color: status == 'active' ? AppColors.success : AppColors.error),
                                    ]),
                                  ]),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(AppRadius.lg)), child: Icon(icon, color: color)),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}
