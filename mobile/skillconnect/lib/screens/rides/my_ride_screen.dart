import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedType = _rideTypes[_rideTypeIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.tileRide,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('MyRide', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0288D1), Color(0xFF0077B6)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text('🚕', style: TextStyle(fontSize: 72)),
                  ),
                ),
              ),
            ),
          ),

          // Ride type selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.tileRide : (isDark ? AppColors.cardDark : Colors.white),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: selected ? AppColors.tileRide : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: selected ? 2 : 1,
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
                              color: selected ? Colors.white : null,
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
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(children: [
                    _AddrField(controller: _fromCtrl, label: 'Pickup location', icon: Icons.radio_button_checked, color: AppColors.success),
                    Divider(height: 20, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    _AddrField(controller: _toCtrl, label: 'Destination', icon: Icons.location_on_rounded, color: AppColors.error),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _search,
                        icon: const Icon(Icons.search_rounded),
                        label: Text('Find ${selectedType.name}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tileRide,
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

          // Driver list
          if (_searched) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Text(
                  'Nearby ${selectedType.name}s',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: SkeletonProfessionalCard()),
                  childCount: 3,
                ),
              )
            else if (_drivers.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Text(selectedType.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No ${selectedType.name.toLowerCase()}s available', style: Theme.of(context).textTheme.bodyMedium),
                  ]),
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
                            decoration: BoxDecoration(color: AppColors.tileRide.withAlpha(30), shape: BoxShape.circle),
                            child: Center(child: Text(selectedType.emoji, style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
                            Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pushNamed(context, '/search', arguments: {
                                  'categoryId': 0, 'categoryName': 'Transport',
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.tileRide,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                elevation: 0,
                              ),
                              child: const Text('Request', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
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
