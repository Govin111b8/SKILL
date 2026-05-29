import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class ProviderAnalyticsScreen extends StatefulWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  State<ProviderAnalyticsScreen> createState() => _ProviderAnalyticsScreenState();
}

class _ProviderAnalyticsScreenState extends State<ProviderAnalyticsScreen> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;
  String? _error;
  String _period = 'week';

  // Demo analytics data
  static const _demoAnalytics = {
    'total_bookings': 42,
    'completion_rate': 94,
    'avg_rating': 4.8,
    'total_earned': 38500,
    'customer_return_rate': 61,
    'daily_bookings': [
      {'label': 'Mon', 'count': 5},
      {'label': 'Tue', 'count': 8},
      {'label': 'Wed', 'count': 6},
      {'label': 'Thu', 'count': 9},
      {'label': 'Fri', 'count': 7},
      {'label': 'Sat', 'count': 11},
      {'label': 'Sun', 'count': 6},
    ],
    'top_categories': [
      {'name': 'AC Service', 'share': 52},
      {'name': 'Deep Cleaning', 'share': 28},
      {'name': 'Appliance Repair', 'share': 20},
    ],
    'demand_heatmap': [
      // day 0=Mon..6=Sun, hour 8..20
      {'day': 0, 'hour': 9, 'score': 7},
      {'day': 0, 'hour': 10, 'score': 8},
      {'day': 0, 'hour': 11, 'score': 5},
      {'day': 0, 'hour': 14, 'score': 6},
      {'day': 1, 'hour': 9, 'score': 9},
      {'day': 1, 'hour': 10, 'score': 10},
      {'day': 1, 'hour': 11, 'score': 8},
      {'day': 1, 'hour': 16, 'score': 7},
      {'day': 2, 'hour': 10, 'score': 6},
      {'day': 2, 'hour': 11, 'score': 9},
      {'day': 2, 'hour': 15, 'score': 5},
      {'day': 3, 'hour': 9, 'score': 8},
      {'day': 3, 'hour': 10, 'score': 10},
      {'day': 3, 'hour': 11, 'score': 9},
      {'day': 4, 'hour': 9, 'score': 7},
      {'day': 4, 'hour': 10, 'score': 9},
      {'day': 4, 'hour': 16, 'score': 8},
      {'day': 4, 'hour': 17, 'score': 7},
      {'day': 5, 'hour': 9, 'score': 10},
      {'day': 5, 'hour': 10, 'score': 10},
      {'day': 5, 'hour': 11, 'score': 9},
      {'day': 5, 'hour': 14, 'score': 8},
      {'day': 5, 'hour': 15, 'score': 9},
      {'day': 5, 'hour': 16, 'score': 8},
      {'day': 6, 'hour': 10, 'score': 7},
      {'day': 6, 'hour': 11, 'score': 8},
      {'day': 6, 'hour': 15, 'score': 6},
    ],
    'competitor_avg_price': 1850,
    'my_avg_price': 1700,
    'competitor_avg_rating': 4.6,
    'boost_suggestions': [
      'Enable Saturday & Sunday slots — demand is 40% higher on weekends in your area',
      'Add "Washing Machine Repair" to expand to 18% more customer searches',
      'Expand service radius to 8 km — 23 more customers would find you',
      'Respond to requests within 30 min — your current response time is 2.1 hrs',
    ],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/professionals/me/analytics', auth: true, queryParams: {'period': _period});
      _analytics = Map<String, dynamic>.from((res['data'] as Map?) ?? const {});
      if ((_analytics!['total_bookings'] ?? 0) == 0) _analytics = Map<String, dynamic>.from(_demoAnalytics);
    } catch (e) {
      _analytics = Map<String, dynamic>.from(_demoAnalytics);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics ?? Map<String, dynamic>.from(_demoAnalytics);
    final daily = (analytics['daily_bookings'] as List? ?? _demoAnalytics['daily_bookings'] as List);
    final categories = (analytics['top_categories'] as List? ?? analytics['category_breakdown'] as List? ?? _demoAnalytics['top_categories'] as List);
    final heatmap = (analytics['demand_heatmap'] as List? ?? _demoAnalytics['demand_heatmap'] as List);
    final suggestions = (analytics['boost_suggestions'] as List? ?? _demoAnalytics['boost_suggestions'] as List);

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(label: const Text('This Week'), selected: _period == 'week', onSelected: (_) { setState(() => _period = 'week'); _load(); }),
                      ChoiceChip(label: const Text('This Month'), selected: _period == 'month', onSelected: (_) { setState(() => _period = 'month'); _load(); }),
                      ChoiceChip(label: const Text('This Quarter'), selected: _period == 'quarter', onSelected: (_) { setState(() => _period = 'quarter'); _load(); }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.18,
                    children: [
                      _MetricCard(label: 'Total bookings', value: '${analytics['total_bookings'] ?? 0}'),
                      _MetricCard(label: 'Completion rate', value: '${analytics['completion_rate'] ?? 0}%'),
                      _MetricCard(label: 'Avg rating', value: '${analytics['avg_rating'] ?? 0} ⭐'),
                      _MetricCard(label: 'Total earned', value: '₹${analytics['total_earned'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Daily bookings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                final label = index >= 0 && index < daily.length ? (daily[index] as Map)['label']?.toString() ?? '' : '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(label, style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: daily.asMap().entries.map((entry) {
                          final item = Map<String, dynamic>.from(entry.value as Map);
                          return BarChartGroupData(x: entry.key, barRods: [BarChartRodData(toY: ((item['count'] ?? 0) as num).toDouble(), color: Theme.of(context).colorScheme.primary, width: 18, borderRadius: BorderRadius.circular(6))]);
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Top service categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...categories.map((item) {
                    final row = Map<String, dynamic>.from(item as Map);
                    final share = (((row['share'] ?? row['percentage'] ?? 0) as num).toDouble() / 100).clamp(0.0, 1.0).toDouble();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(row['name']?.toString() ?? row['category']?.toString() ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text('${(share * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                        ]),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: share, minHeight: 8, borderRadius: BorderRadius.circular(999)),
                      ]),
                    );
                  }),
                  const SizedBox(height: 20),
                  // Demand heatmap section
                  _DemandHeatmap(heatmapData: heatmap),
                  const SizedBox(height: 20),
                  // Competitor benchmarking
                  _CompetitorBenchmark(analytics: analytics),
                  const SizedBox(height: 20),
                  // Boost suggestions
                  _BoostSuggestions(suggestions: suggestions),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Customer return rate', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('${analytics['customer_return_rate'] ?? 61}% of customers booked you again.'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: ((analytics['customer_return_rate'] ?? 61) as num) / 100, minHeight: 10, borderRadius: BorderRadius.circular(8)),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Demand Heatmap ──────────────────────────────────────────────────────────

class _DemandHeatmap extends StatelessWidget {
  final List heatmapData;
  const _DemandHeatmap({required this.heatmapData});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

  double _score(int day, int hour) {
    for (final item in heatmapData) {
      final m = item as Map;
      if ((m['day'] as num?)?.toInt() == day && (m['hour'] as num?)?.toInt() == hour) {
        return ((m['score'] as num?)?.toDouble() ?? 0) / 10;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Demand Heatmap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('When are customers searching for pros in your area?', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant)),
        child: Column(children: [
          // Hour labels
          Row(children: [
            const SizedBox(width: 28),
            ..._hours.map((h) => Expanded(
              child: Text('${h % 12 == 0 ? 12 : h % 12}${h < 12 ? 'a' : 'p'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8)),
            )),
          ]),
          const SizedBox(height: 4),
          ..._days.asMap().entries.map((dayEntry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                SizedBox(width: 28, child: Text(_days[dayEntry.key], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600))),
                ..._hours.map((hour) {
                  final intensity = _score(dayEntry.key, hour).clamp(0.0, 1.0);
                  return Expanded(
                    child: Container(
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: intensity > 0
                            ? cs.primary.withAlpha((intensity * 220).round())
                            : cs.surfaceContainerHighest,
                      ),
                    ),
                  );
                }),
              ]),
            );
          }),
          const SizedBox(height: 8),
          // Legend
          Row(children: [
            const SizedBox(width: 28),
            const Text('Low', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(colors: [cs.surfaceContainerHighest, cs.primary]),
                ),
              );
            })),
            const SizedBox(width: 4),
            const Text('High', style: TextStyle(fontSize: 10)),
          ]),
        ]),
      ),
    ]);
  }
}

