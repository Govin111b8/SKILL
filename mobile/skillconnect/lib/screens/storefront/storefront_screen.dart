import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../services/storefront_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/hero_banner.dart';
import 'widgets/announcement_banner.dart';
import 'widgets/trust_badges_row.dart';
import 'widgets/about_section.dart';
import 'widgets/portfolio_grid.dart';
import 'widgets/service_info_card.dart';
import 'widgets/contact_buttons_row.dart';
import 'widgets/reviews_section.dart';

class StorefrontScreen extends StatefulWidget {
  final String professionalId;
  const StorefrontScreen({super.key, required this.professionalId});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> with SingleTickerProviderStateMixin {
  StorefrontData? _data;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await StorefrontService.fetchStorefront(widget.professionalId);
      _data = StorefrontService.parseStorefront(raw);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _share() {
    final name = _data?.professional.name ?? 'Professional';
    Share.share('Check out $name on SkillConnect: https://skillconnect.app/pro/${widget.professionalId}');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Storefront')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(),
        ),
      );
    }

    if (_error != null || _data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Storefront')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(_error ?? 'Failed to load storefront'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final pro = _data!.professional;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Collapsible app bar with hero
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              actions: [
                IconButton(icon: const Icon(Icons.share), onPressed: _share),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: HeroBanner(professional: pro),
              ),
            ),
            // Announcement
            if (pro.announcement != null && pro.announcement!.isNotEmpty)
              SliverToBoxAdapter(child: AnnouncementBanner(text: pro.announcement!)),
            // Trust badges
            SliverToBoxAdapter(child: TrustBadgesRow(professional: pro)),
            // Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorColor: cs.primary,
                  tabs: const [
                    Tab(text: 'Portfolio'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'Info'),
                    Tab(text: 'Contact'),
                  ],
                ),
                cs.surface,
              ),
            ),
            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  PortfolioGrid(items: _data!.portfolio),
                  ReviewsSection(
                    reviews: _data!.reviews,
                    distribution: _data!.ratingDistribution,
                    averageRating: pro.averageRating,
                    reviewCount: pro.reviewCount,
                  ),
                  ServiceInfoCard(professional: pro),
                  ContactButtonsRow(professional: pro),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
