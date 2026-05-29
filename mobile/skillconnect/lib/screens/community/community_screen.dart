import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/skeleton_loader.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  static const List<String> _tabs = [
    'All',
    'Beauty',
    'Home Services',
    'Fitness',
    'Tutors',
    'Photography',
  ];

  late final TabController _tabController;
  List<_CommunityPostItem> _posts = [];
  bool _loading = true;
  String? _error;
  bool _mineOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) _loadPosts();
      });
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final selectedCategory = _tabController.index == 0 ? null : _tabs[_tabController.index];
      final response = await ApiService.get(
        '/community/posts',
        queryParams: {
          'limit': '50',
          if (selectedCategory != null) 'category': selectedCategory,
        },
      );
      final auth = context.read<AuthService>();
      final currentUserId = auth.user?['id']?.toString();
      final rows = (response['data'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _CommunityPostItem.fromJson(Map<String, dynamic>.from(item)))
          .where((post) => !_mineOnly || (currentUserId != null && post.authorId == currentUserId))
          .toList();

      if (!mounted) return;
      setState(() => _posts = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleMineOnly(bool value) async {
    setState(() => _mineOnly = value);
    await _loadPosts();
  }

  Future<void> _showComposer() async {
    final auth = context.read<AuthService>();
    if (!auth.isProfessional) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only professionals can publish community tips.')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final mediaCtrl = TextEditingController();
    String category = _tabController.index == 0 ? _tabs[1] : _tabs[_tabController.index];

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Share a tip',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'How to prepare your home for AC servicing',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    hintText: 'Share a practical tip your customers will love.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _tabs.skip(1).map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (value) {
                    if (value != null) setModalState(() => category = value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: mediaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty || content.isEmpty) return;

                      try {
                        await ApiService.post('/community/posts', {
                          'title': title,
                          'content': content,
                          'category': category,
                          'media_urls': mediaCtrl.text.trim().isEmpty ? [] : [mediaCtrl.text.trim()],
                        }, auth: true);
                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not publish post: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Publish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true) {
      await _loadPosts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community post published.')),
      );
    }
  }

  Future<void> _toggleLike(_CommunityPostItem post) async {
    final index = _posts.indexWhere((entry) => entry.id == post.id);
    if (index < 0) return;

    final updated = post.copyWith(
      liked: !post.liked,
      likesCount: post.likesCount + (post.liked ? -1 : 1),
    );
    setState(() => _posts[index] = updated);

    try {
      final response = await ApiService.post('/community/posts/${post.id}/like', {}, auth: true);
      final liked = response['liked'] == true;
      if (!mounted) return;
      setState(() {
        _posts[index] = updated.copyWith(
          liked: liked,
          likesCount: post.likesCount + (liked ? 1 : 0),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _posts[index] = post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update like: $e')),
      );
    }
  }

  Future<void> _deletePost(_CommunityPostItem post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('"${post.title}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.delete('/community/posts/${post.id}', auth: true);
      if (!mounted) return;
      setState(() => _posts.removeWhere((entry) => entry.id == post.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete post: $e')),
      );
    }
  }

  Future<void> _openPost(_CommunityPostItem post) async {
    final auth = context.read<AuthService>();
    final isOwner = auth.user?['id']?.toString() == post.authorId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.coverImage?.isNotEmpty == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: CachedNetworkImage(
                      imageUrl: post.coverImage!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 220,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 220,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                if (post.coverImage?.isNotEmpty == true) const SizedBox(height: AppSpacing.xl),
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                          ? NetworkImage(post.authorAvatar!)
                          : null,
                      child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                          ? Text(post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(post.category, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                    Text(post.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(post.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Share.share('${post.title}\n\n${post.content}'),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                    ),
                    if (post.professionalId != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/professional/${post.professionalId}');
                        },
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('View profile'),
                      ),
                    if (isOwner)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deletePost(post);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final canPost = auth.isProfessional;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((label) => Tab(text: label)).toList(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: FilterChip(
              selected: _mineOnly,
              onSelected: (_) => _toggleMineOnly(!_mineOnly),
              label: const Text('My posts'),
            ),
          ),
          IconButton(
            tooltip: 'New post',
            onPressed: canPost ? _showComposer : null,
            icon: const Icon(Icons.add_comment_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _loading
            ? ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                itemBuilder: (_, __) => const SkeletonBookingCard(),
              )
            : _error != null
                ? ListView(
                    children: [
                      EmptyStateWidget(
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.error,
                        title: 'Could not load community',
                        subtitle: _error!,
                        actionLabel: 'Retry',
                        onAction: _loadPosts,
                      ),
                    ],
                  )
                : _posts.isEmpty
                    ? ListView(
                        children: [
                          EmptyStateWidget(
                            icon: Icons.forum_outlined,
                            title: _mineOnly ? 'No posts from you yet' : 'No posts yet',
                            subtitle: _mineOnly
                                ? 'Share your first expert tip to start your community presence.'
                                : 'Fresh tips, ideas and updates from professionals will show up here.',
                            actionLabel: canPost ? 'Write a post' : null,
                            onAction: canPost ? _showComposer : null,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          final isOwner = auth.user?['id']?.toString() == post.authorId;
                          return InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            onTap: () => _openPost(post),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                boxShadow: AppShadows.sm(Colors.black),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.coverImage?.isNotEmpty == true)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                                      child: CachedNetworkImage(
                                        imageUrl: post.coverImage!,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          height: 180,
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          height: 180,
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          child: const Icon(Icons.broken_image_outlined),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                                                  ? NetworkImage(post.authorAvatar!)
                                                  : null,
                                              child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                                                  ? Text(post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase())
                                                  : null,
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                  Text(post.authorHeadline ?? post.category),
                                                ],
                                              ),
                                            ),
                                            Text(post.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                                            if (isOwner)
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'delete') _deletePost(post);
                                                },
                                                itemBuilder: (context) => const [
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('Delete post'),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        Text(
                                          post.title,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          post.content,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          children: [
                                            Chip(
                                              avatar: const Icon(Icons.sell_outlined, size: 16),
                                              label: Text(post.category),
                                            ),
                                            Chip(
                                              avatar: const Icon(Icons.favorite_rounded, size: 16, color: Colors.pink),
                                              label: Text('${post.likesCount} likes'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Row(
                                          children: [
                                            IconButton.filledTonal(
                                              onPressed: () => _toggleLike(post),
                                              icon: Icon(post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            IconButton.filledTonal(
                                              onPressed: () => Share.share('${post.title}\n\n${post.content}'),
                                              icon: const Icon(Icons.share_rounded),
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () => _openPost(post),
                                              child: const Text('Read more'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: _showComposer,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Post'),
            )
          : null,
    );
  }
}

class _CommunityPostItem {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final String category;
  final String authorName;
  final String? authorAvatar;
  final String? authorHeadline;
  final String? professionalId;
  final List<String> mediaUrls;
  final int likesCount;
  final bool liked;
  final DateTime? createdAt;

  const _CommunityPostItem({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.category,
    required this.authorName,
    required this.authorAvatar,
    required this.authorHeadline,
    required this.professionalId,
    required this.mediaUrls,
    required this.likesCount,
    required this.liked,
    required this.createdAt,
  });

  factory _CommunityPostItem.fromJson(Map<String, dynamic> json) {
    return _CommunityPostItem(
      id: (json['id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled post').toString(),
      content: (json['content'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      authorName: (json['author_name'] ?? 'Professional').toString(),
      authorAvatar: json['author_avatar']?.toString(),
      authorHeadline: json['author_headline']?.toString(),
      professionalId: json['professional_id']?.toString(),
      mediaUrls: _parseMediaUrls(json['media_urls']),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      liked: json['user_liked'] == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  _CommunityPostItem copyWith({
    int? likesCount,
    bool? liked,
  }) {
    return _CommunityPostItem(
      id: id,
      authorId: authorId,
      title: title,
      content: content,
      category: category,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorHeadline: authorHeadline,
      professionalId: professionalId,
      mediaUrls: mediaUrls,
      likesCount: likesCount ?? this.likesCount,
      liked: liked ?? this.liked,
      createdAt: createdAt,
    );
  }

  String? get coverImage => mediaUrls.isEmpty ? null : mediaUrls.first;

  String get timeAgo {
    if (createdAt == null) return 'Recently';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  static List<String> _parseMediaUrls(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
        }
      } catch (_) {
        return [raw];
      }
    }
    return const [];
  }
}
