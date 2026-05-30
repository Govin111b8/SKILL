import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';

/// MyRide screen — cab / auto / bike ride booking.
class MyRideScreen extends StatefulWidget {
  const MyRideScreen({super.key});

  @override
  State<MyRideScreen> createState() => _MyRideScreenState();
}

class _MyRideScreenState extends State<MyRideScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  int _rideTypeIndex = 0; // 0=Auto, 1=Cab, 2=Bike
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  bool _searched = false;

  static const _rideTypes = [
    _RideType('Auto', '🛺', 49),
    _RideType('Cab', '🚕', 99),
    _RideType('Bike', '🏍️', 29),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
        '/search',
        queryParams: {'category': 'Transport', 'limit': '8', 'sort_by': 'rating'},
      );
      final list = res['data'] as List? ?? [];
      _drivers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _drivers = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _search() {
    if (_fromCtrl.text.isEmpty || _toCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter both pickup and destination'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _searched = true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = _rideTypes[_rideTypeIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Hero Header
              SliverToBoxAdapter(
                child: PremiumHeroHeader(
                  title: 'MyRide',
                  subtitle: 'Book autos, cabs & bikes instantly',
                  icon: Icons.directions_car_rounded,
                  gradient: const [Color(0xFF0288D1), Color(0xFF0077B6)],
                  chips: const [
                    PremiumStatChip(label: '🛺 Auto', color: Colors.white),
                    PremiumStatChip(label: '🚕 Cab', color: Colors.white),
                    PremiumStatChip(label: '🏍️ Bike', color: Colors.white),
                  ],
                ),
              ),

              // Ride type selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: List.generate(_rideTypes.length, (i) {
                      final rt = _rideTypes[i];
                      final selected = i == _rideTypeIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rideTypeIndex = i);
                          },
                          child: AnimatedContainer(
                            duration: AppDurations.normal,
                            margin: EdgeInsets.only(right: i < _rideTypes.length - 1 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF0077B6)])
                                  : null,
                              color: selected ? null : Colors.white.withAlpha(180),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: selected ? Colors.transparent : AppColors.borderLight,
                                width: selected ? 0 : 1,
                              ),
                              boxShadow: selected ? AppShadows.md(AppColors.tileRide) : null,
                            ),
                            child: Column(children: [
                              Text(rt.emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(
                                rt.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : AppColors.surfaceDark,
                                ),
                              ),
                              Text(
                                '₹${rt.baseFare}+',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected ? Colors.white.withAlpha(200) : Colors.grey.shade500,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Address card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: PremiumGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(children: [
                      _AddrField(controller: _fromCtrl, label: 'Pickup location', icon: Icons.radio_button_checked, color: AppColors.success),
                      Divider(height: 20, color: AppColors.borderLight.withAlpha(180)),
                      _AddrField(controller: _toCtrl, label: 'Destination', icon: Icons.location_on_rounded, color: AppColors.error),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: PremiumGradientButton(
                          label: 'Find ${selectedType.name}',
                          icon: Icons.search_rounded,
                          colors: const [Color(0xFF0288D1), Color(0xFF0077B6)],
                          onPressed: _search,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              // Driver list
              if (_searched) ...[
                SliverToBoxAdapter(
                  child: PremiumSectionTitle(
                    title: 'Nearby ${selectedType.name}s',
                    subtitle: 'Select a driver to request your ride',
                  ),
                ),
                if (_loading)
                  SliverToBoxAdapter(child: PremiumLoadingList(itemCount: 3))
                else if (_drivers.isEmpty)
                  SliverToBoxAdapter(
                    child: PremiumEmptyState(
                      icon: Icons.directions_car_outlined,
                      title: 'No ${selectedType.name.toLowerCase()}s available',
                      subtitle: 'Try a different vehicle type or location.',
                      gradient: const [Color(0xFF0288D1), Color(0xFF0077B6)],
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final d = _drivers[i];
                        final name = d['name']?.toString() ?? 'Driver';
                        final rating = (d['avg_rating'] as num?)?.toDouble() ?? 4.5;
                        final price = selectedType.baseFare + (i * 12);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                          child: PremiumGlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF0288D1), Color(0xFF0077B6)]),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Center(child: Text(selectedType.emoji, style: const TextStyle(fontSize: 24))),
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
                                    Text('· ~${8 + i * 3} min', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  ]),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                const SizedBox(height: 6),
                                PremiumGradientButton(
                                  label: 'Request',
                                  colors: const [Color(0xFF0288D1), Color(0xFF0077B6)],
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.pushNamed(context, '/search', arguments: {
                                      'categoryId': 0, 'categoryName': 'Transport',
                                    });
                                  },
                                ),
                              ]),
                            ]),
                          ),
                        );
                      },
                      childCount: _drivers.length,
                    ),
                  ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideType {
  final String name;
  final String emoji;
  final int baseFare;
  const _RideType(this.name, this.emoji, this.baseFare);
}

class _AddrField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;

  const _AddrField({required this.controller, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
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
