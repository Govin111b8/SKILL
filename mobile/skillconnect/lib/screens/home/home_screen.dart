import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/availability_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/nearby_providers_section.dart';
import '../../widgets/promotions_banner.dart';
import '../../widgets/app_components.dart';
import '../../data/services_catalog.dart';
import 'service_hub_screen.dart';
import 'category_detail_screen.dart';
import '../delivery/delivery_screen.dart';
import '../rides/my_ride_screen.dart';
import '../food/food_screen.dart';
import '../groceries/groceries_screen.dart';
import '../shopping/shopping_screen.dart';
import '../jobs/job_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Professional> _topProfessionals = [];
  bool _loading = true;
  String? _error;
  bool _available = false;
  bool _updatingAvailability = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final status = await AvailabilityService.getStatus();
      if (mounted) setState(() => _available = status == 'available');
    } catch (_) {}
  }

  Future<void> _toggleAvailability(bool val) async {
    if (_updatingAvailability) return;
    HapticFeedback.mediumImpact();
    setState(() { _updatingAvailability = true; _available = val; });
    try {
      await AvailabilityService.setAvailable(val);
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _available = !val);
    }
    if (mounted) setState(() => _updatingAvailability = false);
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
        color: AppColors.superBlue,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Personalized Header (Grab/Gojek-style) ──────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.superAppGradient,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top bar: greeting + notification + avatar ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()} ${_getGreetingEmoji()}',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(180),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification bell
                            Stack(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.notifications_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF1B6EF3), width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            // User Avatar
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withAlpha(100), width: 2.5),
                                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                              ),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Location pill ──
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.white.withAlpha(200), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Hyderabad, Telangana',
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withAlpha(160), size: 16),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Hero Search Bar ──
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/search'),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Icon(Icons.search_rounded, color: Color(0xFF1B6EF3), size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Search for services, pros...',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                ),
                                const Spacer(),
                                Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFF1B6EF3), Color(0xFF4F46E5)]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Suggestion Pills ──
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _SuggestionPill(label: '🔧 Plumbing', onTap: () {}),
                              const SizedBox(width: 8),
                              _SuggestionPill(label: '⚡ Electrician', onTap: () {}),
                              const SizedBox(width: 8),
                              _SuggestionPill(label: '🏠 Cleaning', onTap: () {}),
                              const SizedBox(width: 8),
                              _SuggestionPill(label: '💇 Salon', onTap: () {}),
                              const SizedBox(width: 8),
                              _SuggestionPill(label: '🎓 Tutor', onTap: () {}),
                            ],
                          ),
                        ),

                        // ── Availability toggle (only for professionals) ──
                        if (auth.isProfessional)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withAlpha(30)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _available ? const Color(0xFF10B981) : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _available ? 'You\'re available for bookings' : 'You\'re offline',
                                    style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const Spacer(),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: _available,
                                      onChanged: _updatingAvailability ? null : _toggleAvailability,
                                      activeColor: Colors.white,
                                      activeTrackColor: AppColors.success,
                                      inactiveThumbColor: Colors.white,
                                      inactiveTrackColor: Colors.white.withAlpha(40),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
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

            // ── Quick Actions (8-icon super-app grid) ────────────────
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
                          icon: Icons.local_shipping_rounded,
                          label: 'Delivery',
                          color: AppColors.tileDelivery,
                          colorEnd: const Color(0xFFFF6D00),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.directions_car_rounded,
                          label: 'MyRide',
                          color: AppColors.tileRide,
                          colorEnd: const Color(0xFF01579B),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRideScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.restaurant_rounded,
                          label: 'Food',
                          color: AppColors.tileFood,
                          colorEnd: const Color(0xFFE64A19),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.shopping_cart_rounded,
                          label: 'Groceries',
                          color: AppColors.tileGroceries,
                          colorEnd: const Color(0xFF1B5E20),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceriesScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.shopping_bag_rounded,
                          label: 'Shopping',
                          color: AppColors.tileShopping,
                          colorEnd: const Color(0xFFB71C1C),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.home_repair_service_rounded,
                          label: 'Services',
                          color: AppColors.tileServices,
                          colorEnd: const Color(0xFF4A148C),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHubScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.work_rounded,
                          label: 'Job',
                          color: AppColors.tileJob,
                          colorEnd: const Color(0xFF004D40),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobScreen())),
                        ),
                        _QuickActionIcon(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Wallet',
                          color: AppColors.tileWallet,
                          colorEnd: const Color(0xFF00695C),
                          onTap: () => Navigator.pushNamed(context, '/earnings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Flash Deals ───────────────────────────────────────
            const SliverToBoxAdapter(child: _FlashDealsSection()),

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

// ─── Quick Action Icon (grid item) — gradient tile with scale-on-tap ────────

class _QuickActionIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  /// Optional second gradient stop; defaults to darkened primary.
  final Color? colorEnd;

  const _QuickActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.colorEnd,
  });

  @override
  State<_QuickActionIcon> createState() => _QuickActionIconState();
}

class _QuickActionIconState extends State<_QuickActionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    HapticFeedback.selectionClick();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final end = widget.colorEnd ?? HSLColor.fromColor(widget.color).withLightness(
      (HSLColor.fromColor(widget.color).lightness - 0.12).clamp(0.0, 1.0),
    ).toColor();
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.color, end],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Flash Deals horizontal carousel ────────────────────────────────────────

class _FlashDealsSection extends StatelessWidget {
  const _FlashDealsSection();

  static const _deals = [
    _Deal('AC Service', '40% OFF', 'Book today only', [Color(0xFF1B6EF3), Color(0xFF06B6D4)], Icons.ac_unit_rounded),
    _Deal('Home Cleaning', '₹199 Flat', 'First booking', [Color(0xFF7B1FA2), Color(0xFFE91E63)], Icons.cleaning_services_rounded),
    _Deal('Electrician', '₹99 Visit', 'Any time slot', [Color(0xFFFF6D00), Color(0xFFFFA000)], Icons.electrical_services_rounded),
    _Deal('Plumber', 'Free Inspection', 'Limited slots', [Color(0xFF2E7D32), Color(0xFF66BB6A)], Icons.plumbing_rounded),
    _Deal('Tutor', '1st Class Free', 'All subjects', [Color(0xFF00796B), Color(0xFF26C6DA)], Icons.school_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text('⚡ FLASH DEALS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
            const SizedBox(width: 8),
            Text('Today only', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ]),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: _deals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final d = _deals[i];
              return GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: Container(
                  width: 155,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: d.gradient),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [BoxShadow(color: d.gradient.first.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                        child: Icon(d.icon, color: Colors.white, size: 18),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
                        child: Text(d.badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ]),
                    const Spacer(),
                    Text(d.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(d.sub, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11)),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Deal {
  final String title, badge, sub;
  final List<Color> gradient;
  final IconData icon;
  const _Deal(this.title, this.badge, this.sub, this.gradient, this.icon);
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

// ─── Suggestion Pill ─────────────────────────────────────────────────────────

class _SuggestionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(220),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
