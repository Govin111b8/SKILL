import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  final String professionalId;
  final bool isOwner;
  const PortfolioScreen({super.key, required this.professionalId, this.isOwner = false});

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
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/portfolio/${widget.professionalId}');
      _items = (res['data'] as List).map((e) => PortfolioItem.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Item?'),
      content: const Text('This portfolio item will be permanently deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
      ],
    ));
    if (confirm != true) return;

    try {
      await ApiService.delete('/portfolio/$id', auth: true);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mediaType,
                decoration: const InputDecoration(labelText: 'Media Type'),
                items: const [
                  DropdownMenuItem(value: 'image', child: Text('Image')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'certificate', child: Text('Certificate')),
                ],
                onChanged: (v) => setDialogState(() => mediaType = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Media URL', hintText: 'https://...')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
                try {
                  await ApiService.post('/portfolio', {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'media_type': mediaType,
                    'media_url': urlCtrl.text.trim(),
                  }, auth: true);
                  Navigator.pop(ctx);
                  _load();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added!'), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _items.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No portfolio items yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              // Media preview
                              Container(
                                height: 180,
                                width: double.infinity,
                                color: cs.primaryContainer.withAlpha(60),
                                child: item.mediaUrl.startsWith('http')
                                    ? Image.network(item.mediaUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _mediaPlaceholder(item.mediaType, cs))
                                    : _mediaPlaceholder(item.mediaType, cs),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(6)),
                                      child: Text(item.mediaType.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.primary)),
                                    ),
                                    const Spacer(),
                                    if (widget.isOwner)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () => _deleteItem(item.id),
                                      ),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  if (item.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(item.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ]),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _mediaPlaceholder(String type, ColorScheme cs) {
    final icon = type == 'video' ? Icons.videocam : type == 'certificate' ? Icons.verified : Icons.image;
    return Center(child: Icon(icon, size: 48, color: cs.primary.withAlpha(120)));
  }
}
