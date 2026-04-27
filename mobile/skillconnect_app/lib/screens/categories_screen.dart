import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import 'search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final AuthProvider auth;
  const CategoriesScreen({super.key, required this.auth});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  final _fallback = [
    {'name': 'Plumbing', 'icon': '🔧', 'subs': ['Pipe Repair', 'Drain Cleaning', 'Fixture Install', 'Water Heater']},
    {'name': 'Electrical', 'icon': '⚡', 'subs': ['Wiring', 'Lighting', 'Panel Upgrade', 'Ceiling Fan']},
    {'name': 'Home Repair', 'icon': '🏠', 'subs': ['Painting', 'Carpentry', 'Drywall', 'Flooring']},
    {'name': 'Cleaning', 'icon': '🧹', 'subs': ['Deep Clean', 'Regular Clean', 'Move-In/Out', 'Office Clean']},
    {'name': 'Tutoring', 'icon': '📚', 'subs': ['Math', 'Science', 'Languages', 'Test Prep']},
    {'name': 'Beauty', 'icon': '💇', 'subs': ['Haircut', 'Makeup', 'Nails', 'Skincare']},
    {'name': 'Moving', 'icon': '📦', 'subs': ['Local Move', 'Long Distance', 'Packing', 'Storage']},
    {'name': 'Photography', 'icon': '📷', 'subs': ['Wedding', 'Portrait', 'Event', 'Product']},
    {'name': 'Music', 'icon': '🎵', 'subs': ['Guitar', 'Piano', 'Vocals', 'Production']},
    {'name': 'Health & Fitness', 'icon': '💪', 'subs': ['Personal Training', 'Yoga', 'Nutrition', 'Physiotherapy']},
    {'name': 'Technology', 'icon': '💻', 'subs': ['Web Development', 'Mobile Apps', 'IT Support', 'Data Recovery']},
    {'name': 'Other Services', 'icon': '🔨', 'subs': ['Gardening', 'Pet Care', 'Tailoring', 'Catering']},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.get('/categories');
      final list = data is List ? data : (data['categories'] ?? []);
      setState(() {
        _categories = (list as List).map((j) => Category.fromJson(j)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Categories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.isNotEmpty ? _categories.length : _fallback.length,
              itemBuilder: (_, i) {
                if (_categories.isNotEmpty) {
                  final cat = _categories[i];
                  return _buildCategoryTile(cat.name, cat.icon, cat.children.map((c) => c.name).toList());
                }
                final fb = _fallback[i];
                return _buildCategoryTile(fb['name'] as String, fb['icon'] as String, (fb['subs'] as List).cast<String>());
              },
            ),
    );
  }

  Widget _buildCategoryTile(String name, String icon, List<String> subs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: subs.map((sub) => ListTile(
          contentPadding: const EdgeInsets.only(left: 72, right: 16),
          title: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SearchScreen(auth: widget.auth, initialQuery: sub),
          )),
        )).toList(),
      ),
    );
  }
}
