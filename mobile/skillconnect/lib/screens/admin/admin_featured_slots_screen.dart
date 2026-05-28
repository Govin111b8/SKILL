import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class AdminFeaturedSlotsScreen extends StatefulWidget {
  const AdminFeaturedSlotsScreen({super.key});

  @override
  State<AdminFeaturedSlotsScreen> createState() => _AdminFeaturedSlotsScreenState();
}

class _AdminFeaturedSlotsScreenState extends State<AdminFeaturedSlotsScreen> {
  List<Map<String, dynamic>> _slots = [];
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
      final res = await ApiService.get('/admin/featured-slots', auth: true);
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['slots'] as List? ?? const [])
              : const [];
      _slots = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _remove(String id) async {
    try {
      await ApiService.delete('/admin/featured-slots/$id', auth: true);
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Featured slot removed.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove slot: $e')));
    }
  }

  Future<void> _addFeatured() async {
    final idController = TextEditingController();
    final categoryController = TextEditingController();
    final positionController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add featured professional'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: idController, decoration: const InputDecoration(labelText: 'Professional ID')),
          const SizedBox(height: 12),
          TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
          const SizedBox(height: 12),
          TextField(controller: positionController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Position (1-6)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.post('/admin/featured-slots', {
        'professional_id': idController.text.trim(),
        'category': categoryController.text.trim(),
        'position': int.tryParse(positionController.text.trim()) ?? 1,
      }, auth: true);
      if (!mounted) return;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Featured professional added.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add featured slot: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Featured Slots')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addFeatured, icon: const Icon(Icons.add_rounded), label: const Text('Add Featured')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [EmptyStateWidget(icon: Icons.star_outline_rounded, iconColor: Colors.red, title: 'Could not load featured slots', subtitle: _error!, actionLabel: 'Retry', onAction: _load)])
                : _slots.isEmpty
                    ? ListView(children: const [EmptyStateWidget(icon: Icons.star_outline_rounded, title: 'No featured professionals', subtitle: 'Add up to 6 featured professionals for homepage placement.')])
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .85),
                        itemCount: _slots.length,
                        itemBuilder: (context, index) {
                          final slot = _slots[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Position ${slot['position'] ?? index + 1}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text(slot['professional_name']?.toString() ?? 'Professional', style: const TextStyle(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text(slot['category']?.toString() ?? 'Category'),
                              const SizedBox(height: 12),
                              Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: () => _remove((slot['id'] ?? '').toString()), child: const Text('Remove'))),
                            ]),
                          );
                        },
                      ),
      ),
    );
  }
}
