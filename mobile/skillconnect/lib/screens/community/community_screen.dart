import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/community_post.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;
  String _selectedCategory = '';
  int _page = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();
  final Set<String> _likedIds = {};
  final Set<String> _savedIds = {};

  static const _categories = [
    ('', 'All'),
    ('beauty', 'Beauty'),
    ('home', 'Home'),
    ('fitness', 'Fitness'),
    ('tutoring', 'Tutors'),
    ('photography', 'Photos'),
    ('tech', 'Tech'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200 && !_loading && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) setState(() { _loading = true; _error = null; _page = 1; _hasMore = true; });
    try {
      final params = <String, String>{'page': '1', 'limit': '20'};
      if (_selectedCategory.isNotEmpty) params['category'] = _selectedCategory;
      final res = await ApiService.get('/community/posts', queryParams: params);
      final data = res['data'];
      final list = data is List ? data : (data is Map ? (data['posts'] as List? ?? data['items'] as List? ?? const []) : const []);
      final parsed = list.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
      if (mounted) setState(() { _posts = parsed; _hasMore = parsed.length >= 20; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final nextPage = _page + 1;
      final params = <String, String>{'page': nextPage.toString(), 'limit': '20'};
      if (_selectedCategory.isNotEmpty) params['category'] = _selectedCategory;
      final res = await ApiService.get('/community/posts', queryParams: params);
      final data = res['data'];
      final list = data is List ? data : (data is Map ? (data['posts'] as List? ?? data['items'] as List? ?? const []) : const []);
      final parsed = list.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
      _page = nextPage;
      if (mounted) setState(() { _posts.addAll(parsed); _hasMore = parsed.length >= 20; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _like(String id) async {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_likedIds.contains(id)) {
        _likedIds.remove(id);
      } else {
        _likedIds.add(id);
      }
    });
    try {
      await ApiService.post('/community/posts/$id/like', {}, auth: true);
    } catch (_) {
      setState(() { if (_likedIds.contains(id)) _likedIds.remove(id); else _likedIds.add(id); });
    }
  }

  void _toggleSave(String id) {
    HapticFeedback.mediumImpact();
    setState(() { if (_savedIds.contains(id)) _savedIds.remove(id); else _savedIds.add(id); });
  }

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

  static const _categoryColors = {
    'beauty': Color(0xFFEC4899),
    'home': Color(0xFF0891B2),
    'fitness': Color(0xFF10B981),
    'tutoring': Color(0xFF8B5CF6),
    'photography': Color(0xFFF59E0B),
    'tech': Color(0xFF6366F1),
  };

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { HapticFeedback.mediumImpact(); context.push('/community/create'); },
        backgroundColor: const Color(0xFF0F766E),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Share Tip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      child: RefreshIndicator(
        onRefresh: () => _load(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: PremiumHeroHeader(
                title: 'Community',
                subtitle: 'Tips & insights from professionals',
                icon: Icons.people_rounded,
                gradient: const [Color(0xFF0F766E), Color(0xFF0891B2)],
                chips: [
                  if (!_loading) PremiumStatChip(label: '${_posts.length} posts', color: Colors.white, icon: Icons.article_rounded),
                ],
              ),
            ),
            // Category filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = _selectedCategory == cat.$1;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat.$1);
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0891B2)]) : null,
                          color: selected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade200),
                          boxShadow: selected ? AppShadows.md(const Color(0xFF0F766E)) : null,
                        ),
                        child: Text(
                          cat.$2,
                          style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            if (_loading && _posts.isEmpty)
              SliverToBoxAdapter(child: PremiumLoadingList(itemCount: 4, itemHeight: 160)),
            if (!_loading && _error != null && _posts.isEmpty)
              SliverToBoxAdapter(child: PremiumEmptyState(icon: Icons.error_outline, title: 'Could not load posts', subtitle: _error!, actionLabel: 'Retry', onAction: () => _load())),
            if (!_loading && _error == null && _posts.isEmpty)
              SliverToBoxAdapter(child: PremiumEmptyState(icon: Icons.people_rounded, title: 'No posts yet', subtitle: 'Be the first to share a tip with the community!', actionLabel: 'Share Tip', onAction: () => context.push('/community/create'), gradient: const [Color(0xFF0F766E), Color(0xFF0891B2)])),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == _posts.length) {
                      return _loading ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink();
                    }
                    final post = _posts[i];
                    final id = post['id']?.toString() ?? '';
                    final liked = _likedIds.contains(id);
                    final saved = _savedIds.contains(id);
                    final category = post['category']?.toString() ?? '';
                    final catColor = _categoryColors[category] ?? AppColors.primary;
                    final mediaUrls = post['media_urls'];
                    final List<String> images = mediaUrls is List ? mediaUrls.whereType<String>().toList() : [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: PremiumGlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: post['author_avatar'] != null ? CachedNetworkImageProvider(post['author_avatar'].toString()) : null,
                                  backgroundColor: catColor.withAlpha(30),
                                  child: post['author_avatar'] == null ? Text(
                                    (post['author_name']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                                    style: TextStyle(color: catColor, fontWeight: FontWeight.w800),
                                  ) : null,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(post['author_name']?.toString() ?? 'Professional', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(_timeAgo(post['created_at']?.toString()), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ])),
                                if (category.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: catColor.withAlpha(15), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: catColor.withAlpha(50))),
                                    child: Text(category, style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                              ]),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (post['title'] != null) Text(post['title'].toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
                                if (post['title'] != null) const SizedBox(height: AppSpacing.sm),
                                Text(post['content']?.toString() ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                            // Images
                            if (images.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.md),
                                child: SizedBox(
                                  height: 140,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                    itemCount: images.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (_, j) => ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      child: CachedNetworkImage(imageUrl: images[j], width: 140, height: 140, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ),
                            // Actions
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                              child: Row(children: [
                                _PostAction(icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: '${(post['likes_count'] as num? ?? 0) + (liked ? 1 : 0)}', color: liked ? Colors.red : Colors.grey.shade500, onTap: () => _like(id)),
                                const SizedBox(width: AppSpacing.lg),
                                _PostAction(icon: Icons.chat_bubble_outline_rounded, label: '${post['comments_count'] ?? 0}', color: Colors.grey.shade500, onTap: () { HapticFeedback.mediumImpact(); context.push('/community/posts/$id'); }),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _toggleSave(id),
                                  child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: saved ? AppColors.primary : Colors.grey.shade400, size: 22),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _posts.length + 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PostAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

