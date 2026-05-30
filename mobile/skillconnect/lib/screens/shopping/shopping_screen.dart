import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});
  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _taskCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _selectedStore = 'Any Store';
  bool _submitting = false;
  static const _stores = ['Any Store', 'Amazon', 'Flipkart', 'Myntra', 'Local Market', 'Mall'];
  static const _deals = [
    _Deal('Running Shoes', '👟', 1299, 2499, 'Amazon'),
    _Deal('Bluetooth Earbuds', '🎧', 899, 1999, 'Flipkart'),
    _Deal('Cotton T-Shirt', '👕', 299, 599, 'Myntra'),
    _Deal('Backpack', '🎒', 799, 1499, 'Amazon'),
    _Deal('Sunglasses', '🕶️', 499, 999, 'Local Market'),
    _Deal('Water Bottle', '🍶', 199, 399, 'Flipkart'),
  ];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabCtrl.dispose(); _taskCtrl.dispose(); _budgetCtrl.dispose(); super.dispose(); }

  Future<void> _submitTask() async {
    if (_taskCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe what you need'), behavior: SnackBarBehavior.floating));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await ApiService.post('/quotes/request', {
        'title': 'Shopping: ${_taskCtrl.text}',
        'description': 'Store: $_selectedStore\nBudget: ${_budgetCtrl.text.isEmpty ? "Flexible" : "₹${_budgetCtrl.text}"}',
        'service_mode': 'fixed',
      }, auth: true);
      if (mounted) {
        _taskCtrl.clear(); _budgetCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Task posted! Runners will respond shortly.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: PremiumHeroHeader(
                title: 'Shopping',
                subtitle: 'Personal runners who shop for you',
                icon: Icons.shopping_bag_rounded,
                gradient: const [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                chips: const [PremiumStatChip(label: '🛍️ Buy For Me', color: Colors.white), PremiumStatChip(label: '🔥 Hot Deals', color: Colors.white)],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabDelegate(TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.tileShopping,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.tileShopping,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                tabs: const [Tab(text: 'Buy For Me'), Tab(text: 'Deals')],
              )),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PremiumSectionTitle(title: 'Tell us what you need', subtitle: 'Our runners shop on your behalf and deliver'),
                  PremiumGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(controller: _taskCtrl, maxLines: 4,
                      decoration: InputDecoration(hintText: 'e.g. Buy a blue Nike running shoe, size 10...', hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14), border: InputBorder.none)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: DropdownButtonFormField<String>(
                      value: _selectedStore,
                      decoration: const InputDecoration(labelText: 'Preferred Store', prefixIcon: Icon(Icons.store_rounded), border: InputBorder.none),
                      items: _stores.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _selectedStore = v ?? _selectedStore),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: TextFormField(controller: _budgetCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Budget (₹)', hintText: 'Leave blank for flexible', prefixIcon: Icon(Icons.currency_rupee_rounded), border: InputBorder.none)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(width: double.infinity, child: PremiumGradientButton(
                    label: _submitting ? 'Posting...' : 'Post Task',
                    icon: _submitting ? null : Icons.send_rounded,
                    colors: const [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                    onPressed: _submitting ? () {} : _submitTask,
                  )),
                  PremiumSectionTitle(title: 'How it works'),
                  ...[
                    ('1. Describe', 'Tell us exactly what you need', Icons.edit_note_rounded),
                    ('2. Match', 'A trusted runner accepts your task', Icons.person_search_rounded),
                    ('3. Shop', 'Runner shops and keeps you updated', Icons.shopping_bag_rounded),
                    ('4. Deliver', 'Your items arrive at your door', Icons.local_shipping_rounded),
                  ].map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: PremiumGlassCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(children: [
                        Container(width: 42, height: 42,
                          decoration: BoxDecoration(color: AppColors.tileShopping.withAlpha(30), borderRadius: BorderRadius.circular(AppRadius.md)),
                          child: Icon(step.$3, color: AppColors.tileShopping, size: 20)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(step.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(step.$2, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
                        ])),
                      ]),
                    ),
                  )),
                ]),
              ),
              ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _deals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final deal = _deals[i];
                  final discount = (((deal.original - deal.price) / deal.original) * 100).round();
                  return PremiumGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(children: [
                      Container(width: 60, height: 60,
                        decoration: BoxDecoration(color: AppColors.tileShopping.withAlpha(20), borderRadius: BorderRadius.circular(AppRadius.lg)),
                        child: Center(child: Text(deal.emoji, style: const TextStyle(fontSize: 30)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(deal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(deal.store, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text('₹${deal.price}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.tileShopping)),
                          const SizedBox(width: 8),
                          Text('₹${deal.original}', style: TextStyle(fontSize: 13, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          PremiumStatusPill(label: '$discount% off', color: AppColors.success),
                        ]),
                      ])),
                      PremiumGradientButton(
                        label: 'Get',
                        colors: const [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${deal.name} to "Buy For Me" task'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
                        },
                      ),
                    ]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Colors.white.withAlpha(230), child: tabBar);
  @override bool shouldRebuild(_TabDelegate old) => false;
}

class _Deal {
  final String name; final String emoji; final int price; final int original; final String store;
  const _Deal(this.name, this.emoji, this.price, this.original, this.store);
}
