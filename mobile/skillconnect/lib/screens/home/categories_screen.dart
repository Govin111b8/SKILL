import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin {
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  late final AnimationController _orbCtrl;
  late final AnimationController _entryCtrl;

  static const _colorList = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFFEC4899), Color(0xFFA855F7)],
    [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    [Color(0xFF14B8A6), Color(0xFF0891B2)],
    [Color(0xFFF97316), Color(0xFFEF4444)],
    [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
    [Color(0xFF22C55E), Color(0xFF16A34A)],
  ];

  static const _iconList = [
    Icons.home_repair_service_rounded,
    Icons.event_rounded,
    Icons.person_rounded,
    Icons.computer_rounded,
    Icons.palette_rounded,
    Icons.plumbing_rounded,
    Icons.electrical_services_rounded,
    Icons.format_paint_rounded,
    Icons.camera_alt_rounded,
    Icons.fitness_center_rounded,
    Icons.cleaning_services_rounded,
    Icons.grass_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _load();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/categories');
      _categories =
          (res['data'] as List).map((e) => Category.fromJson(e)).toList();
      _error = null;
      _entryCtrl
        ..reset()
        ..forward();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openCategory(Category cat, {bool isRoot = false}) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          categoryId: cat.id,
          categoryName: cat.name,
          categoryDescription: cat.description,
          isRoot: isRoot,
        ),
      ),
    );
  }

  List<Category> get _filtered => _searchQuery.isEmpty
      ? _categories
      : _categories
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Stack(
        children: [
          // Animated glow orbs in header area
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) {
              final t = _orbCtrl.value;
              return Stack(children: [
                Positioned(
                  top: -30 + math.sin(t * math.pi) * 20,
                  left: -20,
                  child: _GlowOrb(
                    color: AppColors.primary.withAlpha(50),
                    size: 200,
                  ),
                ),
                Positioned(
                  top: 40 + math.cos(t * math.pi) * 15,
                  right: -40,
                  child: _GlowOrb(
                    color: AppColors.accent.withAlpha(40),
                    size: 160,
                  ),
                ),
              ]);
            },
          ),

          CustomScrollView(
            slivers: [
              // ── Premium SliverAppBar ──────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 70),
                  title: const Text(
                    'Explore Services',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.3,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -30,
                          right: -20,
                          child: _GlowOrb(
                              color: Colors.white.withAlpha(25), size: 180),
                        ),
                        Positioned(
                          bottom: 40,
                          left: -30,
                          child: _GlowOrb(
                              color: Colors.white.withAlpha(15), size: 150),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find the perfect pro',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(25),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(
                                          color: Colors.white.withAlpha(40)),
                                    ),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.category_rounded,
                                              size: 13, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${_categories.length} Categories',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ]),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(25),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(
                                          color: Colors.white.withAlpha(40)),
                                    ),
                                    child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_rounded,
                                              size: 13, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text(
                                            'All Verified',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ]),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Search bar ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                              color: AppColors.primary.withAlpha(30)),
                          boxShadow: AppShadows.sm(AppColors.primary),
                        ),
                        child: TextField(
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg, vertical: 14),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.primary),
                            hintText: 'Search categories...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18),
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────
              if (_loading)
                const SliverToBoxAdapter(
                    child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: PremiumLoadingList(itemCount: 6, itemHeight: 130),
                ))
              else if (_error != null)
                SliverFillRemaining(
                  child: PremiumEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Could not load categories',
                    subtitle: _error!,
                    actionLabel: 'Retry',
                    onAction: _load,
                    gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  child: PremiumEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results',
                    subtitle: 'No categories match "$_searchQuery"',
                    actionLabel: 'Clear search',
                    onAction: () => setState(() => _searchQuery = ''),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final cat = _filtered[i];
                        final colors = _colorList[i % _colorList.length];
                        final icon = _iconList[i % _iconList.length];
                        final prosCount = (i + 1) * 12 + (i % 3) * 7;
                        return AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) {
                            final delay = (i * 0.07).clamp(0.0, 0.6);
                            final progress =
                                (((_entryCtrl.value - delay) / (1 - delay))
                                        .clamp(0.0, 1.0));
                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - progress)),
                                child: child,
                              ),
                            );
                          },
                          child: _CategoryCard(
                            category: cat,
                            colors: colors,
                            icon: icon,
                            prosCount: prosCount,
                            onTap: () =>
                                _openCategory(cat, isRoot: cat.parentId == null),
                          ),
                        );
                      },
                      childCount: _filtered.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final Category category;
  final List<Color> colors;
  final IconData icon;
  final int prosCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.colors,
    required this.icon,
    required this.prosCount,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withAlpha(70),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decorative icon
              Positioned(
                top: -10,
                right: -10,
                child: Icon(
                  widget.icon,
                  size: 90,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon box
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: Colors.white.withAlpha(50)),
                      ),
                      child:
                          Icon(widget.icon, color: Colors.white, size: 26),
                    ),
                    const Spacer(),
                    // Name
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Pros count
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_rounded,
                                  size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.prosCount}+ Pros',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ]),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: Colors.white),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}
