import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';
import '../profile/professional_profile_screen.dart';

/// Category detail: shows subcategories (if any) then professionals in this category.
/// Handles both root categories (shows subcategory grid) and leaf subcategories (shows pros).
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

  static const _sorts = [
    ('rating', 'Top Rated'),
    ('jobs', 'Most Jobs'),
    ('price_asc', 'Price: Low'),
    ('price_desc', 'Price: High'),
    ('newest', 'Newest'),
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
      await _loadPros(reset: true);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subs = (_category?['subcategories'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
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
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Category header
                    SliverToBoxAdapter(child: _buildHeader(cs, subs)),

                    // Subcategory chips (if root category)
                    if (subs.isNotEmpty)
                      SliverToBoxAdapter(child: _buildSubcategoryGrid(context, subs, cs)),

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
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ProfessionalProfileScreen(professionalId: pro.id))),
                              ),
                            );
                          },
                          childCount: _professionals.length + (_hasMore ? 1 : 0),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
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
          _headerChip('${_total} professionals'),
          if (subs.isNotEmpty) ...[
            const SizedBox(width: 8),
            _headerChip('${subs.length} specializations'),
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

  Widget _buildSubcategoryGrid(BuildContext context, List subs, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Specializations', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: (subs as List<dynamic>).map((s) {
            final sub = s as Map<String, dynamic>;
            final count = (sub['pro_count'] as num?)?.toInt() ?? 0;
            return ActionChip(
              avatar: Icon(Icons.arrow_forward_ios, size: 12, color: cs.primary),
              label: Text('${sub['name']}${count > 0 ? ' ($count)' : ''}'),
              backgroundColor: cs.primaryContainer.withAlpha(40),
              side: BorderSide(color: cs.primary.withAlpha(30)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(
                  categoryId: (sub['id'] as num).toInt(),
                  categoryName: sub['name']?.toString() ?? '',
                  categoryDescription: sub['description']?.toString(),
                ),
              )),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Divider(),
      ]),
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
