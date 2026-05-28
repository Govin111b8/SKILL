import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/skeleton_loader.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<Map<String, dynamic>> _collections = [];
  bool _loading = true;
  String? _error;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/collections', auth: true);
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['collections'] as List? ?? const [])
              : const [];
      _collections = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleSave(Map<String, dynamic> collection) async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to save collections.')));
      return;
    }
    final id = (collection['id'] ?? '').toString();
    final saved = collection['saved'] == true;
    try {
      if (saved) {
        await ApiService.delete('/collections/$id/save', auth: true);
      } else {
        await ApiService.post('/collections/$id/save', {}, auth: true);
      }
      setState(() => collection['saved'] = !saved);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update collection: $e')));
    }
  }

  void _showCollection(Map<String, dynamic> collection) {
    final professionals = (collection['professionals'] as List? ?? const []);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(collection['title']?.toString() ?? 'Collection', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (professionals.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: EmptyStateWidget(
                    icon: Icons.collections_bookmark_outlined,
                    title: 'No professionals yet',
                    subtitle: 'This collection is ready for professionals to be added.',
                  ),
                )
              else
                ...professionals.map((item) {
                  final pro = Map<String, dynamic>.from(item as Map);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: (pro['avatar_url'] ?? '').toString().isNotEmpty ? NetworkImage(pro['avatar_url'].toString()) : null,
                      child: (pro['avatar_url'] ?? '').toString().isEmpty ? Text((pro['name'] ?? '').toString().trim().isEmpty ? '?' : (pro['name'] ?? '').toString().trim()[0].toUpperCase()) : null,
                    ),
                    title: Text(pro['name']?.toString() ?? 'Professional'),
                    subtitle: Text(pro['category']?.toString() ?? pro['headline']?.toString() ?? ''),
                    trailing: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/professional/${pro['id']}'),
                      child: const Text('View'),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = {'All', ..._collections.map((e) => (e['category'] ?? 'Other').toString())}.toList();
    final visible = _selectedCategory == 'All'
        ? _collections
        : _collections.where((e) => (e['category'] ?? 'Other').toString() == _selectedCategory).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      iconColor: Colors.red,
                      title: 'Could not load collections',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    ),
                  ])
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 52,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: _selectedCategory == category,
                                  onSelected: (_) => setState(() => _selectedCategory = category),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (visible.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.collections_outlined,
                            title: 'No collections found',
                            subtitle: 'Try another category or save some collections to see them here.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final collection = visible[index];
                              final imageUrl = (collection['cover_image'] ?? collection['image_url'] ?? '').toString();
                              return GestureDetector(
                                onTap: () => _showCollection(collection),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: imageUrl.isEmpty
                                              ? Container(
                                                  color: Theme.of(context).colorScheme.primaryContainer,
                                                  child: const Center(child: Icon(Icons.image_outlined, size: 36)),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Row(children: [
                                            Expanded(
                                              child: Text(collection['title']?.toString() ?? 'Collection', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            ),
                                            IconButton(
                                              onPressed: () => _toggleSave(collection),
                                              icon: Icon(collection['saved'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: collection['saved'] == true ? Colors.red : null),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ]),
                                          Text('${collection['professional_count'] ?? 0} professionals'),
                                          Text(collection['category']?.toString() ?? 'General', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }, childCount: visible.length),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: .74,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
