import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

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
        if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
      });
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['professionals'] as List? ?? const [])
              : const [];
      _professionals = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showProfessional(Map<String, dynamic> pro) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pro['name']?.toString() ?? 'Professional', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('⭐ ${pro['average_rating'] ?? 0} • ${pro['category_name'] ?? pro['headline'] ?? 'Service'}'),
            const SizedBox(height: 4),
            Text(pro['location']?.toString() ?? 'Nearby'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pushNamed(context, '/professional/${pro['id']}'), child: const Text('Book Now')),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Search')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _mapMode = !_mapMode),
        icon: Icon(_mapMode ? Icons.list_rounded : Icons.map_rounded),
        label: Text(_mapMode ? 'List View' : 'Map View'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? ListView(children: const [SizedBox(height: 280, child: Center(child: CircularProgressIndicator()))])
                : _error != null
                    ? ListView(children: [EmptyStateWidget(icon: Icons.map_outlined, iconColor: Colors.red, title: 'Could not load nearby professionals', subtitle: _error!, actionLabel: 'Retry', onAction: _load)])
                    : _mapMode
                        ? ListView(
                            padding: const EdgeInsets.only(top: 92, bottom: 110),
                            children: [
                              Container(
                                height: 520,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                  gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer]),
                                ),
                                child: Stack(
                                  children: [
                                    const Positioned.fill(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          '// Note: Replace the placeholder below with actual GoogleMap widget when API key is configured:\n// GoogleMap(\n//   initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 13),\n//   markers: _markers,\n//   onMapCreated: (controller) => _mapController = controller,\n// )',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                    ..._professionals.take(8).toList().asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final pro = entry.value;
                                      return Positioned(
                                        left: 32.0 + (index % 3) * 100,
                                        top: 70.0 + (index * 54 % 280),
                                        child: GestureDetector(
                                          onTap: () => _showProfessional(pro),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                                            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 92, bottom: 110),
                            itemCount: _professionals.length,
                            itemBuilder: (context, index) {
                              final pro = _professionals[index];
                              return Container(
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                                child: ListTile(
                                  onTap: () => _showProfessional(pro),
                                  leading: CircleAvatar(child: Text((pro['name'] ?? '').toString().trim().isEmpty ? '?' : (pro['name'] ?? '').toString().trim()[0].toUpperCase())),
                                  title: Text(pro['name']?.toString() ?? 'Professional', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text('${pro['category_name'] ?? pro['headline'] ?? 'Service'} • ⭐ ${pro['average_rating'] ?? 0}'),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                ),
                              );
                            },
                          ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search nearby services',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: _load),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                ),
                onSubmitted: (_) => _load(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: _categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category['label']!),
                    selected: _categoryId == category['id'],
                    onSelected: (_) {
                      setState(() => _categoryId = category['id']!);
                      _load();
                    },
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
