import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/review_prompt.dart';
import '../../data/services_catalog.dart';
import 'service_hub_screen.dart';
import 'category_detail_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Professional> _topProfessionals = [];
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
      final res = await ApiService.get('/search', queryParams: {'sort_by': 'rating', 'limit': '10'});
      _topProfessionals = (res['data'] as List).map((e) => Professional.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openService(int id, String name) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CategoryDetailScreen(categoryId: id, categoryName: name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final popularIds = [6, 7, 17, 10, 33, 26, 24, 25];
    final popularServices = popularIds
        .map((id) => findServiceById(id))
        .whereType<ServiceDef>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('SkillConnect', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withAlpha(80), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withAlpha(70))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bolt, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('40+ verified services', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 12),
                Text('Find skilled\nprofessionals\nnear you', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5)),
                const SizedBox(height: 10),
                Text('Verified pros · transparent reviews · zero commission', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13)),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.search, color: Color(0xFF6366F1), size: 20),
                      const SizedBox(width: 8),
                      const Text('Browse all services...', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(8)), child: const Text('Go', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                    ]),
                  ),
                ),
              ]),
            ),
            // Review prompt banner (non-intrusive, only shows if pending)
            const SizedBox(height: 16),
            const ReviewPromptBanner(),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.apps_rounded, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text('Service categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())), child: const Text('View all')),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kServiceHubs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final hub = kServiceHubs[i];
                  return GestureDetector(
                    onTap: () => _openService(hub.id, hub.name),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: hub.gradient),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: hub.gradient.first.withAlpha(60), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Stack(children: [
                        Positioned(top: -10, right: -10, child: Icon(hub.icon, size: 70, color: Colors.white.withAlpha(40))),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(hub.emoji, style: const TextStyle(fontSize: 22)),
                          Text(hub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: -0.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Text('Popular services', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9),
              itemCount: popularServices.length,
              itemBuilder: (_, i) {
                final s = popularServices[i];
                return InkWell(
                  onTap: () => _openService(s.id, s.name),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(gradient: LinearGradient(colors: s.gradient), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: s.gradient.first.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]),
                        child: Icon(s.icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(s.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2))),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text('Top-rated professionals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.shade100)),
                child: Column(children: [
                  Icon(Icons.cloud_off, size: 36, color: Colors.red.shade300),
                  const SizedBox(height: 8),
                  Text('Could not connect', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_error!, style: TextStyle(fontSize: 11, color: Colors.red.shade600), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ]),
              )
            else if (_topProfessionals.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No professionals yet')))
            else
              ..._topProfessionals.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ProfessionalCard(professional: p))),
          ],
        ),
      ),
    );
  }
}
