import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

/// Food screen — browse restaurant / home-chef professionals, order meals.
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  static const _cuisines = ['All', 'Indian', 'Chinese', 'South Indian', 'Biryani', 'Snacks', 'Desserts', 'Healthy'];
  int _selectedCuisine = 0;
  List<Map<String, dynamic>> _chefs = [];
  bool _loading = true;
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
        '/search',
        queryParams: {'category': 'Food', 'limit': '12', 'sort_by': 'rating'},
      );
      final list = res['data'] as List? ?? [];
      _chefs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _chefs = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  int get _cartTotal => _cart.values.fold(0, (a, b) => a + b);

  static const _menuItems = [
    _MenuItem('Butter Chicken', '🍗', 180, 'Indian'),
    _MenuItem('Fried Rice', '🍚', 120, 'Chinese'),
    _MenuItem('Masala Dosa', '🫓', 80, 'South Indian'),
    _MenuItem('Chicken Biryani', '🍛', 220, 'Biryani'),
    _MenuItem('Samosa', '🥟', 30, 'Snacks'),
    _MenuItem('Gulab Jamun', '🍩', 60, 'Desserts'),
    _MenuItem('Salad Bowl', '🥗', 150, 'Healthy'),
    _MenuItem('Dal Makhani', '🫕', 140, 'Indian'),
  ];

  List<_MenuItem> get _filteredMenu {
    final cuisine = _cuisines[_selectedCuisine];
    if (cuisine == 'All') return _menuItems;
    return _menuItems.where((m) => m.category == cuisine).toList();
  }

  void _addToCart(String name, int price) {
    HapticFeedback.selectionClick();
    setState(() {
      _cart[name] = (_cart[name] ?? 0) + price;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _filteredMenu;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.tileFood,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('Food', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6D00), Color(0xFFE64A19)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text('🍽️', style: TextStyle(fontSize: 72)),
                  ),
                ),
              ),
            ),
            actions: [
              if (_cartTotal > 0)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                      onPressed: () => _showCart(context),
                    ),
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$_cartTotal', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Cuisine filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: _cuisines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = i == _selectedCuisine;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCuisine = i);
                    },
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.tileFood : (isDark ? AppColors.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: selected ? AppColors.tileFood : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Text(
                        _cuisines[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Nearby chefs
          if (_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonProfessionalCard()))),
              ),
            )
          else if (_chefs.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                child: Text('Nearby Chefs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 130,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: _chefs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final chef = _chefs[i];
                    final name = chef['name']?.toString() ?? 'Chef';
                    final rating = (chef['avg_rating'] as num?)?.toDouble() ?? 4.5;
                    return Container(
                      width: 110,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('👨‍🍳', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFA000)),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ],

          // Menu items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
              child: Text('Menu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No items for this cuisine', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = items[i];
                  final inCart = _cart.containsKey(item.name);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: inCart ? AppColors.tileFood : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                      ),
                      child: Row(children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(item.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _addToCart(item.name, item.price),
                            child: AnimatedContainer(
                              duration: AppDurations.normal,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: inCart ? AppColors.tileFood : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.tileFood),
                              ),
                              child: Text(
                                inCart ? 'Added ✓' : 'Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: inCart ? Colors.white : AppColors.tileFood,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _cartTotal > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ElevatedButton.icon(
                  onPressed: () => _showCart(context),
                  icon: const Icon(Icons.shopping_cart_rounded),
                  label: Text('View Cart (${_cart.keys.length} items · ₹${_cart.values.fold(0, (a, b) => a + b)})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tileFood,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showCart(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ..._cart.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('₹${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              )),
              const Divider(height: 24),
              Row(children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('₹${_cart.values.fold(0, (a, b) => a + b)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.tileFood)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/payment', arguments: {
                      'bookingId': 'food-order',
                      'amount': _cart.values.fold<int>(0, (a, b) => a + b).toDouble(),
                      'professionalName': 'Food Order',
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tileFood,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String name;
  final String emoji;
  final int price;
  final String category;
  const _MenuItem(this.name, this.emoji, this.price, this.category);
}
