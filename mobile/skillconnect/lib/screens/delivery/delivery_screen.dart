import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _estimated
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: PremiumGradientButton(
                    label: 'Book Delivery',
                    icon: Icons.local_shipping_rounded,
                    colors: const [Color(0xFFFFA000), Color(0xFFFF6F00)],
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pushNamed(context, '/search', arguments: {
                        'categoryId': 0, 'categoryName': 'Delivery',
                      });
                    },
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
              // Hero Header
              SliverToBoxAdapter(
                child: PremiumHeroHeader(
                  title: 'Delivery',
                  subtitle: 'Fast & reliable couriers at your doorstep',
                  icon: Icons.local_shipping_rounded,
                  gradient: const [Color(0xFFFFA000), Color(0xFFFF6F00)],
                  chips: const [
                    PremiumStatChip(label: '🚚 Express', color: Colors.white),
                    PremiumStatChip(label: '⚡ ~25 min', color: Colors.white),
                  ],
                ),
              ),

              // Address inputs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PremiumGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(children: [
                      _AddressField(
                        controller: _pickupCtrl,
                        label: 'Pick-up location',
                        icon: Icons.my_location_rounded,
                        iconColor: AppColors.success,
                      ),
                      Divider(height: 24, color: AppColors.borderLight.withAlpha(180)),
                      _AddressField(
                        controller: _dropCtrl,
                        label: 'Drop location',
                        icon: Icons.location_on_rounded,
                        iconColor: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: PremiumGradientButton(
                          label: 'Get Estimate',
                          icon: Icons.calculate_rounded,
                          colors: const [Color(0xFFFFA000), Color(0xFFFF6F00)],
                          onPressed: _estimate,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              // Estimate card
              if (_estimated)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                    child: PremiumGlassCard(
                      gradient: const [Color(0xFFFFA000), Color(0xFFFF6F00)],
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Estimated Fare', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('₹${_estimatedPrice?.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('ETA', style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('~$_estimatedMinutes min',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ]),
                      ]),
                    ),
                  ),
                ),

              // Section title
              SliverToBoxAdapter(
                child: PremiumSectionTitle(
                  title: 'Available Couriers',
                  subtitle: 'Verified delivery professionals near you',
                ),
              ),

              // Loading / empty / list
              if (_loading)
                SliverToBoxAdapter(child: PremiumLoadingList(itemCount: 4))
              else if (_providers.isEmpty)
                SliverToBoxAdapter(
                  child: PremiumEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No couriers available',
                    subtitle: 'No couriers are available right now.\nPlease try again shortly.',
                    gradient: const [Color(0xFFFFA000), Color(0xFFFF6F00)],
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
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
            ],
          ),
        ),
      ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: onBook,
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFA000), Color(0xFFFF6F00)]),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(child: Text('🚚', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA000)),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('· ~20 min', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ]),
          ),
          PremiumGradientButton(
            label: 'Book',
            colors: const [Color(0xFFFFA000), Color(0xFFFF6F00)],
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
            onPressed: onBook,
          ),
        ]),
      ),
    );
  }
}
