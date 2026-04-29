import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';
import '../../data/services_catalog.dart';

/// Category detail: shows subcategories (if any) then professionals in this category.
/// Handles both root categories (shows subcategory grid only) and leaf subcategories (shows pros).
class CategoryDetailScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String? categoryDescription;
  final bool isRoot; // root = has children; leaf = show pros directly

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    this.isRoot = false,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  Map<String, dynamic>? _category;
  List<Professional> _professionals = [];
  bool _loading = true;
  bool _loadingPros = false;
  String? _error;
  String _sortBy = 'rating';
  String? _availability;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  /// Whether this category has subcategories (determined after API fetch).
  bool get _hasSubcategories => ((_category?['subcategories'] as List?) ?? []).isNotEmpty;

  static const _sorts = [
    ('rating', 'Top Rated'),
    ('jobs', 'Most Jobs'),
    ('price_asc', 'Price: Low'),
    ('price_desc', 'Price: High'),
    ('newest', 'Newest'),
  ];

  // Gradient colors for subcategory cards
  static const _gradients = [
    [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFEAB308)],
    [Color(0xFF92400E), Color(0xFFB45309)],
    [Color(0xFFEC4899), Color(0xFFA855F7)],
    [Color(0xFF10B981), Color(0xFF14B8A6)],
    [Color(0xFF22C55E), Color(0xFF16A34A)],
    [Color(0xFF7C2D12), Color(0xFFDC2626)],
    [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    [Color(0xFF059669), Color(0xFF047857)],
  ];

  // Icons for subcategory cards
  static const _subIcons = [
    Icons.plumbing,
    Icons.electrical_services,
    Icons.handyman,
    Icons.format_paint,
    Icons.cleaning_services,
    Icons.grass,
    Icons.pest_control,
    Icons.ac_unit,
    Icons.roofing,
    Icons.kitchen,
    Icons.restaurant,
    Icons.camera_alt,
    Icons.videocam,
    Icons.music_note,
    Icons.event,
    Icons.celebration,
    Icons.mic,
    Icons.location_city,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      _loadMorePros();
    }
  }

  Future<void> _loadCategory() async {
    try {
      final res = await ApiService.get('/categories/${widget.categoryId}');
      if (mounted) setState(() { _category = res['data']; });
      // Only load professionals if this is a leaf category (no subcategories)
      final subs = (res['data']?['subcategories'] as List?) ?? [];
      if (subs.isEmpty) {
        await _loadPros(reset: true);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPros({bool reset = false}) async {
    if (_loadingPros) return;
    if (!reset && !_hasMore) return;
    setState(() => _loadingPros = true);
    final nextPage = reset ? 1 : _page + 1;
    try {
      final params = {
        'sort_by': _sortBy,
        'limit': '20',
        'page': '$nextPage',
        if (_availability != null) 'availability': _availability!,
      };
      final res = await ApiService.get('/categories/${widget.categoryId}/professionals', queryParams: params);
      final newPros = (res['data'] as List).map((e) => Professional.fromJson(e as Map<String, dynamic>)).toList();
      final pagination = res['pagination'] as Map?;
      final total = (pagination?['total'] as num?)?.toInt() ?? 0;
      setState(() {
        if (reset) _professionals = newPros;
        else _professionals = [..._professionals, ...newPros];
        _page = nextPage;
        _total = total;
        _hasMore = _professionals.length < total;
        _loadingPros = false;
      });
    } catch (_) {
      setState(() => _loadingPros = false);
    }
  }

  Future<void> _loadMorePros() => _loadPros();

  void _applyFilters({String? sort, String? avail}) {
    setState(() {
      if (sort != null) _sortBy = sort;
      if (avail != null) _availability = avail == 'all' ? null : avail;
      _page = 1;
      _hasMore = true;
    });
    _loadPros(reset: true);
  }

  IconData _iconForSub(Map<String, dynamic> sub, int index) {
    // Try to match from static catalog by name or id
    final subId = (sub['id'] as num?)?.toInt();
    if (subId != null) {
      final service = findServiceById(subId);
      if (service != null) return service.icon;
    }
    return _subIcons[index % _subIcons.length];
  }

  List<Color> _gradientForSub(Map<String, dynamic> sub, int index) {
    // Try to match from static catalog by id
    final subId = (sub['id'] as num?)?.toInt();
    if (subId != null) {
      final service = findServiceById(subId);
      if (service != null) return service.gradient;
    }
    return _gradients[index % _gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subs = (_category?['subcategories'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          // Only show filter button when showing professionals (leaf category)
          if (!_hasSubcategories)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Filter & Sort',
              onPressed: _showFilterSheet,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _hasSubcategories
                  ? _buildSubServicesView(context, subs, cs)
                  : _buildProfessionalsView(cs, subs),
    );
  }

  /// View for root categories: shows prominent sub-service cards
  Widget _buildSubServicesView(BuildContext context, List subs, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Category header
        _buildHeader(cs, subs),

        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('Choose a Service', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${subs.length} services', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('Tap a service to view skilled professionals', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ),

        // Sub-services grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: subs.length,
            itemBuilder: (_, i) {
              final sub = subs[i] as Map<String, dynamic>;
              final subName = sub['name']?.toString() ?? '';
              final subDesc = sub['description']?.toString() ?? '';
              final proCount = (sub['pro_count'] as num?)?.toInt() ?? 0;
              final gradient = _gradientForSub(sub, i);
              final icon = _iconForSub(sub, i);

              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(
                    categoryId: (sub['id'] as num).toInt(),
                    categoryName: subName,
                    categoryDescription: subDesc,
                  ),
                )),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: gradient.first.withAlpha(60), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Stack(children: [
                    Positioned(top: -10, right: -10, child: Icon(icon, size: 70, color: Colors.white.withAlpha(30))),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Icon(icon, color: Colors.white, size: 28),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(subName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (proCount > 0)
                          Text('$proCount professionals', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11))
                        else
                          Text('View professionals', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11)),
                      ]),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// View for leaf categories: shows professionals list
  Widget _buildProfessionalsView(ColorScheme cs, List subs) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Category header
        SliverToBoxAdapter(child: _buildHeader(cs, subs)),

        // Pro count + sort bar
        SliverToBoxAdapter(child: _buildProBar(cs)),

        // Professional list
        if (_professionals.isEmpty && !_loadingPros)
          SliverToBoxAdapter(child: _emptyPros())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i == _professionals.length) {
                  return _loadingPros
                      ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                      : const SizedBox.shrink();
                }
                final pro = _professionals[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ProfessionalCard(
                    professional: pro,
                  ),
                );
              },
              childCount: _professionals.length + (_hasMore ? 1 : 0),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs, List subs) {
    final desc = widget.categoryDescription ?? _category?['description']?.toString();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [cs.primary, cs.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cs.primary.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.categoryName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        if (desc != null) ...[
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          if (subs.isNotEmpty) ...[
            _headerChip('${subs.length} sub-services'),
          ] else ...[
            _headerChip('$_total professionals'),
          ],
        ]),
      ]),
    );
  }

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(70)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildProBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Text('$_total professionals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700)),
        const Spacer(),
        // Availability filter
        DropdownButton<String>(
          value: _availability ?? 'all',
          underline: const SizedBox.shrink(),
          style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Any status')),
            DropdownMenuItem(value: 'available', child: Text('Available')),
            DropdownMenuItem(value: 'busy', child: Text('Busy')),
          ],
          onChanged: (v) => _applyFilters(avail: v),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _sortBy,
          underline: const SizedBox.shrink(),
          style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
          items: _sorts.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
          onChanged: (v) => _applyFilters(sort: v),
        ),
      ]),
    );
  }

  Widget _emptyPros() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(Icons.person_search, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No professionals found', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Text('Try a different filter or check back later.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _errorView() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
      const SizedBox(height: 12),
      Text(_error ?? 'Something went wrong', style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: _loadCategory, child: const Text('Retry')),
    ]));
  }

  void _showFilterSheet() {
    showModalBottomSheet(context: context, builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sort & Filter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 16),
        const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _sorts.map((s) => ChoiceChip(
          label: Text(s.$2),
          selected: _sortBy == s.$1,
          onSelected: (_) { Navigator.pop(context); _applyFilters(sort: s.$1); },
        )).toList()),
        const SizedBox(height: 16),
        const Text('Availability', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('All'), selected: _availability == null, onSelected: (_) { Navigator.pop(context); _applyFilters(avail: 'all'); }),
          ChoiceChip(label: const Text('Available'), selected: _availability == 'available', onSelected: (_) { Navigator.pop(context); _applyFilters(avail: 'available'); }),
          ChoiceChip(label: const Text('Busy'), selected: _availability == 'busy', onSelected: (_) { Navigator.pop(context); _applyFilters(avail: 'busy'); }),
        ]),
        const SizedBox(height: 16),
      ]),
    ));
  }
}
