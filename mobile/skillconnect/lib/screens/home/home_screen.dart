import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/review_prompt.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/nearby_providers_section.dart';
import '../../widgets/promotions_banner.dart';
import '../../widgets/app_components.dart';
import '../../data/services_catalog.dart';
import 'service_hub_screen.dart';
import 'category_detail_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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

  void _openService(int id, String name, {bool isRoot = false}) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CategoryDetailScreen(categoryId: id, categoryName: name, isRoot: isRoot),
    ));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '👋';
    return '🌙';
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
    final auth = context.watch<AuthService>();
    final userName = auth.user?['name']?.toString().split(' ').first ?? 'there';

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Personalized Header (like sample image) ─────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting + Avatar row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(
                                      '${_getGreeting()} ${_getGreetingEmoji()}',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Available badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withAlpha(40),
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(color: AppColors.success.withAlpha(80)),
                                      ),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.circle, size: 6, color: AppColors.success),
                                        SizedBox(width: 4),
                                        Text('Online', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ]),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // User Avatar
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(80), width: 3),
                                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                              ),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Search bar
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: AppShadows.md(Colors.black),
                            ),
                            child: Row(children: [
                              const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Search services or professionals...',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Text('Go', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Promotions Banner Carousel ──────────────────────────
            const SliverToBoxAdapter(child: PromotionsBanner()),

            // ── Quick Actions (expanded 8-icon grid) ────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.lg),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.85,
                      children: [
                        _QuickActionIcon(
                          icon: Icons.home_repair_service_rounded,
                          label: 'Services',
                          color: const Color(0xFF6366F1),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.emergency_rounded,
                          label: 'Emergency',
                          color: const Color(0xFFEF4444),
                          onTap: () => Navigator.pushNamed(context, '/emergency'),
                        ),
                        _QuickActionIcon(
                          icon: Icons.event_note_rounded,
                          label: 'Bookings',
                          color: const Color(0xFFF59E0B),
                          onTap: () {}, // Navigate handled by bottom nav
                        ),
                        _QuickActionIcon(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Wallet',
                          color: const Color(0xFF10B981),
                          onTap: () => Navigator.pushNamed(context, '/earnings'),
                        ),
                        _QuickActionIcon(
                          icon: Icons.camera_alt_rounded,
                          label: 'Photo Quote',
                          color: const Color(0xFF06B6D4),
                          onTap: () => Navigator.pushNamed(context, '/instant-quote'),
                        ),
                        _QuickActionIcon(
                          icon: Icons.people_rounded,
                          label: 'Referrals',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.pushNamed(context, '/contacts'),
                        ),
                        _QuickActionIcon(
                          icon: Icons.verified_user_rounded,
                          label: 'Warranty',
                          color: const Color(0xFF059669),
                          onTap: () => Navigator.pushNamed(context, '/warranty'),
                        ),
                        _QuickActionIcon(
                          icon: Icons.local_offer_rounded,
                          label: 'Offers',
                          color: const Color(0xFFEC4899),
                          onTap: () {}, // Placeholder for offers
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Review prompt (only if pending) ──────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: ReviewPromptBanner(),
              ),
            ),

            // ── Service hubs ──────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Categories',
                accentColor: cs.primary,
                actionLabel: 'View all',
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    scrollDirection: Axis.horizontal,
                    itemCount: kServiceHubs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final hub = kServiceHubs[i];
                      return GestureDetector(
                        onTap: () => _openService(hub.id, hub.name, isRoot: true),
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: hub.gradient),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppShadows.md(hub.gradient.first),
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
              ),
            ),

            // ── Popular services grid ─────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Popular Services',
                accentColor: const Color(0xFFEF4444),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
                  itemCount: popularServices.length,
                  itemBuilder: (_, i) {
                    final s = popularServices[i];
                    return InkWell(
                      onTap: () => _openService(s.id, s.name),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: s.gradient),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: AppShadows.sm(s.gradient.first),
                            ),
                            child: Icon(s.icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(s.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.2)),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Nearby available providers (smart location) ─────
            const SliverToBoxAdapter(child: NearbyProvidersSection()),

            // ── Top-rated professionals ───────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Top-rated Professionals',
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                child: _loading
                    ? Column(children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonProfessionalCard())))
                    : _error != null
                        ? _ErrorWidget(onRetry: _load, isDark: isDark)
                        : _topProfessionals.isEmpty
                            ? EmptyStateWidget(
                                icon: Icons.person_search_rounded,
                                title: 'No professionals yet',
                                subtitle: 'Be the first to join! Check back soon.',
                                actionLabel: 'Browse services',
                                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())),
                              )
                            : Column(
                                children: _topProfessionals.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ProfessionalCard(professional: p),
                                )).toList(),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Icon (grid item) ──────────────────────────────────────────

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Error State Widget ─────────────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorWidget({required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Column(children: [
        Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.error.withAlpha(180)),
        const SizedBox(height: AppSpacing.md),
        const Text('Could not connect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppSpacing.xs),
        Text('Check your connection and try again', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Try again'),
        ),
      ]),
    );
  }
}
