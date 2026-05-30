import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';

class ProviderAnalyticsScreen extends StatefulWidget {
  const ProviderAnalyticsScreen({super.key});
  @override
  State<ProviderAnalyticsScreen> createState() => _ProviderAnalyticsScreenState();
}

class _ProviderAnalyticsScreenState extends State<ProviderAnalyticsScreen> {
  String _period = 'week';
  Map<String, dynamic> _data = _demoAnalytics;
  bool _loading = true;

  static const _demoAnalytics = {
    'bookings': 24, 'completion_rate': 91.7, 'avg_rating': 4.8, 'revenue': 18400,
    'bar_data': [3.0, 5.0, 2.0, 7.0, 4.0, 6.0, 8.0],
    'categories': [
      {'name': 'Plumbing', 'percent': 45},
      {'name': 'Electrical', 'percent': 30},
      {'name': 'Carpentry', 'percent': 25},
    ],
    'demand_slots': [3, 7, 9, 8, 6, 4, 2, 1, 3, 5, 7, 9, 8, 6, 4, 2],
    'competitors': [
      {'name': 'You', 'rating': 4.8, 'bookings': 24, 'response': '18m'},
      {'name': 'Area Avg', 'rating': 4.3, 'bookings': 15, 'response': '42m'},
      {'name': 'Top Pro', 'rating': 4.9, 'bookings': 38, 'response': '8m'},
    ],
    'boosts': [
      'Add portfolio photos to increase views by 60%',
      'Enable quick responses to rank higher in search',
      'Ask satisfied customers to leave a review',
    ],
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/analytics/professional?period=$_period', auth: true);
      if (mounted && res is Map<String, dynamic>) setState(() => _data = res);
    } catch (_) {
      if (mounted) setState(() => _data = _demoAnalytics);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final barData = (_data['bar_data'] as List?)?.map((v) => (v as num).toDouble()).toList() ?? [];
    final categories = (_data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final boosts = (_data['boosts'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: _loading
            ? PremiumLoadingList(itemCount: 5)
            : SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: PremiumHeroHeader(
                        title: 'Analytics',
                        subtitle: 'Your business performance at a glance',
                        icon: Icons.bar_chart_rounded,
                        gradient: AppColors.primaryGradient,
                        chips: [
                          PremiumStatChip(label: '📦 ${_data['bookings'] ?? 0} Bookings', color: Colors.white),
                          PremiumStatChip(label: '✅ ${_data['completion_rate'] ?? 0}% Done', color: Colors.white),
                        ],
                      ),
                    ),

                    // Period selector
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: PremiumGlassCard(
                          padding: const EdgeInsets.all(6),
                          child: Row(children: [
                            for (final p in ['week', 'month', 'year'])
                              Expanded(child: GestureDetector(
                                onTap: () { HapticFeedback.selectionClick(); setState(() => _period = p); _load(); },
                                child: AnimatedContainer(
                                  duration: AppDurations.normal,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: _period == p ? const LinearGradient(colors: [Color(0xFF6C47FF), Color(0xFF4A28D4)]) : null,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Text(p[0].toUpperCase() + p.substring(1), textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _period == p ? Colors.white : Colors.grey)),
                                ),
                              )),
                          ]),
                        ),
                      ),
                    ),

