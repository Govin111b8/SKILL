import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Professional> _topProfessionals = [];
  List<Category> _categories = [];
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
      final results = await Future.wait([
        ApiService.get('/search', queryParams: {'sort_by': 'rating', 'limit': '10'}),
        ApiService.get('/categories'),
      ]);
      _topProfessionals = (results[0]['data'] as List).map((e) => Professional.fromJson(e)).toList();
      _categories = (results[1]['data'] as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.handyman, color: cs.primary),
          const SizedBox(width: 8),
          const Text('SkillConnect', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Could not connect to server', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Hero banner
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cs.primary, cs.primary.withAlpha(180)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Find Skilled\nProfessionals', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Connect with verified experts in your area', style: TextStyle(color: Colors.white.withAlpha(220))),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      // Categories
                      Text('Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final cat = _categories[i];
                            final icons = [Icons.plumbing, Icons.electrical_services, Icons.format_paint, Icons.carpenter, Icons.cleaning_services, Icons.local_shipping, Icons.grass, Icons.computer];
                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/home'), // TODO: filter by category
                              child: Container(
                                width: 90,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer.withAlpha(80),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(icons[i % icons.length], color: cs.primary, size: 32),
                                  const SizedBox(height: 6),
                                  Text(cat.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Top rated
                      Text('Top Rated Professionals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_topProfessionals.isEmpty)
                        const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No professionals found yet')))
                      else
                        ..._topProfessionals.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProfessionalCard(professional: p),
                        )),
                    ],
                  ),
                ),
    );
  }
}
