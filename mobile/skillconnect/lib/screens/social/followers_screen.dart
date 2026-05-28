import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Follow> _followers = [];
  List<Follow> _following = [];
  final Set<String> _followingIds = <String>{};
  final Set<String> _busyIds = <String>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _fetchFollows('/social/followers', allowMissing: true),
        _fetchFollows('/social/following'),
      ]);
      if (!mounted) return;
      setState(() {
        _followers = results[0];
        _following = results[1];
        _followingIds
          ..clear()
          ..addAll(_following.map((item) => item.followingId).where((id) => id.isNotEmpty));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<List<Follow>> _fetchFollows(String path, {bool allowMissing = false}) async {
    try {
      final res = await ApiService.get(path, auth: true);
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['results'] as List? ?? const [])
              : const [];
      return list
          .whereType<Map>()
          .map((item) => Follow.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on ApiException catch (e) {
      if (allowMissing && e.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<void> _toggleFollow(Follow follow) async {
    final targetId = follow.followingId;
    if (targetId.isEmpty || _busyIds.contains(targetId)) return;
    final isFollowing = _followingIds.contains(targetId);
    setState(() => _busyIds.add(targetId));
    try {
      if (isFollowing) {
        await ApiService.delete('/social/unfollow/$targetId', auth: true);
      } else {
        await ApiService.post('/social/follow/$targetId', {}, auth: true);
      }
      if (!mounted) return;
      setState(() {
        if (isFollowing) {
          _followingIds.remove(targetId);
          _following = _following.where((item) => item.followingId != targetId).toList();
        } else {
          _followingIds.add(targetId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFollowing ? 'Unfollowed successfully.' : 'Now following ${follow.followingName ?? 'professional'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update follow status: $e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(targetId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connections'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? _buildSkeletonList()
              : _error != null
                  ? ListView(
                      children: [
                        EmptyStateWidget(
                          icon: Icons.people_outline_rounded,
                          iconColor: Colors.red,
                          title: 'Could not load connections',
                          subtitle: _error!,
                          actionLabel: 'Retry',
                          onAction: _load,
                        ),
                      ],
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_followers, emptyTitle: 'No followers yet', emptySubtitle: 'Your followers will show up here once people start following your work.'),
                        _buildList(_following, emptyTitle: 'Not following anyone yet', emptySubtitle: 'Follow professionals to keep up with their latest stories and updates.'),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, __) => Row(
        children: const [
          SkeletonLoader(width: 56, height: 56, radius: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 140, height: 14),
                SizedBox(height: 8),
                SkeletonLoader(width: 110, height: 12),
                SizedBox(height: 8),
                SkeletonLoader(width: 80, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonLoader(width: 88, height: 36, radius: 18),
        ],
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemCount: 6,
    );
  }

  Widget _buildList(List<Follow> items, {required String emptyTitle, required String emptySubtitle}) {
    if (items.isEmpty) {
      return ListView(
        children: [
          EmptyStateWidget(
            icon: Icons.people_outline_rounded,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final follow = items[index];
        final isFollowing = _followingIds.contains(follow.followingId);
        final isBusy = _busyIds.contains(follow.followingId);
        final initialsSource = (follow.followingName ?? '').trim();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: (follow.followingAvatar ?? '').isNotEmpty ? CachedNetworkImageProvider(follow.followingAvatar!) : null,
                child: (follow.followingAvatar ?? '').isEmpty
                    ? Text(initialsSource.isEmpty ? '?' : initialsSource[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      follow.followingName ?? 'Professional',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((follow.followingHeadline ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        follow.followingHeadline!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (follow.followingRating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(follow.followingRating!.toStringAsFixed(1), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (follow.followingId.isNotEmpty)
                isFollowing
                    ? OutlinedButton(
                        onPressed: isBusy ? null : () => _toggleFollow(follow),
                        child: Text(isBusy ? '...' : 'Unfollow'),
                      )
                    : FilledButton.tonal(
                        onPressed: isBusy ? null : () => _toggleFollow(follow),
                        child: Text(isBusy ? '...' : 'Follow'),
                      ),
            ],
          ),
        );
      },
    );
  }
}
