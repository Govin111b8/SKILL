import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _reels = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _page = 1;
        _hasMore = true;
        _error = null;
      });
    }
    try {
      final res = await ApiService.get('/reels', auth: true, queryParams: {'page': _page.toString()});
      final data = res['data'];
      final items = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['reels'] as List? ?? const [])
              : const [];
      final parsed = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _reels = parsed;
        } else {
          _reels.addAll(parsed);
        }
        _hasMore = parsed.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
    await _load(refresh: false);
  }

  Future<void> _toggleLike(Map<String, dynamic> reel) async {
    final id = (reel['id'] ?? '').toString();
    final liked = reel['liked'] == true;
    setState(() {
      reel['liked'] = !liked;
      reel['like_count'] = ((reel['like_count'] ?? 0) as num).toInt() + (liked ? -1 : 1);
    });
    try {
      await ApiService.post('/reels/$id/like', {}, auth: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        reel['liked'] = liked;
        reel['like_count'] = ((reel['like_count'] ?? 0) as num).toInt() + (liked ? 1 : -1);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not like reel: $e')));
    }
  }

  Future<void> _shareReel(Map<String, dynamic> reel) async {
    final id = (reel['id'] ?? '').toString();
    final text = 'Check out this pro on SkillConnect: ${reel['title'] ?? ''}';
    try {
      await ApiService.post('/reels/$id/share', {}, auth: true);
    } catch (_) {}
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Reels')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.video_library_outlined,
                      iconColor: Colors.red,
                      title: 'Could not load reels',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    ),
                  ]),
                )
              : _reels.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(children: const [
                        EmptyStateWidget(
                          icon: Icons.movie_filter_outlined,
                          title: 'No reels yet',
                          subtitle: 'Fresh professional stories and transformations will show up here.',
                        ),
                      ]),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _reels.length,
                      onPageChanged: (index) {
                        setState(() => _activeIndex = index);
                        if (index >= _reels.length - 1) _loadMore();
                      },
                      itemBuilder: (context, index) {
                        final reel = _reels[index];
                        final thumbnail = (reel['thumbnail_url'] ?? reel['image_url'] ?? '').toString();
                        final professionalId = (reel['professional_id'] ?? '').toString();
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            thumbnail.isEmpty
                                ? Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: const Center(child: Icon(Icons.play_circle_fill_rounded, size: 84)),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: thumbnail,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      child: const Center(child: Icon(Icons.broken_image_outlined, size: 56)),
                                    ),
                                  ),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xD9000000)],
                                ),
                              ),
                            ),
                            // Replace this placeholder with an actual video_player implementation when video playback is enabled.
                            const Center(child: Icon(Icons.play_circle_fill_rounded, size: 84, color: Colors.white70)),
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 28,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reel['professional_name']?.toString() ?? 'Professional', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                                        const SizedBox(height: 6),
                                        Text(reel['service_category']?.toString() ?? reel['category']?.toString() ?? 'Service', style: const TextStyle(color: Colors.white70)),
                                        const SizedBox(height: 6),
                                        Text(reel['caption']?.toString() ?? reel['title']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        FilledButton(
                                          onPressed: () => Navigator.pushNamed(context, '/professional/$professionalId'),
                                          child: const Text('Book this Pro'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedScale(
                                        scale: _activeIndex == index && reel['liked'] == true ? 1.15 : 1,
                                        duration: const Duration(milliseconds: 180),
                                        child: IconButton(
                                          onPressed: () => _toggleLike(reel),
                                          icon: Icon(reel['liked'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: reel['liked'] == true ? Colors.redAccent : Colors.white, size: 30),
                                        ),
                                      ),
                                      Text('${reel['like_count'] ?? 0}', style: const TextStyle(color: Colors.white)),
                                      const SizedBox(height: 8),
                                      IconButton(
                                        onPressed: () => _shareReel(reel),
                                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 28),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (_loadingMore && index == _reels.length - 1)
                              const Positioned(top: 24, right: 24, child: CircularProgressIndicator()),
                          ],
                        );
                      },
                    ),
    );
  }
}
