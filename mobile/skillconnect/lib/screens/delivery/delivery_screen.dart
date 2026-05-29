import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

/// Delivery screen — find delivery / courier professionals,
/// enter pick-up & drop-off addresses, get an estimate, and book.
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  List<Map<String, dynamic>> _providers = [];
  bool _loading = true;
  bool _estimated = false;
  double? _estimatedPrice;
  int? _estimatedMinutes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
        '/search',
        queryParams: {'category': 'Delivery', 'limit': '10', 'sort_by': 'rating'},
      );
      final list = res['data'] as List? ?? [];
      _providers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _providers = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _estimate() {
    if (_pickupCtrl.text.isEmpty || _dropCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter both pickup and drop locations'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _estimated = true;
      _estimatedPrice = 89 + (_providers.length * 3.5);
      _estimatedMinutes = 25 + (_providers.isEmpty ? 10 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.tileDelivery,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFA000), Color(0xFFFF6F00)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text('🚚', style: TextStyle(fontSize: 72)),
                  ),
                ),
              ),
            ),
          ),

          // Address inputs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(children: [
                    _AddressField(
                      controller: _pickupCtrl,
                      label: 'Pick-up location',
                      icon: Icons.my_location_rounded,
                      iconColor: AppColors.success,
                    ),
                    Divider(height: 24, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    _AddressField(
                      controller: _dropCtrl,
                      label: 'Drop location',
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _estimate,
                        icon: const Icon(Icons.calculate_rounded),
                        label: const Text('Get Estimate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tileDelivery,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // Estimate card
          if (_estimated)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFA000), Color(0xFFFF6F00)]),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Estimated Fare', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('₹${_estimatedPrice?.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('ETA', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('~$_estimatedMinutes min',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                ),
              ),
            ),

          // Available couriers
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
              child: Text(
                'Available Couriers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: SkeletonProfessionalCard()),
                childCount: 4,
              ),
            )
          else if (_providers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  const Text('🚴', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No couriers available right now', style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ProviderTile(provider: _providers[i], onBook: () {
                  Navigator.pushNamed(context, '/search', arguments: {
                    'categoryId': 0, 'categoryName': 'Delivery',
                  });
                }),
                childCount: _providers.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      bottomNavigationBar: _estimated
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pushNamed(context, '/search', arguments: {
                      'categoryId': 0, 'categoryName': 'Delivery',
                    });
                  },
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Book Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tileDelivery,
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
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _AddressField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ]);
  }
}

class _ProviderTile extends StatelessWidget {
  final Map<String, dynamic> provider;
  final VoidCallback onBook;

  const _ProviderTile({required this.provider, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final name = provider['name']?.toString() ?? 'Courier';
    final rating = (provider['avg_rating'] as num?)?.toDouble() ?? 4.5;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: AppShadows.sm(Colors.black),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.tileDelivery.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🚚', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA000)),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('· ~20 min', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ]),
          ),
          ElevatedButton(
            onPressed: onBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tileDelivery,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              elevation: 0,
            ),
            child: const Text('Book', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
