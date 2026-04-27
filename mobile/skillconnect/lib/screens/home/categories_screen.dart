import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/categories');
      _categories = (res['data'] as List).map((e) => Category.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final icons = [Icons.plumbing, Icons.electrical_services, Icons.format_paint, Icons.carpenter, Icons.cleaning_services, Icons.local_shipping, Icons.grass, Icons.computer];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: Icon(icons[i % icons.length], color: Theme.of(context).colorScheme.primary),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: cat.description != null ? Text(cat.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                    children: cat.children.map((sub) => ListTile(
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      title: Text(sub.name),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {}, // TODO: search by subcategory
                    )).toList(),
                  ),
                );
              },
            ),
    );
  }
}
