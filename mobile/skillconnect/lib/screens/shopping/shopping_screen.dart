import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';

/// Shopping screen — errand runners & retail professionals who can
/// shop on your behalf, or link to the existing marketplace.
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
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _taskCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    if (_taskCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please describe what you need'),
        behavior: SnackBarBehavior.floating,
      ));
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
        _taskCtrl.clear();
        _budgetCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Task posted! Runners will respond shortly.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.tileShopping,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
              title: const Text('Shopping', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text('🛍️', style: TextStyle(fontSize: 72)),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Buy For Me'),
                Tab(text: 'Deals'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Buy For Me tab ──────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tell us what you need',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our runners will shop on your behalf and deliver to you',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Task description
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: TextField(
                      controller: _taskCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'e.g. Buy a blue Nike running shoe, size 10, from the mall near my office...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Store selector
                  DropdownButtonFormField<String>(
                    value: _selectedStore,
                    decoration: InputDecoration(
                      labelText: 'Preferred Store',
                      prefixIcon: const Icon(Icons.store_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    items: _stores.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedStore = v ?? _selectedStore),
                  ),
                  const SizedBox(height: 16),

                  // Budget
                  TextFormField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Budget (₹)',
                      hintText: 'Leave blank for flexible',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submitTask,
                      icon: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Posting...' : 'Post Task',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tileShopping,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // How it works
                  Text('How it works', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ...[
                    ('1. Describe', 'Tell us exactly what you need and from where', Icons.edit_note_rounded),
                    ('2. Match', 'A trusted runner accepts your task', Icons.person_search_rounded),
                    ('3. Shop', 'Runner shops and keeps you updated', Icons.shopping_bag_rounded),
                    ('4. Deliver', 'Your items arrive at your door', Icons.local_shipping_rounded),
                  ].map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.tileShopping.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(step.$3, color: AppColors.tileShopping, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(step.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(step.$2, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3)),
                        ]),
                      ),
                    ]),
                  )),
                ],
              ),
            ),

            // ── Deals tab ───────────────────────────────────────
            ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _deals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final deal = _deals[i];
                final discount = (((deal.original - deal.price) / deal.original) * 100).round();
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: AppShadows.sm(Colors.black),
                  ),
                  child: Row(children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.tileShopping.withAlpha(15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(child: Text(deal.emoji, style: const TextStyle(fontSize: 30))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(deal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(deal.store, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text('₹${deal.price}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.tileShopping)),
                          const SizedBox(width: 8),
                          Text('₹${deal.original}', style: TextStyle(fontSize: 13, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.success.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text('$discount% off', style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ]),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Added ${deal.name} to "Buy For Me" task'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tileShopping,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        elevation: 0,
                      ),
                      child: const Text('Get', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Deal {
  final String name;
  final String emoji;
  final int price;
  final int original;
  final String store;
  const _Deal(this.name, this.emoji, this.price, this.original, this.store);
}
