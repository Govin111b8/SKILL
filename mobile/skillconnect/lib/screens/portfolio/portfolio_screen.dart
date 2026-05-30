import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class PortfolioScreen extends StatefulWidget {
  final String professionalId;
  final bool isOwner;
  const PortfolioScreen(
      {super.key, required this.professionalId, this.isOwner = false});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<PortfolioItem> _items = [];
  bool _loading = true;
  String? _error;

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
      final res = await ApiService.get('/portfolio/${widget.professionalId}');
      _items = (res['data'] as List)
          .map((e) => PortfolioItem.fromJson(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Delete Item?'),
              content: const Text(
                  'This portfolio item will be permanently deleted.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: const Text('Delete')),
              ],
            ));
    if (confirm != true) return;

    try {
      await ApiService.delete('/portfolio/$id', auth: true);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Item deleted'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String mediaType = 'image';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Portfolio Item'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Title')),
              const SizedBox(height: AppSpacing.md),
              TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 3),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: mediaType,
                decoration:
                    const InputDecoration(labelText: 'Media Type'),
                items: const [
                  DropdownMenuItem(value: 'image', child: Text('Image')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(
                      value: 'certificate',
                      child: Text('Certificate')),
                ],
                onChanged: (v) =>
                    setDialogState(() => mediaType = v!),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Media URL',
                      hintText: 'https://...')),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    descCtrl.text.trim().isEmpty ||
                    urlCtrl.text.trim().isEmpty) return;
                try {
                  await ApiService.post(
                      '/portfolio',
                      {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'media_type': mediaType,
                        'media_url': urlCtrl.text.trim(),
                      },
                      auth: true);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Item added!'),
                            backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (!ctx.mounted) return;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      descCtrl.dispose();
      urlCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Add Item',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const PremiumLoadingList(
                      itemCount: 4, itemHeight: 240)
                  : _error != null
                      ? Center(
                          child: PremiumEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Could not load portfolio',
                            subtitle: _error!,
                            actionLabel: 'Retry',
                            onAction: _load,
                            gradient: const [
                              AppColors.error,
                              Color(0xFFFF6B6B)
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(
                              child: PremiumEmptyState(
                                icon: Icons.photo_library_outlined,
                                title: 'No portfolio items yet',
                                subtitle:
                                    'Showcase your best work to attract more customers.',
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    0,
                                    AppSpacing.lg,
                                    100),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.lg),
                                itemBuilder: (_, i) {
                                  final item = _items[i];
                                  return _PortfolioCard(
                                    item: item,
                                    isOwner: widget.isOwner,
                                    onDelete: () =>
                                        _deleteItem(item.id),
                                  );
                                },
                              ),
                            ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Portfolio',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
              Text(
                '${_items.length} item${_items.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _mediaPlaceholder(String type, ColorScheme cs) {
    final icon = type == 'video'
        ? Icons.videocam_rounded
        : type == 'certificate'
            ? Icons.verified_rounded
            : Icons.image_rounded;
    return Container(
      color: AppColors.primary.withAlpha(12),
      child: Center(
        child: Icon(icon, size: 48, color: AppColors.primary.withAlpha(120)),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  final bool isOwner;
  final VoidCallback onDelete;
  const _PortfolioCard(
      {required this.item,
      required this.isOwner,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeColor = item.mediaType == 'video'
        ? AppColors.error
        : item.mediaType == 'certificate'
            ? AppColors.success
            : AppColors.primary;

    return PremiumGlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: item.mediaUrl.startsWith('http')
                    ? Image.network(
                        item.mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primary.withAlpha(12),
                          child: Center(
                            child: Icon(
                              _typeIcon(item.mediaType),
                              size: 48,
                              color: AppColors.primary.withAlpha(120),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primary.withAlpha(12),
                        child: Center(
                          child: Icon(_typeIcon(item.mediaType),
                              size: 48,
                              color: AppColors.primary.withAlpha(120)),
                        ),
                      ),
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.sm(typeColor),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_typeIcon(item.mediaType),
                        size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      item.mediaType.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ]),
                ),
              ),
              if (isOwner)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  if (item.description != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.description!,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.4)),
                  ],
                ]),
          ),
        ]),
      ),
    );
  }

  IconData _typeIcon(String type) => type == 'video'
      ? Icons.videocam_rounded
      : type == 'certificate'
          ? Icons.verified_rounded
          : Icons.image_rounded;
}