                    // Metrics
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverGrid(
                        delegate: SliverChildListDelegate([
                          PremiumMetricCard(icon: Icons.calendar_today_rounded, label: 'Bookings', value: '${_data['bookings'] ?? 0}', color: AppColors.primaryLight),
                          PremiumMetricCard(icon: Icons.check_circle_rounded, label: 'Completion', value: '${_data['completion_rate'] ?? 0}%', color: AppColors.success),
                          PremiumMetricCard(icon: Icons.star_rounded, label: 'Avg Rating', value: '${_data['avg_rating'] ?? 0}', color: AppColors.warning),
                          PremiumMetricCard(icon: Icons.currency_rupee_rounded, label: 'Revenue', value: '₹${_data['revenue'] ?? 0}', color: AppColors.tileJob),
                        ]),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.4, mainAxisSpacing: 10, crossAxisSpacing: 10),
                      ),
                    ),

                    // Bar chart
                    if (barData.isNotEmpty) ...[
                      SliverToBoxAdapter(child: PremiumSectionTitle(title: 'Bookings Trend', subtitle: 'Daily breakdown for this $_period')),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: PremiumGlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: SizedBox(
                              height: 180,
                              child: BarChart(BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: barData.reduce((a, b) => a > b ? a : b) + 2,
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                                    const days = ['M','T','W','T','F','S','S'];
                                    final i = v.toInt();
                                    return i < days.length ? Text(days[i], style: const TextStyle(fontSize: 10)) : const SizedBox.shrink();
                                  })),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: barData.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
                                  BarChartRodData(toY: e.value, width: 16,
                                    gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF4A28D4), Color(0xFF6C47FF)])),
                                ])).toList(),
                              )),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Category breakdown
                    if (categories.isNotEmpty) ...[
                      SliverToBoxAdapter(child: PremiumSectionTitle(title: 'Service Breakdown')),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                          final cat = categories[i];
                          final pct = (cat['percent'] as num).toInt();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PremiumGlassCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text(cat['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryLight)),
                                ]),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    minHeight: 8,
                                    backgroundColor: AppColors.borderLight,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        }, childCount: categories.length)),
                      ),
                    ],

                    SliverToBoxAdapter(child: _DemandHeatmap(data: _data)),
                    SliverToBoxAdapter(child: _CompetitorBenchmark(data: _data)),
                    SliverToBoxAdapter(child: _BoostSuggestions(boosts: boosts)),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DemandHeatmap extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DemandHeatmap({required this.data});
  @override
  Widget build(BuildContext context) {
    final slots = (data['demand_slots'] as List?)?.cast<int>() ?? [];
    final hours = ['6am','8am','10am','12pm','2pm','4pm','6pm','8pm','10pm','11pm','12am','1am','2am','3am','4am','5am'];
    final maxV = slots.isEmpty ? 1 : slots.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PremiumSectionTitle(title: 'Demand Heatmap', subtitle: 'Best hours to be online'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(slots.length, (i) {
              final intensity = maxV > 0 ? slots[i] / maxV : 0.0;
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Color.lerp(AppColors.borderLight, AppColors.primaryLight, intensity),
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                const SizedBox(height: 2),
                Text(i < hours.length ? hours[i] : '', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ]);
            }),
          ),
        ]),
      ),
    );
  }
}

class _CompetitorBenchmark extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CompetitorBenchmark({required this.data});
  @override
  Widget build(BuildContext context) {
    final competitors = (data['competitors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PremiumSectionTitle(title: 'Competitor Benchmark'),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
            children: [
              TableRow(children: [
                for (final h in ['Name', 'Rating', 'Jobs', 'Resp.'])
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(h, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
              ]),
              ...competitors.map((c) => TableRow(children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(c['name'] as String, style: TextStyle(fontWeight: c['name'] == 'You' ? FontWeight.w800 : FontWeight.w500, color: c['name'] == 'You' ? AppColors.primaryLight : null))),
                Text('⭐${c['rating']}', style: const TextStyle(fontSize: 13)),
                Text('${c['bookings']}', style: const TextStyle(fontSize: 13)),
                Text('${c['response']}', style: const TextStyle(fontSize: 13)),
              ])),
            ],
          ),
        ]),
      ),
    );
  }
}

class _BoostSuggestions extends StatelessWidget {
  final List<String> boosts;
  const _BoostSuggestions({required this.boosts});
  @override
  Widget build(BuildContext context) {
    if (boosts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: PremiumGlassCard(
        gradient: [AppColors.primaryLight.withAlpha(20), AppColors.primaryLight.withAlpha(10)],
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PremiumSectionTitle(title: '🚀 Growth Tips', subtitle: 'AI-powered suggestions to grow faster'),
          const SizedBox(height: 8),
          ...boosts.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 24, height: 24, margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C47FF), Color(0xFF4A28D4)]), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
              Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.4))),
            ]),
          )),
        ]),
      ),
    );
  }
}
