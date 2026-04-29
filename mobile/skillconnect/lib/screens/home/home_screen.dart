import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/review_prompt.dart';
import '../../widgets/skeleton_loader.dart';
import '../../data/services_catalog.dart';
import 'service_hub_screen.dart';
import 'category_detail_screen.dart';

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

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('SkillConnect'),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () { HapticFeedback.lightImpact(); _load(); },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 40),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ── Hero banner ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withAlpha(70), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(60))),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('40+ verified services', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text('Find trusted\nprofessionals', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 6),
                  Text('Verified · Reviewed · Zero commission', style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())); },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.search, color: Color(0xFF6366F1), size: 18),
                        const SizedBox(width: 8),
                        Text('Search services...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Go', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Review prompt (only if pending) ──────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: ReviewPromptBanner(),
            ),

            // ── Service hubs ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())),
                  child: Text('View all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: kServiceHubs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final hub = kServiceHubs[i];
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); _openService(hub.id, hub.name); },
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: hub.gradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: hub.gradient.first.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(hub.emoji, style: const TextStyle(fontSize: 24)),
                        Text(hub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: -0.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // ── Popular services grid ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Popular services', style: Theme.of(context).textTheme.titleMedium),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
                itemCount: popularServices.length,
                itemBuilder: (_, i) {
                  final s = popularServices[i];
                  return InkWell(
                    onTap: () { HapticFeedback.selectionClick(); _openService(s.id, s.name); },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: s.gradient), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: s.gradient.first.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]),
                          child: Icon(s.icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(s.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.2))),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // ── Top-rated professionals ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Top-rated professionals', style: Theme.of(context).textTheme.titleMedium),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loading
                  ? Column(children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonProfessionalCard())))
                  : _error != null
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(children: [
                            Icon(Icons.wifi_off_rounded, size: 36, color: Colors.red.shade400),
                            const SizedBox(height: 8),
                            const Text('Could not connect', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Check your connection and try again', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(height: 10),
                            OutlinedButton(onPressed: _load, child: const Text('Try again')),
                          ]),
                        )
                      : _topProfessionals.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.person_search_rounded,
                              title: 'No professionals yet',
                              subtitle: 'Be the first to join! Check back soon.',
                              actionLabel: 'Browse services',
                              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())),
                            )
                          : Column(children: _topProfessionals.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ProfessionalCard(professional: p))).toList()),
            ),
          ],
        ),
      ),
    );
  }
}
