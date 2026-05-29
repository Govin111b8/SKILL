import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/skeleton_loader.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = _categories[_selectedCategory];

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.tileGroceries,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('Groceries', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text('🛒', style: TextStyle(fontSize: 72)),
                  ),
                ),
              ),
            ),
            actions: [
              if (_cartItemCount > 0)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_basket_rounded, color: Colors.white),
                      onPressed: () => _showCart(context),
                    ),
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$_cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Category tabs
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
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
                        color: selected ? AppColors.tileGroceries : (isDark ? AppColors.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: selected ? AppColors.tileGroceries : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: selected ? 2 : 1,
                        ),
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
                            color: selected ? Colors.white : null,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Text('${cat.emoji} ${cat.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: qty > 0 ? AppColors.tileGroceries : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 32)),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(p.unit, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Row(children: [
                          Text('₹${p.price}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const Spacer(),
                          if (qty == 0)
                            GestureDetector(
                              onTap: () => _addToCart(p.name, p.price),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.tileGroceries,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 18),
                              ),
                            )
                          else
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              GestureDetector(
                                onTap: () => _removeFromCart(p.name),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.remove, size: 14, color: Colors.black87),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              GestureDetector(
                                onTap: () => _addToCart(p.name, p.price),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(color: AppColors.tileGroceries, borderRadius: BorderRadius.circular(6)),
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
      bottomNavigationBar: _cartItemCount > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ElevatedButton.icon(
                  onPressed: () => _showCart(context),
                  icon: const Icon(Icons.shopping_basket_rounded),
                  label: Text('Checkout ($_cartItemCount items)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tileGroceries,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        // Compute total from cart quantities × prices across all categories
        int total = 0;
        for (final cat in _categories) {
          for (final p in cat.products) {
            total += ((_cart[p.name] ?? 0) * p.price);
          }
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Basket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ..._cart.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('×${e.value}'),
                  const SizedBox(width: 16),
                ]),
              )),
              const Divider(height: 24),
              Row(children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('₹$total', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.tileGroceries)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/payment', arguments: {
                      'bookingId': 'grocery-order',
                      'amount': total.toDouble(),
                      'professionalName': 'Grocery Order',
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tileGroceries,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
