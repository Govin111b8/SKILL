import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../widgets/professional_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Professional> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await NotificationsService.listFavorites();
      _items = raw.map((e) => Professional.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Professionals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: const Text('Retry')),
                  ])))
              : _items.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(40),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No favorites yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Tap the heart on any professional to save them here.',
                            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                      ])))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => Dismissible(
                          key: ValueKey(_items[i].id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(18)),
                            child: const Icon(Icons.heart_broken, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            try {
                              await NotificationsService.toggleFavorite(_items[i].id);
                              return true;
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
                              return false;
                            }
                          },
                          onDismissed: (_) {
                            setState(() => _items.removeAt(i));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
                          },
                          child: ProfessionalCard(professional: _items[i]),
                        ),
                      ),
                    ),
    );
  }
}
