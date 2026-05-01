import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

/// Earnings dashboard screen for professionals.
/// Shows total earnings, weekly/monthly breakdown, booking stats,
/// and payout history.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.get('/analytics', auth: true);
      _data = result['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(onRefresh: _load, child: _buildContent(cs)),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    final monthlyEarnings = (_data?['monthlyEarnings'] as List?) ?? [];
    final weeklyBookings = (_data?['weeklyBookings'] as List?) ?? [];
    final recentActivity = _data?['recentActivity'] as Map<String, dynamic>? ?? {};
    final ratingDist = (_data?['ratingDistribution'] as List?) ?? [];

    double totalEarnings = 0;
    int totalBookings = 0;
    for (final m in monthlyEarnings) {
      totalEarnings += (m['earnings'] as num?)?.toDouble() ?? 0;
      totalBookings += (m['bookings_completed'] as num?)?.toInt() ?? 0;
    }

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(children: [
          Expanded(child: _SummaryCard(
            icon: Icons.account_balance_wallet, label: 'Total Earned',
            value: currencyFmt.format(totalEarnings), color: Colors.green,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            icon: Icons.check_circle, label: 'Jobs Done',
            value: '$totalBookings', color: cs.primary,
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SummaryCard(
            icon: Icons.trending_up, label: '7-day Bookings',
            value: '${recentActivity['bookings_7d'] ?? 0}', color: Colors.orange,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            icon: Icons.calendar_month, label: '30-day Done',
            value: '${recentActivity['completed_30d'] ?? 0}', color: Colors.teal,
          )),
        ]),
        const SizedBox(height: 24),

        // Monthly Earnings
        Text('Monthly Earnings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (monthlyEarnings.isEmpty)
          _EmptyState(message: 'No earnings data yet')
        else
          ...monthlyEarnings.reversed.take(6).map((m) {
            final earnings = (m['earnings'] as num?)?.toDouble() ?? 0;
            final month = m['month']?.toString().substring(0, 7) ?? '';
            final maxEarning = monthlyEarnings.fold<double>(1, (prev, e) {
              final v = (e['earnings'] as num?)?.toDouble() ?? 0;
              return v > prev ? v : prev;
            });
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 60, child: Text(month, style: Theme.of(context).textTheme.bodySmall)),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: earnings / maxEarning,
                    minHeight: 20,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: Text(currencyFmt.format(earnings),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
              ]),
            );
          }),

        const SizedBox(height: 24),

        // Weekly Activity
        Text('Weekly Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (weeklyBookings.isEmpty)
          _EmptyState(message: 'No booking data yet')
        else
          ...weeklyBookings.reversed.take(4).map((w) {
            final week = w['week']?.toString().substring(0, 10) ?? '';
            final total = (w['total'] as num?)?.toInt() ?? 0;
            final completed = (w['completed'] as num?)?.toInt() ?? 0;
            final cancelled = (w['cancelled'] as num?)?.toInt() ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Week of $week'),
                subtitle: Text('Total: $total • Done: $completed • Cancelled: $cancelled'),
                trailing: total > 0 ? SizedBox(
                  width: 36, height: 36,
                  child: CircularProgressIndicator(
                    value: completed / total, strokeWidth: 3,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ) : null,
              ),
            );
          }),

        const SizedBox(height: 24),

        // Rating Distribution
        if (ratingDist.isNotEmpty) ...[
          Text('Rating Distribution', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(5, (i) {
            final star = 5 - i;
            final entry = ratingDist.firstWhere((r) => r['rating'] == star, orElse: () => {'count': 0});
            final count = (entry['count'] as num?)?.toInt() ?? 0;
            final totalR = ratingDist.fold<int>(0, (p, e) => p + ((e['count'] as num?)?.toInt() ?? 0));
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                SizedBox(width: 20, child: Text('$star', style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: totalR > 0 ? count / totalR : 0,
                    minHeight: 12, backgroundColor: cs.surfaceContainerHighest, color: Colors.amber,
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 30, child: Text('$count', textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall)),
              ]),
            );
          }),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    ));
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
    );
  }
}
