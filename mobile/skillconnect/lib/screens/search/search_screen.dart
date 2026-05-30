import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/services_catalog.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/voice_search_button.dart';

class SearchScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  const SearchScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtl = TextEditingController();
  final _scrollController = ScrollController();
  List<Professional> _results = [];
  List<Category> _categories = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _searched = false;
  String _sortBy = 'reputation';
  int _page = 1;
  int _totalPages = 1;
  int? _selectedCategoryId;
  String? _maxPrice;
  bool _showFilters = false;
  final _maxPriceCtl = TextEditingController();
  Timer? _debounce;

  bool _availableNow = false;
  bool _nearMe = false;
  double _radiusKm = 25;
  double? _userLat;
  double? _userLng;
  bool _geoLoading = false;
  static const double _fallbackLat = 17.385;
  static const double _fallbackLng = 78.4867;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _loadCategories();
    if (widget.categoryId != null) {
      _search();
    }
    _searchCtl.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtl.removeListener(_onSearchChanged);
    _searchCtl.dispose();
    _maxPriceCtl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _geoLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showGeoSnackBar('Location services are disabled. Using default city.');
        _userLat = _fallbackLat;
        _userLng = _fallbackLng;
        if (mounted) setState(() => _geoLoading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showGeoSnackBar('Location permission denied. Using default city.');
        _userLat = _fallbackLat;
        _userLng = _fallbackLng;
        if (mounted) setState(() => _geoLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    } catch (_) {
      _userLat = _fallbackLat;
      _userLng = _fallbackLng;
    }
    if (mounted) setState(() => _geoLoading = false);
  }

  void _showGeoSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page < _totalPages) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final params = <String, String>{
        'sort_by': _sortBy,
        'page': nextPage.toString(),
        'limit': '20',
      };
      if (_searchCtl.text.trim().isNotEmpty) params['q'] = _searchCtl.text.trim();
      if (_selectedCategoryId != null) {
        params['category_id'] = _selectedCategoryId.toString();
      }
      if (_maxPrice != null && _maxPrice!.isNotEmpty) {
        params['max_price'] = _maxPrice!;
      }
      if (_availableNow) params['availability'] = 'available';
      if (_nearMe && _userLat != null && _userLng != null) {
        params['latitude'] = _userLat.toString();
        params['longitude'] = _userLng.toString();
        params['radius_km'] = _radiusKm.toStringAsFixed(0);
      }
      final res = await ApiService.get('/search', queryParams: params);
      final next = (res['data'] as List)
          .map((e) => Professional.fromJson(e as Map<String, dynamic>))
          .toList();
      final pag = res['pagination'] as Map?;
      _totalPages = (pag?['pages'] as num?)?.toInt() ?? 1;
      _page = nextPage;
      if (mounted) {
        setState(() {
          _results.addAll(next);
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _search();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final res = await ApiService.get('/categories');
      _categories =
          (res['data'] as List).map((e) => Category.fromJson(e)).toList();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _search({int page = 1}) async {
    setState(() {
      _loading = true;
      _page = page;
    });
    try {
      final params = <String, String>{
        'sort_by': _sortBy,
        'page': page.toString(),
        'limit': '20',
      };
      if (_searchCtl.text.trim().isNotEmpty) params['q'] = _searchCtl.text.trim();
      if (_selectedCategoryId != null) {
        params['category_id'] = _selectedCategoryId.toString();
      }
      if (_maxPrice != null && _maxPrice!.isNotEmpty) {
        params['max_price'] = _maxPrice!;
      }
      if (_availableNow) params['availability'] = 'available';
      if (_nearMe && _userLat != null && _userLng != null) {
        params['latitude'] = _userLat.toString();
        params['longitude'] = _userLng.toString();
        params['radius_km'] = _radiusKm.toStringAsFixed(0);
      }
      final res = await ApiService.get('/search', queryParams: params);
      _results = (res['data'] as List)
          .map((e) => Professional.fromJson(e as Map<String, dynamic>))
          .toList();
      final pag = res['pagination'] as Map?;
      _totalPages = (pag?['pages'] as num?)?.toInt() ?? 1;
      _searched = true;
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _clearFilters() {
    _debounce?.cancel();
    setState(() {
      _searchCtl.clear();
      _selectedCategoryId = null;
      _maxPrice = null;
      _maxPriceCtl.clear();
      _availableNow = false;
      _nearMe = false;
      _radiusKm = 25;
      _results = [];
      _searched = false;
    });
  }

  bool get hasFilters =>
      _selectedCategoryId != null ||
      (_maxPrice != null && _maxPrice!.isNotEmpty) ||
      _availableNow ||
      _nearMe;

  String _selectedCategoryName() {
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) return category.name;
    }
    return 'Category';
  }

  Future<void> _handleNearMeToggle(bool value) async {
    HapticFeedback.mediumImpact();
    if (value && _userLat == null) {
      await _fetchLocation();
    }
    if (mounted) setState(() => _nearMe = value);
  }

  void _runSearchNow() {
    HapticFeedback.mediumImpact();
    _debounce?.cancel();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.categoryId != null ? findServiceById(widget.categoryId!) : null;
    final hub = widget.categoryId != null ? findHubById(widget.categoryId!) : null;
    final themeColors = svc?.gradient ?? hub?.gradient ?? AppColors.primaryGradient;
    final bannerTitle =
        widget.categoryName ?? svc?.name ?? hub?.name ?? 'Search Professionals';
    final bannerSubtitle = svc?.tagline ??
        hub?.description ??
        'Find trusted professionals near you with premium discovery filters.';

    return PremiumScrollScaffold(
      safeTop: false,
      child: RefreshIndicator(
        onRefresh: () async {
          if (_searched) {
            await _search(page: 1);
          } else {
            await _loadCategories();
          }
        },
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              elevation: 0,
              expandedHeight: widget.categoryId != null ? 286 : 210,
              backgroundColor: Colors.transparent,
              foregroundColor:
                  widget.categoryId != null ? Colors.white : AppColors.surfaceDark,
              automaticallyImplyLeading: widget.categoryId != null,
              title: widget.categoryId == null
                  ? const Text(
                      'Search Professionals',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.categoryId != null
                          ? themeColors
                          : const [
                              Color(0xFFEEF2FF),
                              Color(0xFFF5F3FF),
                              Color(0xFFF0F9FF),
                            ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        112,
                      ),
                      child: widget.categoryId != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(28),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.xl),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(70),
                                        ),
                                      ),
                                      child: Icon(
                                        svc?.icon ?? hub?.icon ?? Icons.search_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    const Spacer(),
                                    const PremiumStatChip(
                                      label: 'Verified pros',
                                      color: Colors.white,
                                      icon: Icons.verified_rounded,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    Text(
                                      svc?.emoji ?? hub?.emoji ?? '✨',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        bannerTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          height: 1.02,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  bannerSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(225),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Discover exceptional talent',
                                  style: TextStyle(
                                    color: AppColors.surfaceDark.withAlpha(235),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Search by skill, category, availability, price, and distance with a beautifully refined experience.',
                                  style: TextStyle(
                                    color: AppColors.surfaceDark.withAlpha(170),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(94),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PremiumSearchField(
                          hint: 'Search by name, skill, or keyword...',
                          controller: _searchCtl,
                          onChanged: (_) => setState(() {}),
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchCtl.text.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Clear',
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      _searchCtl.clear();
                                      setState(() {});
                                    },
                                  ),
                                IconButton(
                                  tooltip: 'Search',
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: _runSearchNow,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      PremiumGlassCard(
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: Center(
                            child: VoiceSearchButton(
                              onResult: (text) {
                                _searchCtl.text = text;
                                _search();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      PremiumGlassCard(
                        onTap: () {
                          setState(() => _showFilters = !_showFilters);
                        },
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                _showFilters
                                    ? Icons.tune_rounded
                                    : Icons.filter_alt_rounded,
                                color: AppColors.primary,
                              ),
                              if (hasFilters)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      boxShadow: AppShadows.sm(AppColors.accent),
                                    ),
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
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: AppDurations.normal,
                child: _showFilters
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          0,
                        ),
                        child: PremiumGlassCard(
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Refine your search',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (hasFilters)
                                    TextButton(
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        _clearFilters();
                                      },
                                      child: const Text('Clear all'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              DropdownButtonFormField<int?>(
                                value: _selectedCategoryId,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon:
                                      const Icon(Icons.category_rounded),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(120),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Categories'),
                                  ),
                                  ..._categories.map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _selectedCategoryId = v);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _maxPriceCtl,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _maxPrice = v,
                                decoration: InputDecoration(
                                  labelText: 'Max Price (₹)',
                                  prefixIcon: const Icon(
                                    Icons.currency_rupee_rounded,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(120),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              PremiumGlassCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                gradient: [
                                  Colors.white.withAlpha(205),
                                  Colors.white.withAlpha(120),
                                ],
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      dense: true,
                                      value: _availableNow,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (v) {
                                        HapticFeedback.mediumImpact();
                                        setState(() => _availableNow = v);
                                      },
                                      title: const Text(
                                        'Available Now',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Only show professionals currently online',
                                      ),
                                      secondary: PremiumStatusPill(
                                        label: _availableNow ? 'Live' : 'Offline',
                                        color: _availableNow
                                            ? AppColors.success
                                            : Colors.grey,
                                      ),
                                    ),
                                    const Divider(height: AppSpacing.xl),
                                    SwitchListTile(
                                      dense: true,
                                      value: _nearMe,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: _geoLoading
                                          ? null
                                          : _handleNearMeToggle,
                                      title: Row(
                                        children: [
                                          const Text(
                                            'Near Me',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (_geoLoading) ...[
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: const Text(
                                        'Search professionals within your preferred radius',
                                      ),
                                      secondary: const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (_nearMe) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.radar_rounded,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Slider(
                                              value: _radiusKm,
                                              min: 5,
                                              max: 100,
                                              divisions: 19,
                                              label:
                                                  '${_radiusKm.toStringAsFixed(0)} km',
                                              onChanged: (v) {
                                                setState(() => _radiusKm = v);
                                              },
                                            ),
                                          ),
                                          Text(
                                            '${_radiusKm.toStringAsFixed(0)} km',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: PremiumGlassCard(
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        setState(() => _showFilters = false);
                                      },
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.xl,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.lg,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Close',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.surfaceDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: PremiumGradientButton(
                                      label: 'Apply filters',
                                      icon: Icons.tune_rounded,
                                      onPressed: () {
                                        setState(() => _showFilters = false);
                                        _search();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumSectionTitle(
                      title: 'Sort by',
                      subtitle: _searched
                          ? '${_results.length} professionals found'
                          : 'Choose how results are ranked',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final s in [
                            ('reputation', 'Top Rated'),
                            ('rating', 'Highest Rating'),
                            ('experience', 'Most Experienced'),
                            ('response_time', 'Fastest Response'),
                            if (_nearMe) ('distance', 'Nearest'),
                          ])
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              child: _PremiumSelectableChip(
                                label: s.$2,
                                selected: _sortBy == s.$1,
                                onTap: () {
                                  setState(() => _sortBy = s.$1);
                                  if (_searched) _search();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasFilters) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (_selectedCategoryId != null)
                            _ActiveFilterChip(
                              label: _selectedCategoryName(),
                              icon: Icons.category_rounded,
                              onTap: () {
                                setState(() => _selectedCategoryId = null);
                                if (_searched) _search();
                              },
                            ),
                          if (_maxPrice != null && _maxPrice!.isNotEmpty)
                            _ActiveFilterChip(
                              label: 'Max ₹$_maxPrice',
                              icon: Icons.currency_rupee_rounded,
                              onTap: () {
                                setState(() {
                                  _maxPrice = null;
                                  _maxPriceCtl.clear();
                                });
                                if (_searched) _search();
                              },
                            ),
                          if (_availableNow)
                            _ActiveFilterChip(
                              label: 'Available Now',
                              icon: Icons.bolt_rounded,
                              color: AppColors.success,
                              onTap: () {
                                setState(() => _availableNow = false);
                                if (_searched) _search();
                              },
                            ),
                          if (_nearMe)
                            _ActiveFilterChip(
                              label:
                                  'Within ${_radiusKm.toStringAsFixed(0)} km',
                              icon: Icons.location_on_rounded,
                              color: AppColors.accent,
                              onTap: () {
                                setState(() => _nearMe = false);
                                if (_searched) _search();
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: PremiumLoadingList(itemCount: 4, itemHeight: 124),
                ),
              )
            else if (!_searched)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.huge,
                  ),
                  child: _SearchSuggestions(
                    onSelect: (q) {
                      _searchCtl.text = q;
                      HapticFeedback.selectionClick();
                      _debounce?.cancel();
                      _search();
                    },
                  ),
                ),
              )
            else if (_results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PremiumEmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'No professionals found',
                  subtitle: hasFilters
                      ? 'Try adjusting your filters or searching with a different keyword.'
                      : 'We couldn\'t find anyone matching your search. Try a broader keyword.',
                  actionLabel: hasFilters ? 'Clear filters' : null,
                  onAction: hasFilters ? _clearFilters : null,
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ProfessionalCard(professional: _results[index]),
                    ),
                    childCount: _results.length,
                  ),
                ),
              ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.huge),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.huge),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumSelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PremiumSelectableChip({
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
          color: selected ? null : Colors.white.withAlpha(178),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            width: 1.4,
            color: selected
                ? Colors.transparent
                : AppColors.primary.withAlpha(60),
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActiveFilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      gradient: [color.withAlpha(38), Colors.white.withAlpha(195)],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.close_rounded, size: 14, color: color),
        ],
      ),
    );
  }
}

class _SearchSuggestions extends StatefulWidget {
  final void Function(String query) onSelect;
  const _SearchSuggestions({required this.onSelect});

  @override
  State<_SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<_SearchSuggestions> {
  List<String> _history = [];

  static const _suggestions = [
    ('🔧', 'Plumber'),
    ('⚡', 'Electrician'),
    ('🎨', 'Painter'),
    ('🧹', 'House Cleaning'),
    ('❄️', 'AC Service'),
    ('🪚', 'Carpenter'),
    ('🐜', 'Pest Control'),
    ('🚚', 'Home Shifting'),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await ApiService.get('/search/history', auth: true);
      if (mounted) setState(() => _history = List<String>.from(res['data'] ?? []));
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    try {
      await ApiService.delete('/search/history', auth: true);
      if (mounted) setState(() => _history = []);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart suggestions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pick up where you left off or explore popular searches curated for SkillConnect.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Text(
                        'Recent searches',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _clearHistory();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _history
                        .map(
                          (q) => _SuggestionChip(
                            label: q,
                            icon: Icons.history_rounded,
                            onTap: () => widget.onSelect(q),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumSectionTitle(
            title: 'Popular searches',
            subtitle: 'Instant shortcuts to what customers search most',
          ),
          PremiumGlassCard(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _suggestions
                  .map(
                    (s) => _SuggestionChip(
                      label: '${s.$1}  ${s.$2}',
                      icon: Icons.trending_up_rounded,
                      onTap: () => widget.onSelect(s.$2),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumGlassCard(
            gradient: [AppColors.primary.withAlpha(28), Colors.white.withAlpha(205)],
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro tip',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use filters for availability, price, and distance to discover the perfect professional faster.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.primary.withAlpha(40)),
          boxShadow: AppShadows.sm(AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
