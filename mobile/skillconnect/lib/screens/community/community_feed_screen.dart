import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<Map<String, dynamic>> _items = [];
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
      final res = await ApiService.get('/social/feed', auth: true);
      final data = res['data'];
      final list = data is List ? data : (data is Map ? (data['items'] as List? ?? data['feed'] as List? ?? const []) : const []);
      _items = list.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  static const _typeConfig = {
    'portfolio': (Color(0xFF8B5CF6), Icons.photo_library_rounded, 'New Portfolio'),
    'availability': (Color(0xFF10B981), Icons.calendar_today_rounded, 'Available Now'),
    'offer': (Color(0xFFF59E0B), Icons.local_offer_rounded, 'Special Offer'),
    'post': (Color(0xFF6366F1), Icons.article_rounded, 'Post'),
  };

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PremiumHeroHeader(
                title: 'Your Feed',
                subtitle: 'Updates from professionals you follow',
                icon: Icons.dynamic_feed_rounded,
                gradient: const [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
            ),
            if (_loading)
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: PremiumLoadingList(itemCount: 5, itemHeight: 110))),
            if (!_loading && _error != null)
              SliverToBoxAdapter(child: PremiumEmptyState(icon: Icons.error_outline, title: 'Could not load feed', subtitle: _error!, actionLabel: 'Retry', onAction: _load)),
            if (!_loading && _error == null && _items.isEmpty)
              SliverToBoxAdapter(child: PremiumEmptyState(
                icon: Icons.dynamic_feed_rounded,
                title: 'Your feed is empty',
                subtitle: 'Follow professionals to see their updates, new work, and special offers here.',
                gradient: const [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              )),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = _items[i];
                    final type = item['type']?.toString() ?? 'post';
                    final cfg = _typeConfig[type] ?? _typeConfig['post']!;
                    final color = cfg.$1;
                    final icon = cfg.$2;
                    final typeLabel = cfg.$3;
                    final proId = item['professional_id']?.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (proId != null) context.push('/professional/$proId');
                        },
                        child: PremiumGlassCard(
                          padding: EdgeInsets.zero,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl), bottomLeft: Radius.circular(AppRadius.xl)),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundImage: item['professional_avatar'] != null ? CachedNetworkImageProvider(item['professional_avatar'].toString()) : null,
                                            backgroundColor: color.withAlpha(30),
                                            child: item['professional_avatar'] == null ? Text(
                                              (item['professional_name']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                                              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                                            ) : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(item['professional_name']?.toString() ?? 'Professional', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                            Text(_timeAgo(item['created_at']?.toString()), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                          ])),
                                          PremiumStatusPill(label: typeLabel, color: color),
                                        ]),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(item['content']?.toString() ?? item['message']?.toString() ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        if (proId != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                                            child: Text('View Profile →', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _items.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

