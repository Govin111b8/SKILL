import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/professional.dart';
import '../models/category.dart' as cat;
import '../widgets/professional_card.dart';
import 'search_screen.dart';
import 'professional_profile_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider auth;
  const HomeScreen({super.key, required this.auth});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  List<Professional> _featured = [];
  bool _loadingFeatured = true;

  final _categories = [
    {'name': 'Plumbing', 'icon': Icons.plumbing, 'color': Colors.blue},
    {'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.amber},
    {'name': 'Home Repair', 'icon': Icons.handyman, 'color': Colors.orange},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.teal},
    {'name': 'Tutoring', 'icon': Icons.school, 'color': Colors.purple},
    {'name': 'Beauty', 'icon': Icons.face, 'color': Colors.pink},
    {'name': 'Moving', 'icon': Icons.local_shipping, 'color': Colors.brown},
    {'name': 'Photography', 'icon': Icons.camera_alt, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    try {
      final data = await ApiService.get('/search?sort_by=reputation&limit=6');
      final list = data['professionals'] as List? ?? [];
      setState(() {
        _featured = list.map((j) => Professional.fromJson(j)).toList();
        _loadingFeatured = false;
      });
    } catch (e) {
      setState(() => _loadingFeatured = false);
    }
  }

  void _doSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SearchScreen(auth: widget.auth, initialQuery: q),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SkillConnect', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onPrimary)),
                  const SizedBox(height: 8),
                  Text('Find trusted professionals\nnear you', style: TextStyle(fontSize: 16, color: cs.onPrimary.withValues(alpha: 0.9))),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'What service do you need?',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _doSearch(),
                      )),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilledButton(onPressed: _doSearch, child: const Text('Search')),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Popular Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: _categories.map((c) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SearchScreen(auth: widget.auth, initialQuery: c['name'] as String),
                  )),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: (c['color'] as Color).withValues(alpha: 0.12),
                        child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(c['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // How It Works
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Text('How It Works', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _stepCard('1', 'Search', 'Find the service you need', Icons.search, cs),
                const SizedBox(width: 8),
                _stepCard('2', 'Compare', 'Check ratings and reviews', Icons.compare_arrows, cs),
                const SizedBox(width: 8),
                _stepCard('3', 'Connect', 'Contact your professional', Icons.handshake, cs),
              ]),
            ),
          ),

          // Featured pros
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Text('Top Professionals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_loadingFeatured)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())))
          else if (_featured.isEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Column(children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Connect your backend to see professionals', style: TextStyle(color: Colors.grey[500])),
              ])),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: _featured.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProfessionalCard(
                    professional: _featured[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProfessionalProfileScreen(professionalId: _featured[i].id, auth: widget.auth),
                    )),
                  ),
                ),
              ),
            ),

          // Stats
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('5,000+', 'Professionals'),
                _stat('50+', 'Categories'),
                _stat('100+', 'Cities'),
              ]),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  Widget _stepCard(String num, String title, String sub, IconData icon, ColorScheme cs) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            CircleAvatar(radius: 20, backgroundColor: cs.primary.withValues(alpha: 0.1), child: Icon(icon, color: cs.primary, size: 20)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey[600]), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]);
  }
}
