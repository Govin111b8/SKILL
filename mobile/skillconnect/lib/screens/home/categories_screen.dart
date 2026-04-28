import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'category_detail_screen.dart';

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

  void _openCategory(Category cat, {bool isRoot = false}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CategoryDetailScreen(
        categoryId: cat.id,
        categoryName: cat.name,
        categoryDescription: cat.description,
        isRoot: isRoot,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final iconList = [Icons.home_repair_service, Icons.event, Icons.person, Icons.computer, Icons.palette, Icons.plumbing, Icons.electrical_services, Icons.format_paint];
    final colorList = [const Color(0xFF6366F1), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFF3B82F6), const Color(0xFFEC4899), const Color(0xFF8B5CF6), const Color(0xFF14B8A6), const Color(0xFFF97316)];

    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0,
              ),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final color = colorList[i % colorList.length];
                final icon = iconList[i % iconList.length];
                final proCount = cat.children.fold<int>(0, (s, c) => s + (c.children.length + 1));
                return GestureDetector(
                  onTap: () => _openCategory(cat, isRoot: cat.parentId == null),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withAlpha(200)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Stack(children: [
                      Positioned(top: -12, right: -12, child: Icon(icon, size: 80, color: Colors.white.withAlpha(30))),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                          Icon(icon, color: Colors.white, size: 28),
                          const SizedBox(height: 8),
                          Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(cat.children.isNotEmpty ? '${cat.children.length} services' : 'View professionals',
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
