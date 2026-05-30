import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';

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
    final items = _filteredMenu;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _cartTotal > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: PremiumGradientButton(
                    label: 'View Cart (${_cart.keys.length} items · ₹${_cart.values.fold(0, (a, b) => a + b)})',
                    icon: Icons.shopping_cart_rounded,
                    colors: const [Color(0xFFFF6D00), Color(0xFFE64A19)],
                    onPressed: () => _showCart(context),
                  ),
                ),
              ),
            )
          : null,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PremiumHeroHeader(
                  title: 'Food',
                  subtitle: 'Home chefs & restaurants near you',
                  icon: Icons.restaurant_rounded,
                  gradient: const [Color(0xFFFF6D00), Color(0xFFE64A19)],
                  trailing: _cartTotal > 0
                      ? GestureDetector(
                          onTap: () => _showCart(context),
                          child: Stack(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(28),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: Colors.white.withAlpha(50)),
                                ),
                                child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
                              ),
                              Positioned(
                                right: 4, top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text('$_cartTotal', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
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
                            gradient: selected
                                ? const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFE64A19)])
                                : null,
                            color: selected ? null : Colors.white.withAlpha(200),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: selected ? Colors.transparent : AppColors.borderLight),
                            boxShadow: selected ? AppShadows.sm(AppColors.tileFood) : null,
                          ),
                          child: Text(
                            _cuisines[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.surfaceDark,
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
                SliverToBoxAdapter(child: PremiumLoadingList(itemCount: 3, itemHeight: 120))
              else if (_chefs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: PremiumSectionTitle(
                    title: 'Nearby Chefs',
                    subtitle: 'Home chefs ready to cook for you',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      scrollDirection: Axis.horizontal,
                      itemCount: _chefs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final chef = _chefs[i];
                        final name = chef['name']?.toString() ?? 'Chef';
                        final rating = (chef['avg_rating'] as num?)?.toDouble() ?? 4.5;
                        return PremiumGlassCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: SizedBox(
                            width: 100,
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Text('👨‍🍳', style: TextStyle(fontSize: 28)),
                              const SizedBox(height: 6),
                              Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFA000)),
                                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Menu section
              SliverToBoxAdapter(
                child: PremiumSectionTitle(
                  title: 'Menu',
                  subtitle: _cuisines[_selectedCuisine] == 'All' ? 'All dishes' : '${_cuisines[_selectedCuisine]} cuisine',
                ),
              ),
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: PremiumEmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'No items found',
                    subtitle: 'No dishes for this cuisine yet.\nTry another category.',
                    gradient: const [Color(0xFFFF6D00), Color(0xFFE64A19)],
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
                        child: PremiumGlassCard(
                          gradient: inCart
                              ? [AppColors.tileFood.withAlpha(30), AppColors.tileFood.withAlpha(15)]
                              : null,
                          child: Row(children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(item.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('₹${item.price}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _addToCart(item.name, item.price),
                                child: AnimatedContainer(
                                  duration: AppDurations.normal,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: inCart ? const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFE64A19)]) : null,
                                    color: inCart ? null : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: inCart ? Colors.transparent : AppColors.tileFood,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    inCart ? 'Added ✓' : 'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }

  void _showCart(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFE64A19)]),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Your Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: AppSpacing.lg),
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
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.tileFood)),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PremiumGradientButton(
                  label: 'Checkout',
                  colors: const [Color(0xFFFF6D00), Color(0xFFE64A19)],
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/payment', arguments: {
                      'bookingId': 'food-order',
                      'amount': _cart.values.fold<int>(0, (a, b) => a + b).toDouble(),
                      'professionalName': 'Food Order',
                    });
                  },
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
