import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Follow> _followers = [];
  List<Follow> _following = [];
  final Set<String> _followingIds = <String>{};
  final Set<String> _busyIds = <String>{};
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)..addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
      return list.whereType<Map>().map((item) => Follow.fromJson(Map<String, dynamic>.from(item))).toList();
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

  List<Follow> _filteredItems(List<Follow> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      final name = (item.followingName ?? '').toLowerCase();
      final headline = (item.followingHeadline ?? '').toLowerCase();
      return name.contains(query) || headline.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabController.index;
    final selectedItems = currentIndex == 0 ? _followers : _following;
    final filteredItems = _filteredItems(selectedItems);

    return DefaultTabController(
      length: 2,
      child: PremiumScrollScaffold(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.huge),
            children: [
              PremiumHeroHeader(
                title: 'My Network',
                subtitle: 'Followers & Following',
                icon: Icons.people_alt_rounded,
                gradient: AppColors.primaryGradient,
                chips: [
                  PremiumStatChip(
                    label: '${_followers.length} Followers',
                    color: Colors.white,
                    icon: Icons.favorite_rounded,
                  ),
                  PremiumStatChip(
                    label: '${_following.length} Following',
                    color: Colors.white,
                    icon: Icons.outgoing_mail_rounded,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumSearchField(
                  hint: 'Search people in your network',
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  suffix: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PremiumGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.md(AppColors.primary),
                    ),
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.surfaceDark.withAlpha(160),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Followers'),
                      Tab(text: 'Following'),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PremiumLoadingList(itemCount: 6, itemHeight: 104),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PremiumEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Could not load connections',
                    subtitle: _error!,
                    actionLabel: 'Retry',
                    onAction: _load,
                    gradient: AppColors.warmGradient,
                  ),
                )
              else ...[
                PremiumSectionTitle(
                  title: currentIndex == 0 ? 'Followers' : 'Following',
                  subtitle: _searchQuery.isEmpty
                      ? 'People connected to your professional identity.'
                      : 'Showing matches for "$_searchQuery"',
                  trailing: PremiumStatusPill(
                    label: '${filteredItems.length}',
                    color: AppColors.primary,
                  ),
                ),
                if (filteredItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: PremiumEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: currentIndex == 0 ? 'No followers yet' : 'Not following anyone yet',
                      subtitle: currentIndex == 0
                          ? 'Your followers will show up here once people start following your work.'
                          : 'Follow professionals to keep up with their latest stories and updates.',
                    ),
                  )
                else
                  ...filteredItems.map((follow) => Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                        child: _buildPersonCard(follow),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard(Follow follow) {
    final isFollowing = _followingIds.contains(follow.followingId);
    final isBusy = _busyIds.contains(follow.followingId);
    final initialsSource = (follow.followingName ?? '').trim();

    return PremiumGlassCard(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              boxShadow: AppShadows.sm(AppColors.primary),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: (follow.followingAvatar ?? '').isNotEmpty ? CachedNetworkImageProvider(follow.followingAvatar!) : null,
                child: (follow.followingAvatar ?? '').isEmpty
                    ? Text(
                        initialsSource.isEmpty ? '?' : initialsSource[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  follow.followingName ?? 'Professional',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                if ((follow.followingHeadline ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    follow.followingHeadline!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (follow.followingRating != null) ...[
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        follow.followingRating!.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ] else
                      const PremiumStatusPill(label: 'New connection', color: AppColors.accent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (follow.followingId.isNotEmpty)
            isFollowing
                ? GestureDetector(
                    onTap: isBusy
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _toggleFollow(follow);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.error.withAlpha(140)),
                        color: AppColors.error.withAlpha(18),
                      ),
                      child: Text(
                        isBusy ? '...' : 'Unfollow',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                : PremiumGradientButton(
                    label: isBusy ? '...' : 'Follow',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: () => _toggleFollow(follow),
                  ),
        ],
      ),
    );
  }
}
