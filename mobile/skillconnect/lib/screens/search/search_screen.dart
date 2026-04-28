import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';
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
  List<Professional> _results = [];
  List<Category> _categories = [];
  bool _loading = false;
  bool _searched = false;
  String _sortBy = 'reputation';
  int _page = 1;
  int _totalPages = 1;
  int? _selectedCategoryId;
  String? _maxPrice;
  bool _showFilters = false;
  final _maxPriceCtl = TextEditingController();

  // Geo + Availability filters
  bool _availableNow = false;
  bool _nearMe = false;
  double _radiusKm = 25;
  // Hardcoded demo coords (Hyderabad city center) — in production, use geolocator package
  static const double _defaultLat = 17.385;
  static const double _defaultLng = 78.4867;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _loadCategories();
    if (widget.categoryId != null) {
      _search();
    }
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _maxPriceCtl.dispose();
    super.dispose();
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
      if (_nearMe) {
        params['latitude'] = _defaultLat.toString();
        params['longitude'] = _defaultLng.toString();
        params['radius_km'] = _radiusKm.toStringAsFixed(0);
      }
      final res = await ApiService.get('/search', queryParams: params);
      _results = (res['data'] as List).map((e) => Professional.fromJson(e)).toList();
      final pag = res['pagination'];
      _totalPages = pag['pages'] ?? 1;
      _searched = true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _maxPrice = null;
      _maxPriceCtl.clear();
      _availableNow = false;
      _nearMe = false;
      _radiusKm = 25;
    });
    if (_searched) _search();
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
                  onSubmitted: (_) => _search(),
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
                  onChanged: (v) => setState(() => _nearMe = v),
                  title: const Text('Near Me', style: TextStyle(fontWeight: FontWeight.w600)),
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
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Search for professionals', style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('Use filters to narrow results', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                      ]))
                    : _results.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No professionals found'),
                            if (hasFilters) ...[
                              const SizedBox(height: 8),
                              TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
                            ],
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length + (_totalPages > _page ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _results.length) {
                                return Center(child: TextButton(onPressed: () => _search(page: _page + 1), child: const Text('Load More')));
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
