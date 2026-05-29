import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/skeleton_loader.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<_CollectionSummary> _collections = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/collections', auth: true);
      final data = response['data'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _collections = data
            .whereType<Map>()
            .map((item) => _CollectionSummary.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    bool isPublic = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Create collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Collection name',
                  hintText: 'Favorites, Wedding ideas, Trusted pros…',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public collection'),
                subtitle: const Text('Anyone with access can view it.'),
                value: isPublic,
                onChanged: (value) => setModalState(() => isPublic = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  await ApiService.post('/collections', {
                    'name': name,
                    'is_public': isPublic,
                  }, auth: true);
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not create collection: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      await _loadCollections();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection created.')),
      );
    }
  }

  Future<void> _deleteCollection(_CollectionSummary collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text('"${collection.name}" will be removed permanently.'),
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
      await ApiService.delete('/collections/${collection.id}', auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${collection.name}.')),
      );
      await _loadCollections();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete collection: $e')),
      );
    }
  }

  Future<void> _openCollection(_CollectionSummary summary) async {
    try {
      final response = await ApiService.get('/collections/${summary.id}', auth: true);
      final data = Map<String, dynamic>.from(response['data'] as Map? ?? const {});
      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _CollectionItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        builder: (context) {
          var currentItems = List<_CollectionItem>.from(items);
          return StatefulBuilder(
            builder: (context, setModalState) => SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.78,
                  child: Column(
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
                        data['name']?.toString() ?? summary.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${currentItems.length} saved item${currentItems.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (currentItems.isEmpty)
                        const Expanded(
                          child: EmptyStateWidget(
                            icon: Icons.bookmark_outline_rounded,
                            title: 'Nothing saved yet',
                            subtitle: 'Add professionals or services to this collection and they will show up here.',
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: currentItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final item = currentItems[index];
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                                          ? NetworkImage(item.avatarUrl!)
                                          : null,
                                      child: item.avatarUrl == null || item.avatarUrl!.isEmpty
                                          ? Text(item.title.isEmpty ? '?' : item.title[0].toUpperCase())
                                          : null,
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          if (item.subtitle?.isNotEmpty == true) ...[
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(item.subtitle!),
                                          ],
                                          if (item.location?.isNotEmpty == true) ...[
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              item.location!,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                          const SizedBox(height: AppSpacing.sm),
                                          Wrap(
                                            spacing: AppSpacing.sm,
                                            runSpacing: AppSpacing.sm,
                                            children: [
                                              Chip(
                                                label: Text(item.itemTypeLabel),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                              if (item.averageRating != null)
                                                Chip(
                                                  avatar: const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                                                  label: Text(item.averageRating!.toStringAsFixed(1)),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'view' && item.professionalId != null) {
                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                          Navigator.pushNamed(context, '/professional/${item.professionalId}');
                                        }
                                        if (value == 'remove') {
                                          try {
                                            await ApiService.delete(
                                              '/collections/${summary.id}/items/${item.id}',
                                              auth: true,
                                            );
                                            setModalState(() {
                                              currentItems = currentItems.where((entry) => entry.id != item.id).toList();
                                            });
                                            await _loadCollections();
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not remove item: $e')),
                                            );
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (item.professionalId != null)
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Text('View profile'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remove from collection'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open collection: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isLoggedIn) {
      return const Scaffold(
        body: EmptyStateWidget(
          icon: Icons.lock_outline_rounded,
          title: 'Login required',
          subtitle: 'Sign in to manage your collections.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collections'),
        actions: [
          IconButton(
            tooltip: 'Create collection',
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCollections,
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
                        title: 'Could not load collections',
                        subtitle: _error!,
                        actionLabel: 'Retry',
                        onAction: _loadCollections,
                      ),
                    ],
                  )
                : _collections.isEmpty
                    ? ListView(
                        children: [
                          EmptyStateWidget(
                            icon: Icons.collections_bookmark_outlined,
                            title: 'Start your first collection',
                            subtitle: 'Save favorite professionals and service ideas into tidy collections.',
                            actionLabel: 'Create collection',
                            onAction: _showCreateDialog,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _collections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final collection = _collections[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            onTap: () => _openCollection(collection),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primaryContainer.withAlpha(220),
                                    Theme.of(context).colorScheme.surface,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                boxShadow: AppShadows.sm(Colors.black),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withAlpha(20),
                                          borderRadius: BorderRadius.circular(AppRadius.lg),
                                        ),
                                        child: Icon(
                                          Icons.folder_special_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const Spacer(),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'delete') _deleteCollection(collection);
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete collection'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    collection.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      Chip(
                                        label: Text('${collection.itemCount} item${collection.itemCount == 1 ? '' : 's'}'),
                                      ),
                                      Chip(
                                        label: Text(collection.isPublic ? 'Public' : 'Private'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    collection.updatedLabel,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _CollectionSummary {
  final String id;
  final String name;
  final bool isPublic;
  final int itemCount;
  final DateTime? updatedAt;

  const _CollectionSummary({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.itemCount,
    required this.updatedAt,
  });

  factory _CollectionSummary.fromJson(Map<String, dynamic> json) {
    return _CollectionSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Untitled collection').toString(),
      isPublic: json['is_public'] == true,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }

  String get updatedLabel {
    if (updatedAt == null) return 'Updated recently';
    final now = DateTime.now();
    final diff = now.difference(updatedAt!);
    if (diff.inDays > 0) return 'Updated ${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours > 0) return 'Updated ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes > 0) return 'Updated ${diff.inMinutes} min ago';
    return 'Updated just now';
  }
}

class _CollectionItem {
  final String id;
  final String itemType;
  final String title;
  final String? subtitle;
  final String? location;
  final String? avatarUrl;
  final double? averageRating;
  final String? professionalId;

  const _CollectionItem({
    required this.id,
    required this.itemType,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.avatarUrl,
    required this.averageRating,
    required this.professionalId,
  });

  factory _CollectionItem.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['average_rating'];
    return _CollectionItem(
      id: (json['id'] ?? '').toString(),
      itemType: (json['item_type'] ?? 'item').toString(),
      title: (json['professional_name'] ?? json['title'] ?? 'Saved item').toString(),
      subtitle: json['headline']?.toString(),
      location: json['location']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      averageRating: ratingRaw == null ? null : double.tryParse(ratingRaw.toString()),
      professionalId: json['item_type'] == 'professional' ? json['item_id']?.toString() : null,
    );
  }

  String get itemTypeLabel {
    switch (itemType) {
      case 'professional':
        return 'Professional';
      case 'service':
        return 'Service';
      default:
        return 'Saved item';
    }
  }
}
