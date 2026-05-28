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
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics ?? const <String, dynamic>{};
    final daily = (analytics['daily_bookings'] as List? ?? const []);
    final categories = (analytics['top_categories'] as List? ?? analytics['category_breakdown'] as List? ?? const []);
    final peakHours = (analytics['peak_hours'] as List? ?? const []);
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(icon: Icons.analytics_outlined, iconColor: Colors.red, title: 'Could not load analytics', subtitle: _error!, actionLabel: 'Retry', onAction: _load),
                  ])
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
                          _MetricCard(label: 'Avg rating', value: '${analytics['avg_rating'] ?? 0}'),
                          _MetricCard(label: 'Total earned', value: '₹${analytics['total_earned'] ?? 0}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Daily bookings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Container(
                        height: 260,
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
                            Text(row['name']?.toString() ?? row['category']?.toString() ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: share, minHeight: 8, borderRadius: BorderRadius.circular(999)),
                          ]),
                        );
                      }),
                      const SizedBox(height: 20),
                      Text('Peak hours heatmap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: peakHours.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.4),
                        itemBuilder: (context, index) {
                          final item = Map<String, dynamic>.from(peakHours[index] as Map);
                          final intensity = (((item['score'] ?? item['bookings'] ?? 0) as num).toDouble() / 10).clamp(0.1, 1.0).toDouble();
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: intensity),
                            ),
                            child: Center(child: Text(item['hour']?.toString() ?? '${index + 8}:00', style: TextStyle(color: intensity > .55 ? Colors.white : Colors.black87, fontWeight: FontWeight.w700))),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Customer return rate', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('${analytics['customer_return_rate'] ?? 0}% of customers booked you again.'),
                        ]),
                      ),
                    ],
                  ),
      ),
    );
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
        Text(label),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