// ── Competitor Benchmarking ─────────────────────────────────────────────────

class _CompetitorBenchmark extends StatelessWidget {
  final Map<String, dynamic> analytics;
  const _CompetitorBenchmark({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final myPrice = (analytics['my_avg_price'] as num?)?.toInt() ?? 1700;
    final compPrice = (analytics['competitor_avg_price'] as num?)?.toInt() ?? 1850;
    final myRating = (analytics['avg_rating'] as num?)?.toDouble() ?? 4.8;
    final compRating = (analytics['competitor_avg_rating'] as num?)?.toDouble() ?? 4.6;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('vs. Competitors in Your Area', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant)),
        child: Column(children: [
          _BenchmarkRow(label: 'Avg price', myValue: '₹$myPrice', compValue: '₹$compPrice', myBetter: myPrice < compPrice),
          const Divider(height: 20),
          _BenchmarkRow(label: 'Avg rating', myValue: '$myRating ⭐', compValue: '$compRating ⭐', myBetter: myRating > compRating),
        ]),
      ),
    ]);
  }
}

class _BenchmarkRow extends StatelessWidget {
  final String label;
  final String myValue;
  final String compValue;
  final bool myBetter;
  const _BenchmarkRow({required this.label, required this.myValue, required this.compValue, required this.myBetter});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: Column(children: [
        Text(myValue, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: myBetter ? const Color(0xFF22C55E) : Colors.orange.shade700)),
        const Text('You', style: TextStyle(fontSize: 11)),
      ]),
    ),
    Expanded(child: Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)),
    Expanded(child: Column(children: [
      Text(compValue, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const Text('Avg competitor', style: TextStyle(fontSize: 11)),
    ])),
  ]);
}

// ── Boost Suggestions ───────────────────────────────────────────────────────

class _BoostSuggestions extends StatelessWidget {
  final List suggestions;
  const _BoostSuggestions({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.rocket_launch_outlined, size: 18, color: Color(0xFFF59E0B)),
        const SizedBox(width: 6),
        Text('Boost Your Earnings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 12),
      ...suggestions.asMap().entries.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22, height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
            child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
          ),
          Expanded(child: Text(e.value.toString(), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
        ]),
      )),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

