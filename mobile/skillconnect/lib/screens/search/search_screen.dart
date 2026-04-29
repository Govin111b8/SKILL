import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../data/services_catalog.dart';

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

  // Geo + Availability filters
  bool _availableNow = false;
  bool _nearMe = false;
  double _radiusKm = 25;
  double? _userLat;
  double? _userLng;
  bool _geoLoading = false;
  // Fallback coords (Hyderabad) used only if permission denied
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

  /// Request permission and fetch real device coordinates.
  /// Falls back to hardcoded Hyderabad coords if permission denied.
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

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showGeoSnackBar('Location permission denied. Using default city.');
        _userLat = _fallbackLat;
        _userLng = _fallbackLng;
        if (mounted) setState(() => _geoLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200 && !_loadingMore && _page < _totalPages) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final params = <String, String>{
        'sort_by': _sortBy, 'page': nextPage.toString(), 'limit': '20',
      };
      if (_searchCtl.text.trim().isNotEmpty) params['q'] = _searchCtl.text.trim();
      if (_selectedCategoryId != null) params['category_id'] = _selectedCategoryId.toString();
      if (_maxPrice != null && _maxPrice!.isNotEmpty) params['max_price'] = _maxPrice!;
      if (_availableNow) params['availability'] = 'available';
      if (_nearMe && _userLat != null && _userLng != null) {
        params['latitude'] = _userLat.toString(); params['longitude'] = _userLng.toString(); params['radius_km'] = _radiusKm.toStringAsFixed(0);
      }
      final res = await ApiService.get('/search', queryParams: params);
      final next = (res['data'] as List).map((e) => Professional.fromJson(e as Map<String, dynamic>)).toList();
      final pag = res['pagination'] as Map?;
      _totalPages = (pag?['pages'] as num?)?.toInt() ?? 1;
      _page = nextPage;
      if (mounted) setState(() { _results.addAll(next); _loadingMore = false; });
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
      _categories = (res['data'] as List).map((e) => Category.fromJson(e)).toList();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _search({int page = 1}) async {
    setState(() { _loading = true; _page = page; });
    try {
      final params = <String, String>{
        'sort_by': _sortBy,
        'page': page.toString(),
        'limit': '20',
      };
      if (_searchCtl.text.trim().isNotEmpty) params['q'] = _searchCtl.text.trim();
      if (_selectedCategoryId != null) params['category_id'] = _selectedCategoryId.toString();
      if (_maxPrice != null && _maxPrice!.isNotEmpty) params['max_price'] = _maxPrice!;
      if (_availableNow) params['availability'] = 'available';
      if (_nearMe && _userLat != null && _userLng != null) {
        params['latitude'] = _userLat.toString();
        params['longitude'] = _userLng.toString();
        params['radius_km'] = _radiusKm.toStringAsFixed(0);
      }
      final res = await ApiService.get('/search', queryParams: params);
      _results = (res['data'] as List).map((e) => Professional.fromJson(e as Map<String, dynamic>)).toList();
      final pag = res['pagination'] as Map?;
      _totalPages = (pag?['pages'] as num?)?.toInt() ?? 1;
      _searched = true;
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.red.shade700));
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFilters = _selectedCategoryId != null || (_maxPrice != null && _maxPrice!.isNotEmpty) || _availableNow || _nearMe;
    final svc = widget.categoryId != null ? findServiceById(widget.categoryId!) : null;
    final hub = widget.categoryId != null ? findHubById(widget.categoryId!) : null;
    final themeColors = svc?.gradient ?? hub?.gradient ?? const [Color(0xFF6366F1), Color(0xFF8B5CF6)];

    return Scaffold(
      appBar: AppBar(
        title: widget.categoryName != null ? Text(widget.categoryName!) : const Text('Search Professionals'),
        automaticallyImplyLeading: widget.categoryId != null,
        flexibleSpace: widget.categoryId != null
            ? Container(decoration: BoxDecoration(gradient: LinearGradient(colors: themeColors)))
            : null,
        foregroundColor: widget.categoryId != null ? Colors.white : null,
      ),
      body: Column(
        children: [
          // Service banner
          if (svc != null || hub != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: themeColors),
                boxShadow: [BoxShadow(color: themeColors.first.withAlpha(80), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(80))),
                  child: Icon(svc?.icon ?? hub?.icon ?? Icons.apps, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(svc?.emoji ?? hub?.emoji ?? '⭐', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(svc?.name ?? hub?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    Text(svc?.tagline ?? hub?.description ?? '', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(100)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),
          ],

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, skill, or keyword...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtl.clear(); setState(() {}); })
                        : null,
                  ),
                  onSubmitted: (_) { _debounce?.cancel(); _search(); },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: () => _search(), child: const Text('Go')),
              const SizedBox(width: 4),
              IconButton(
                icon: Badge(
                  isLabelVisible: hasFilters,
                  child: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
            ]),
          ),

          // Filters panel
          if (_showFilters) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: cs.surfaceContainerHighest.withAlpha(80),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Category dropdown
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category), isDense: true),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                const SizedBox(height: 10),
                // Max price
                TextField(
                  controller: _maxPriceCtl,
                  decoration: const InputDecoration(labelText: 'Max Price (₹)', prefixIcon: Icon(Icons.attach_money), isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _maxPrice = v,
                ),
                const SizedBox(height: 14),
                // Available Now toggle
                SwitchListTile(
                  dense: true,
                  value: _availableNow,
                  onChanged: (v) => setState(() => _availableNow = v),
                  title: const Text('Available Now', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Only show pros currently online'),
                  secondary: Icon(Icons.circle, size: 14, color: _availableNow ? Colors.green : Colors.grey.shade400),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                // Near Me toggle + radius
                SwitchListTile(
                  dense: true,
                  value: _nearMe,
                  onChanged: _geoLoading ? null : (v) async {
                    if (v && _userLat == null) {
                      await _fetchLocation();
                    }
                    if (mounted) setState(() => _nearMe = v);
                  },
                  title: Row(children: [
                    const Text('Near Me', style: TextStyle(fontWeight: FontWeight.w600)),
                    if (_geoLoading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ]),
                  subtitle: const Text('Professionals within radius'),
                  secondary: Icon(Icons.location_on, color: _nearMe ? cs.primary : Colors.grey.shade400),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_nearMe) ...[                  
                  Row(children: [
                    const SizedBox(width: 4),
                    const Icon(Icons.straighten, size: 16),
                    Expanded(child: Slider(
                      value: _radiusKm,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: '${_radiusKm.toStringAsFixed(0)} km',
                      onChanged: (v) => setState(() => _radiusKm = v),
                    )),
                    Text('${_radiusKm.toStringAsFixed(0)} km', style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
                  ]),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  TextButton(onPressed: _clearFilters, child: const Text('Clear Filters')),
                  const Spacer(),
                  FilledButton.tonal(onPressed: () { setState(() => _showFilters = false); _search(); }, child: const Text('Apply')),
                ]),
              ]),
            ),
          ],

          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              for (final s in [('reputation', 'Top Rated'), ('rating', 'Highest Rating'), ('experience', 'Most Experienced'), if (_nearMe) ('distance', 'Nearest')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.$2),
                    selected: _sortBy == s.$1,
                    onSelected: (_) { setState(() => _sortBy = s.$1); if (_searched) _search(); },
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),

          // Active filters chips
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                if (_selectedCategoryId != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(_categories.where((c) => c.id == _selectedCategoryId).firstOrNull?.name ?? 'Category', style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () { setState(() => _selectedCategoryId = null); if (_searched) _search(); },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (_maxPrice != null && _maxPrice!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text('Max ₹$_maxPrice', style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () { setState(() { _maxPrice = null; _maxPriceCtl.clear(); }); if (_searched) _search(); },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (_availableNow)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      avatar: const Icon(Icons.circle, size: 10, color: Colors.green),
                      label: const Text('Available Now', style: TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () { setState(() => _availableNow = false); if (_searched) _search(); },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (_nearMe)
                  Chip(
                    avatar: const Icon(Icons.location_on, size: 14),
                    label: Text('Within ${_radiusKm.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () { setState(() => _nearMe = false); if (_searched) _search(); },
                    visualDensity: VisualDensity.compact,
                  ),
              ]),
            ),

          // Results
          Expanded(
            child: _loading
                ? ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => const SkeletonProfessionalCard(),
                  )
                : !_searched
                    ? _SearchSuggestions(
                        onSelect: (q) {
                          _searchCtl.text = q;
                          HapticFeedback.selectionClick();
                          _debounce?.cancel();
                          _search();
                        },
                      )
                    : _results.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.person_search_rounded,
                            iconColor: const Color(0xFF6366F1),
                            title: 'No professionals found',
                            subtitle: hasFilters
                                ? 'Try adjusting your filters or searching a different keyword.'
                                : 'We couldn\'t find anyone matching your search. Try a different keyword.',
                            actionLabel: hasFilters ? 'Clear filters' : null,
                            onAction: hasFilters ? _clearFilters : null,
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _results.length) {
                                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ProfessionalCard(professional: _results[i]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final void Function(String query) onSelect;
  const _SearchSuggestions({required this.onSelect});

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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Popular searches', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () => onSelect(s.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.$1, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(s.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withAlpha(30)),
          ),
          child: Row(children: [
            Icon(Icons.lightbulb_outline_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tip: Use filters for better results', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.primary)),
              const SizedBox(height: 2),
              Text('Filter by availability, price range, and distance to find the perfect match.', style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
            ])),
          ]),
        ),
      ],
    );
  }
}
