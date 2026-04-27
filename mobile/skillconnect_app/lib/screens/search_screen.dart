import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/professional.dart';
import '../widgets/professional_card.dart';
import 'professional_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  final AuthProvider auth;
  final String? initialQuery;
  const SearchScreen({super.key, required this.auth, this.initialQuery});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryCtrl = TextEditingController();
  List<Professional> _results = [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  // Filters
  double _minRating = 0;
  double _maxPrice = 10000;
  bool _availableOnly = false;
  String _sortBy = 'reputation';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _queryCtrl.text = widget.initialQuery!;
      _search();
    }
  }

  Future<void> _search({int page = 1}) async {
    setState(() { _loading = true; _error = null; });
    try {
      var endpoint = '/search?q=${Uri.encodeComponent(_queryCtrl.text.trim())}'
          '&sort_by=$_sortBy&page=$page&limit=10';
      if (_minRating > 0) endpoint += '&min_rating=${_minRating.toInt()}';
      if (_maxPrice < 10000) endpoint += '&max_price=${_maxPrice.toInt()}';
      if (_availableOnly) endpoint += '&availability=available';

      final data = await ApiService.get(endpoint);
      final list = data['professionals'] as List? ?? [];
      final pagination = data['pagination'] as Map? ?? {};
      setState(() {
        _results = list.map((j) => Professional.fromJson(j)).toList();
        _page = pagination['page'] ?? page;
        _totalPages = pagination['totalPages'] ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Minimum Rating: ${_minRating.toInt()} stars'),
            Slider(value: _minRating, max: 5, divisions: 5, label: '${_minRating.toInt()}', onChanged: (v) => setSheetState(() => _minRating = v)),
            const SizedBox(height: 12),
            Text('Max Price: \$${_maxPrice.toInt()}'),
            Slider(value: _maxPrice, min: 0, max: 10000, divisions: 100, onChanged: (v) => setSheetState(() => _maxPrice = v)),
            const SizedBox(height: 12),
            SwitchListTile(title: const Text('Available Only'), value: _availableOnly, onChanged: (v) => setSheetState(() => _availableOnly = v)),
            const SizedBox(height: 12),
            const Text('Sort By'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Reputation'), selected: _sortBy == 'reputation', onSelected: (_) => setSheetState(() => _sortBy = 'reputation')),
              ChoiceChip(label: const Text('Rating'), selected: _sortBy == 'rating', onSelected: (_) => setSheetState(() => _sortBy = 'rating')),
              ChoiceChip(label: const Text('Experience'), selected: _sortBy == 'experience', onSelected: (_) => setSheetState(() => _sortBy = 'experience')),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { Navigator.pop(ctx); _search(); }, child: const Text('Apply Filters'))),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Professionals'),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilters),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      OutlinedButton(onPressed: _search, child: const Text('Retry')),
                    ]))
                  : _results.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(_queryCtrl.text.isEmpty ? 'Search for professionals' : 'No results found',
                              style: TextStyle(color: Colors.grey[600])),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _results.length + 1,
                          itemBuilder: (_, i) {
                            if (i == _results.length) {
                              return _totalPages > 1
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        if (_page > 1) TextButton(onPressed: () => _search(page: _page - 1), child: const Text('Previous')),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$_page / $_totalPages')),
                                        if (_page < _totalPages) TextButton(onPressed: () => _search(page: _page + 1), child: const Text('Next')),
                                      ]),
                                    )
                                  : const SizedBox(height: 16);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProfessionalCard(
                                professional: _results[i],
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ProfessionalProfileScreen(professionalId: _results[i].id, auth: widget.auth),
                                )),
                              ),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}
