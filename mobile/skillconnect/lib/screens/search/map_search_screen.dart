import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _professionals = [];
  bool _loading = true;
  String? _error;
  bool _mapMode = true;
  double _lat = 17.385;
  double _lng = 78.4867;
  String _categoryId = '';

  final List<Map<String, String>> _categories = const [
    {'id': '', 'label': 'All'},
    {'id': '6', 'label': 'AC'},
    {'id': '7', 'label': 'Cleaning'},
    {'id': '10', 'label': 'Beauty'},
    {'id': '17', 'label': 'Plumbing'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/search', queryParams: {
        'lat': _lat.toString(),
        'lng': _lng.toString(),
        'radius': '10',
        if (_categoryId.isNotEmpty) 'category_id': _categoryId,
        if (_searchController.text.trim().isNotEmpty)
          'q': _searchController.text.trim(),
      });
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ??
                  data['professionals'] as List? ??
                  const [])
              : const [];
      _professionals =
          list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showProfessional(Map<String, dynamic> pro) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(180),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow: AppShadows.lg(AppColors.primary),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(28),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: Colors.white.withAlpha(60)),
                      ),
                      child: Center(
                        child: Text(
                          (pro['name'] ?? '').toString().trim().isEmpty
                              ? '?'
                              : (pro['name'] ?? '').toString().trim()[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pro['name']?.toString() ?? 'Professional',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            pro['category_name']?.toString() ??
                                pro['headline']?.toString() ??
                                'Service',
                            style: TextStyle(
                              color: Colors.white.withAlpha(225),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumGlassCard(
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        PremiumStatusPill(
                          label: '⭐ ${pro['average_rating'] ?? 0}',
                          color: AppColors.warning,
                        ),
                        PremiumStatusPill(
                          label: pro['location']?.toString() ?? 'Nearby',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: PremiumMetricCard(
                            label: 'Category',
                            value: (pro['category_name'] ??
                                    pro['headline'] ??
                                    'Service')
                                .toString(),
                            icon: Icons.work_outline_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: PremiumMetricCard(
                            label: 'Rating',
                            value: '${pro['average_rating'] ?? 0}',
                            icon: Icons.star_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumGradientButton(
                        label: 'Book Now',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/professional/${pro['id']}'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      floatingActionButton: PremiumGradientButton(
        label: _mapMode ? 'List View' : 'Map View',
        icon: _mapMode ? Icons.list_rounded : Icons.map_rounded,
        onPressed: () {
          HapticFeedback.mediumImpact();
          setState(() => _mapMode = !_mapMode);
        },
      ),
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: _buildBody(context),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumSearchField(
                    hint: 'Search nearby services',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _categories
                          .map(
                            (category) => Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              child: _MapCategoryChip(
                                label: category['label']!,
                                selected: _categoryId == category['id'],
                                onTap: () {
                                  setState(() => _categoryId = category['id']!);
                                  _load();
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          164,
          AppSpacing.lg,
          140,
        ),
        children: const [
          PremiumLoadingList(itemCount: 4, itemHeight: 120),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          170,
          AppSpacing.lg,
          140,
        ),
        children: [
          PremiumEmptyState(
            icon: Icons.map_outlined,
            title: 'Could not load nearby professionals',
            subtitle: _error!,
            actionLabel: 'Retry',
            onAction: _load,
            gradient: const [AppColors.error, Color(0xFFF97316)],
          ),
        ],
      );
    }

    if (_professionals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          170,
          AppSpacing.lg,
          140,
        ),
        children: [
          PremiumEmptyState(
            icon: Icons.location_searching_rounded,
            title: 'No nearby professionals',
            subtitle:
                'Try a different category or search term to explore more results around you.',
            actionLabel: 'Refresh',
            onAction: _load,
          ),
        ],
      );
    }

    return _mapMode ? _buildMapMode(context) : _buildListMode(context);
  }

  Widget _buildMapMode(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        170,
        AppSpacing.lg,
        160,
      ),
      children: [
        PremiumGlassCard(
          gradient: [AppColors.primary.withAlpha(32), Colors.white.withAlpha(205)],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live discovery map',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Explore ${_professionals.length} professionals around your current service radius.',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const PremiumStatusPill(
                label: '10 km radius',
                color: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 520,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDDEAFE), Color(0xFFEDE9FE), Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: AppShadows.lg(AppColors.primary),
            border: Border.all(color: Colors.white.withAlpha(220)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.lg,
                left: AppSpacing.lg,
                child: PremiumGlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Placeholder map surface — replace with GoogleMap when key is configured.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ..._professionals.take(8).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final pro = entry.value;
                return Positioned(
                  left: 28.0 + (index % 3) * 104,
                  top: 92.0 + (index * 58 % 280),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showProfessional(pro);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadows.md(AppColors.primary),
                        border: Border.all(color: Colors.white.withAlpha(150)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            (pro['name'] ?? 'Pro').toString().split(' ').first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumSectionTitle(
          title: 'Nearby highlights',
          subtitle:
              'Quick access to top professionals around the selected map area',
        ),
        ..._professionals.take(3).map(
              (pro) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ProfessionalPreviewCard(
                  professional: pro,
                  onTap: () => _showProfessional(pro),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildListMode(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        170,
        AppSpacing.lg,
        160,
      ),
      itemCount: _professionals.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: PremiumGlassCard(
              gradient: [
                AppColors.success.withAlpha(24),
                Colors.white.withAlpha(205),
              ],
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium nearby matches',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${_professionals.length} professionals are ready to serve around your selected area.',
                          style:
                              TextStyle(color: Colors.grey.shade700, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const PremiumStatusPill(
                    label: 'Live',
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          );
        }
        final pro = _professionals[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ProfessionalPreviewCard(
            professional: pro,
            onTap: () => _showProfessional(pro),
          ),
        );
      },
    );
  }
}

class _MapCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MapCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: selected ? null : Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.primary.withAlpha(55),
          ),
          boxShadow: selected
              ? AppShadows.md(AppColors.primary)
              : AppShadows.sm(AppColors.primary),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.surfaceDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfessionalPreviewCard extends StatelessWidget {
  final Map<String, dynamic> professional;
  final VoidCallback onTap;

  const _ProfessionalPreviewCard({
    required this.professional,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = professional['name']?.toString() ?? 'Professional';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return PremiumGlassCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${professional['category_name'] ?? professional['headline'] ?? 'Service'} • ⭐ ${professional['average_rating'] ?? 0}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    PremiumStatusPill(
                      label: professional['location']?.toString() ?? 'Nearby',
                      color: AppColors.primary,
                    ),
                    const PremiumStatusPill(
                      label: 'Quick view',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withAlpha(28)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
