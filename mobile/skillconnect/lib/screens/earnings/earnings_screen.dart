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
      padding: EdgeInsets.zero,
      children: [
        // ── Hero earnings banner ───────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF6366F1)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Earnings', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(currencyFmt.format(totalEarnings),
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 20),
            // Mini stat row
            Row(children: [
              _heroPill(Icons.check_circle_rounded, '$totalBookings Jobs', const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _heroPill(Icons.trending_up_rounded, '${recentActivity['bookings_7d'] ?? 0} this week', const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              _heroPill(Icons.calendar_today_rounded, '${recentActivity['completed_30d'] ?? 0} this month', const Color(0xFF06B6D4)),
            ]),
          ]),
        ),

        // ── KPI cards ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(children: [
            Row(children: [
              _GradientKpi('Lifetime', currencyFmt.format(totalEarnings), Icons.account_balance_wallet_rounded,
                  const [Color(0xFF10B981), Color(0xFF34D399)]),
              const SizedBox(width: 12),
              _GradientKpi('Completed', '$totalBookings', Icons.check_circle_outline_rounded,
                  const [Color(0xFF6366F1), Color(0xFF818CF8)]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _GradientKpi('7-day Jobs', '${recentActivity['bookings_7d'] ?? 0}', Icons.trending_up_rounded,
                  const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
              const SizedBox(width: 12),
              _GradientKpi('30-day Done', '${recentActivity['completed_30d'] ?? 0}', Icons.calendar_month_rounded,
                  const [Color(0xFF0288D1), Color(0xFF29B6F6)]),
            ]),

            const SizedBox(height: 28),

            // ── Monthly Earnings bar chart ────────────────────────
            _SectionTitle('Monthly Earnings', Icons.bar_chart_rounded, const Color(0xFF6366F1)),
            const SizedBox(height: 14),
            if (monthlyEarnings.isEmpty)
              _EmptyState(message: 'No earnings data yet')
            else ...[
              _MonthlyBarChart(months: monthlyEarnings.reversed.take(6).toList()),
            ],

            const SizedBox(height: 28),

            // ── Weekly activity cards ────────────────────────────
            _SectionTitle('Weekly Activity', Icons.event_note_rounded, const Color(0xFF10B981)),
            const SizedBox(height: 14),
            if (weeklyBookings.isEmpty)
              _EmptyState(message: 'No booking data yet')
            else
              ...weeklyBookings.reversed.take(4).map((w) {
                final week = w['week']?.toString().substring(0, 10) ?? '';
                final total = (w['total'] as num?)?.toInt() ?? 0;
                final completed = (w['completed'] as num?)?.toInt() ?? 0;
                final cancelled = (w['cancelled'] as num?)?.toInt() ?? 0;
                final pct = total > 0 ? completed / total : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(40)),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_view_week_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Week of $week', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('$total bookings • $completed done • $cancelled cancelled',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ])),
                      SizedBox(
                        width: 40, height: 40,
                        child: Stack(alignment: Alignment.center, children: [
                          CircularProgressIndicator(
                            value: pct, strokeWidth: 4,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF10B981),
                          ),
                          Text('${(pct * 100).toInt()}%',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct, minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ]),
                );
              }),

            const SizedBox(height: 28),

            // ── Rating distribution ──────────────────────────────
            if (ratingDist.isNotEmpty) ...[
              _SectionTitle('Rating Distribution', Icons.star_rounded, const Color(0xFFF59E0B)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(children: List.generate(5, (i) {
                  final star = 5 - i;
                  final entry = ratingDist.firstWhere((r) => r['rating'] == star, orElse: () => {'count': 0});
                  final count = (entry['count'] as num?)?.toInt() ?? 0;
                  final totalR = ratingDist.fold<int>(0, (p, e) => p + ((e['count'] as num?)?.toInt() ?? 0));
                  final pct = totalR > 0 ? count / totalR : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(width: 16, child: Text('$star', style: const TextStyle(fontWeight: FontWeight.w700))),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct, minHeight: 10,
                          backgroundColor: Colors.grey.shade100,
                          color: const Color(0xFFF59E0B),
                        ),
                      )),
                      const SizedBox(width: 10),
                      SizedBox(width: 30, child: Text('$count',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.right)),
                    ]),
                  );
                })),
              ),
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  Widget _heroPill(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

class _GradientKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  const _GradientKpi(this.label, this.value, this.icon, this.gradient);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: gradient.first.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionTitle(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
    ]);
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List months;
  const _MonthlyBarChart({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxVal = months.fold<double>(1, (prev, m) {
      final v = (m['earnings'] as num?)?.toDouble() ?? 0;
      return v > prev ? v : prev;
    });
    final fmt = NumberFormat.compact(locale: 'en_IN');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: months.map((m) {
          final earnings = (m['earnings'] as num?)?.toDouble() ?? 0;
          final month = m['month']?.toString().substring(0, 7) ?? '';
          final pct = earnings / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(width: 54, child: Text(month, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(height: 24, color: const Color(0xFF6366F1).withAlpha(15)),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 56, child: Text('₹${fmt.format(earnings)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.right)),
            ]),
          );
        }).toList(),
      ),
    );
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
