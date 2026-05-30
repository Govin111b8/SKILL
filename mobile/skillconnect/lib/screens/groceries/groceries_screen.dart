import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

/// Groceries screen — browse and order groceries from local kirana/store providers.
class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  static const _categories = [
    _GroceryCategory('Vegetables', '🥦', [
      _Product('Tomatoes', '🍅', 30, '1 kg'),
      _Product('Onions', '🧅', 20, '1 kg'),
      _Product('Spinach', '🌿', 25, '250 g'),
      _Product('Carrot', '🥕', 35, '500 g'),
    ]),
    _GroceryCategory('Dairy', '🥛', [
      _Product('Milk', '🥛', 60, '1 L'),
      _Product('Curd', '🫙', 45, '500 g'),
      _Product('Paneer', '🧀', 90, '200 g'),
      _Product('Butter', '🧈', 55, '100 g'),
    ]),
    _GroceryCategory('Fruits', '🍎', [
      _Product('Apples', '🍎', 80, '1 kg'),
      _Product('Bananas', '🍌', 40, '1 dozen'),
      _Product('Mangoes', '🥭', 120, '1 kg'),
      _Product('Grapes', '🍇', 60, '500 g'),
    ]),
    _GroceryCategory('Grains', '🌾', [
      _Product('Rice', '🌾', 70, '1 kg'),
      _Product('Wheat Flour', '🫙', 45, '1 kg'),
      _Product('Dal', '🫘', 90, '500 g'),
      _Product('Oats', '🥣', 110, '500 g'),
    ]),
  ];

  int _selectedCategory = 0;
  final Map<String, int> _cart = {}; // productName -> quantity

  void _addToCart(String name, int price) {
    HapticFeedback.selectionClick();
    setState(() {
      _cart[name] = (_cart[name] ?? 0) + 1;
    });
  }

  void _removeFromCart(String name) {
    HapticFeedback.selectionClick();
    setState(() {
      final qty = (_cart[name] ?? 0) - 1;
      if (qty <= 0) {
        _cart.remove(name);
      } else {
        _cart[name] = qty;
      }
    });
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final cat = _categories[_selectedCategory];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _cartItemCount > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: PremiumGradientButton(
                    label: 'Checkout ($_cartItemCount items)',
                    icon: Icons.shopping_basket_rounded,
                    colors: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    onPressed: () => _showCart(context),
                  ),
                ),
              ),
            )
          : null,
      body: PremiumBackground(
        colors: const [Color(0xFFF3FFF5), Color(0xFFEDF7EF), Color(0xFFE8F5E9)],
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PremiumHeroHeader(
                  title: 'Groceries',
                  subtitle: 'Fresh produce from local stores',
                  icon: Icons.shopping_basket_rounded,
                  gradient: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  trailing: _cartItemCount > 0
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
                                child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 22),
                              ),
                              Positioned(
                                right: 4, top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text('$_cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  chips: const [
                    PremiumStatChip(label: '🛒 Express Delivery', color: Colors.white),
                    PremiumStatChip(label: '🌿 Fresh Daily', color: Colors.white),
                  ],
                ),
              ),

              // Category tabs
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      final selected = i == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = i);
                        },
                        child: AnimatedContainer(
                          duration: AppDurations.normal,
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)])
                                : null,
                            color: selected ? null : Colors.white.withAlpha(200),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: selected ? Colors.transparent : AppColors.borderLight,
                              width: selected ? 0 : 1,
                            ),
                            boxShadow: selected ? AppShadows.md(AppColors.tileGroceries) : null,
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(c.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              c.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppColors.surfaceDark,
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Category header
              SliverToBoxAdapter(
                child: PremiumSectionTitle(
                  title: '${cat.emoji} ${cat.name}',
                  subtitle: '${cat.products.length} items available',
                ),
              ),

              // Products grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final p = cat.products[i];
                      final qty = _cart[p.name] ?? 0;
                      return PremiumGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        gradient: qty > 0
                            ? [AppColors.tileGroceries.withAlpha(30), AppColors.tileGroceries.withAlpha(15)]
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.emoji, style: const TextStyle(fontSize: 32)),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(p.unit, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ]),
                            Row(children: [
                              Text('₹${p.price}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              const Spacer(),
                              if (qty == 0)
                                GestureDetector(
                                  onTap: () => _addToCart(p.name, p.price),
                                  child: Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                                  ),
                                )
                              else
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  GestureDetector(
                                    onTap: () => _removeFromCart(p.name),
                                    child: Container(
                                      width: 26, height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: const Icon(Icons.remove, size: 14, color: Colors.black87),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  ),
                                  GestureDetector(
                                    onTap: () => _addToCart(p.name, p.price),
                                    child: Container(
                                      width: 26, height: 26,
                                      decoration: BoxDecoration(
                                        color: AppColors.tileGroceries,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ]),
                            ]),
                          ],
                        ),
                      );
                    },
                    childCount: cat.products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) {
        int total = 0;
        for (final cat in _categories) {
          for (final p in cat.products) {
            total += ((_cart[p.name] ?? 0) * p.price);
          }
        }
        return Container(
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
                    gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Your Basket', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: AppSpacing.lg),
              ..._cart.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('×${e.value}', style: TextStyle(color: Colors.grey.shade600)),
                ]),
              )),
              const Divider(height: 24),
              Row(children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('₹$total', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.tileGroceries)),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PremiumGradientButton(
                  label: 'Place Order',
                  colors: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/payment', arguments: {
                      'bookingId': 'grocery-order',
                      'amount': total.toDouble(),
                      'professionalName': 'Grocery Order',
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroceryCategory {
  final String name;
  final String emoji;
  final List<_Product> products;
  const _GroceryCategory(this.name, this.emoji, this.products);
}

class _Product {
  final String name;
  final String emoji;
  final int price;
  final String unit;
  const _Product(this.name, this.emoji, this.price, this.unit);
}
