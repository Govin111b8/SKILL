import 'package:flutter/material.dart';
import '../../data/services_catalog.dart';
import '../search/search_screen.dart';
import 'category_detail_screen.dart';

/// Service Hub — every service is a "mini-app" inside the unified SkillConnect platform.
/// Tapping a service opens its themed search experience for that category only.
class ServiceHubScreen extends StatelessWidget {
  const ServiceHubScreen({super.key});

  void _open(BuildContext context, int categoryId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryDetailScreen(
        categoryId: categoryId,
        categoryName: name,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('Service Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                      ),
                    ),
                  ),
                  // decorative orbs
                  Positioned(top: -40, right: -30, child: _orb(160, Colors.white.withAlpha(30))),
                  Positioned(bottom: -50, left: -40, child: _orb(220, Colors.white.withAlpha(20))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 70, 20, 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withAlpha(60))),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text('40+ verified services', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Every service,\none platform.',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Hubs (parent categories)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                const Icon(Icons.apps_rounded, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text('Browse by category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5),
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final hub = kServiceHubs[i];
                return _hubCard(context, hub);
              }, childCount: kServiceHubs.length),
            ),
          ),
          // All services as mini-apps
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Text('All services', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${kServices.length} mini-apps', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
          ),
          // Group services by parent hub
          ...kServiceHubs.expand((hub) {
            final hubServices = servicesForHub(hub.id);
            return [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    Text(hub.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(hub.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF334155))),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: hub.gradient.first.withAlpha(30), borderRadius: BorderRadius.circular(100)), child: Text('${hubServices.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: hub.gradient.first))),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final s = hubServices[i];
                    return _serviceTile(context, s);
                  }, childCount: hubServices.length),
                ),
              ),
            ];
          }),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _orb(double size, Color c) => Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _hubCard(BuildContext context, ServiceHubDef hub) {
    return InkWell(
      onTap: () => _open(context, hub.id, hub.name),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: hub.gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: hub.gradient.first.withAlpha(60), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(children: [
          Positioned(top: -10, right: -10, child: Icon(hub.icon, size: 80, color: Colors.white.withAlpha(40))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(hub.emoji, style: const TextStyle(fontSize: 24)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text(hub.description, style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 11, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _serviceTile(BuildContext context, ServiceDef s) {
    return InkWell(
      onTap: () => _open(context, s.id, s.name),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: s.gradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: s.gradient.first.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(s.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(s.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
          ),
        ]),
      ),
    );
  }
}
