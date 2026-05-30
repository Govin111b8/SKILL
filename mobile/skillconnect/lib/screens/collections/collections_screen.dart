import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/collections', auth: true);
      final data = res['data'];
      final list = data is List ? data : (data is Map ? (data['items'] as List? ?? data['collections'] as List? ?? const []) : const []);
      _collections = list.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createCollection(String name, bool isPublic) async {
    try {
      await ApiService.post('/collections', {'name': name, 'is_public': isPublic}, auth: true);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteCollection(String id) async {
    try {
      await ApiService.delete('/collections/$id', auth: true);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtl = TextEditingController();
    bool isPublic = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(AppRadius.md)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('New Collection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g. Favorite Plumbers',
                prefixIcon: const Icon(Icons.collections_bookmark_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: isPublic,
                onChanged: (v) => setS(() => isPublic = v),
                title: const Text('Public Collection', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(isPublic ? 'Visible to everyone' : 'Only you can see this'),
                secondary: Icon(isPublic ? Icons.public_rounded : Icons.lock_outline_rounded, color: AppColors.primary),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            PremiumGradientButton(
              label: 'Create',
              colors: const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
              onPressed: () { if (nameCtl.text.trim().isNotEmpty) Navigator.pop(ctx, true); },
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && nameCtl.text.trim().isNotEmpty) {
      await _createCollection(nameCtl.text.trim(), isPublic);
    }
  }

  Future<void> _confirmDelete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete Collection?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteCollection(id);
  }

  static const _collectionGradients = [
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    [Color(0xFF6366F1), Color(0xFF0891B2)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF1B6EF3), Color(0xFF7C3AED)],
    [Color(0xFFDB2777), Color(0xFFDC2626)],
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { HapticFeedback.mediumImpact(); _showCreateDialog(); },
        backgroundColor: const Color(0xFFEC4899),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Collection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PremiumHeroHeader(
              title: 'My Collections',
              subtitle: 'Your curated boards',
              icon: Icons.collections_bookmark_rounded,
              gradient: const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
              chips: [
                if (!_loading) PremiumStatChip(label: '${_collections.length} boards', color: Colors.white, icon: Icons.grid_view_rounded),
              ],
            ),
          ),
          if (_loading)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: PremiumLoadingList(itemCount: 4, itemHeight: 160))),
          if (!_loading && _error != null)
            SliverToBoxAdapter(child: PremiumEmptyState(icon: Icons.error_outline, title: 'Something went wrong', subtitle: _error!, actionLabel: 'Retry', onAction: _load, gradient: const [AppColors.error, Color(0xFFDC2626)])),
          if (!_loading && _error == null && _collections.isEmpty)
            SliverToBoxAdapter(child: PremiumEmptyState(icon: Icons.collections_bookmark_rounded, title: 'No collections yet', subtitle: 'Create your first board to save and organize your favorite professionals.', actionLabel: 'Create Collection', onAction: _showCreateDialog, gradient: const [Color(0xFFEC4899), Color(0xFF8B5CF6)])),
          if (!_loading && _error == null && _collections.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final col = _collections[i];
                    final id = col['id']?.toString() ?? '';
                    final name = col['name']?.toString() ?? 'Collection';
                    final count = (col['item_count'] as num?)?.toInt() ?? 0;
                    final isPublic = col['is_public'] == true;
                    final grad = _collectionGradients[i % _collectionGradients.length];
                    return GestureDetector(
                      onTap: () { HapticFeedback.mediumImpact(); context.push('/collections/$id'); },
                      onLongPress: () { HapticFeedback.heavyImpact(); _confirmDelete(id, name); },
                      child: PremiumGlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: grad),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl), topRight: Radius.circular(AppRadius.xl)),
                              ),
                              child: Stack(children: [
                                Center(child: Icon(Icons.collections_bookmark_rounded, color: Colors.white.withAlpha(80), size: 48)),
                                Positioned(top: 10, right: 10, child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black.withAlpha(50), borderRadius: BorderRadius.circular(AppRadius.pill)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(isPublic ? Icons.public_rounded : Icons.lock_outline_rounded, color: Colors.white, size: 11),
                                    const SizedBox(width: 4),
                                    Text(isPublic ? 'Public' : 'Private', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ]),
                                )),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('$count item${count == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _collections.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.88),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

