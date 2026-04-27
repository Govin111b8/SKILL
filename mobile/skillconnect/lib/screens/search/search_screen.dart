import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtl = TextEditingController();
  List<Professional> _results = [];
  bool _loading = false;
  bool _searched = false;
  String _sortBy = 'reputation';
  int _page = 1;
  int _totalPages = 1;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Professionals')),
      body: Column(
        children: [
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
              FilledButton(onPressed: _search, child: const Text('Go')),
            ]),
          ),
          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              for (final s in [('reputation', 'Top Rated'), ('rating', 'Highest Rating'), ('experience', 'Most Experienced')])
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
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Search for professionals', style: TextStyle(color: Colors.grey.shade500)),
                      ]))
                    : _results.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No professionals found'),
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
