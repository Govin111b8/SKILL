import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

/// Earnings dashboard screen for professionals.
/// Shows total earnings, weekly/monthly breakdown, booking stats,
/// and payout history.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          child: _loading
              ? const PremiumLoadingList(itemCount: 5, itemHeight: 130)
              : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: _buildContent(),
                    ),
        ),
      ),
    );
  }

  Widget _buildError() => PremiumEmptyState(
    icon: Icons.error_outline_rounded,
    title: 'Unable to load earnings',
    subtitle: _error ?? 'Something went wrong while fetching your dashboard.',
    actionLabel: 'Retry',
    onAction: _load,
    gradient: AppColors.warmGradient,
  );

  Widget _buildContent() {
    final monthlyEarnings = (_data?['monthlyEarnings'] as List?) ?? [];
    final weeklyBookings = (_data?['weeklyBookings'] as List?) ?? [];
    final recentActivity = _data?['recentActivity'] as Map<String, dynamic>? ?? {};

    double totalEarnings = 0;
    int totalBookings = 0;
    for (final m in monthlyEarnings) {
      totalEarnings += (m['earnings'] as num?)?.toDouble() ?? 0;
      totalBookings += (m['bookings_completed'] as num?)?.toInt() ?? 0;
    }

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final avgRating = (recentActivity['avgRating'] as num?)?.toDouble() ?? 4.8;
    final repeatCustomers = (recentActivity['repeatCustomers'] as num?)?.toInt() ?? 0;
    final activeDays = weeklyBookings.where((day) {
      final count = ((day['count'] ?? day['bookings'] ?? day['bookings_completed'] ?? 0) as num).toInt();
      return count > 0;
    }).length;
    final bestMonth = monthlyEarnings.isEmpty
        ? null
        : monthlyEarnings.reduce((a, b) {
            final aValue = (a['earnings'] as num?)?.toDouble() ?? 0;
            final bValue = (b['earnings'] as num?)?.toDouble() ?? 0;
            return aValue >= bValue ? a : b;
          });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        PremiumGlassCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          gradient: const [Color(0xEE4338CA), Color(0xEE6366F1), Color(0xEE8B5CF6)],
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(24),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Colors.white.withAlpha(50)),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  PremiumStatChip(
                    label: activeDays > 0 ? '$activeDays active days' : 'Fresh start',
                    icon: Icons.auto_graph_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalEarnings),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text(
                  currencyFmt.format(val),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  const PremiumStatChip(
                    label: '+12% this month',
                    icon: Icons.trending_up_rounded,
                    color: Color(0xFFD1FAE5),
                  ),
                  PremiumStatChip(
                    label: '${currencyFmt.format(totalBookings == 0 ? 0 : totalEarnings / totalBookings)} avg / job',
                    icon: Icons.payments_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(16),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready for payout',
                            style: TextStyle(
                              color: Colors.white.withAlpha(220),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            currencyFmt.format(totalEarnings * 0.9),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => HapticFeedback.mediumImpact(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.md(Colors.black26),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_rounded, color: AppColors.primaryDark, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Withdraw',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.18,
          children: [
            PremiumMetricCard(
              label: 'Completed Jobs',
              value: '$totalBookings',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            PremiumMetricCard(
              label: 'Average Rating',
              value: avgRating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              color: AppColors.warning,
            ),
            PremiumMetricCard(
              label: 'Repeat Clients',
              value: '$repeatCustomers',
              icon: Icons.groups_rounded,
              color: AppColors.primary,
            ),
            PremiumMetricCard(
              label: 'Peak Window',
              value: activeDays > 0 ? '10–12 AM' : '—',
              icon: Icons.bolt_rounded,
              color: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        PremiumGlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            indicator: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.sm(AppColors.primary),
            ),
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Week'),
              Tab(text: 'Month'),
              Tab(text: 'Year'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionTitle(
          title: 'Insights',
          subtitle: 'Track revenue, momentum and consistency.',
          trailing: bestMonth == null
              ? null
              : PremiumStatusPill(
                  label: 'Best: ${bestMonth['month']}',
                  color: AppColors.success,
                ),
        ),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earnings Overview',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Monthly revenue performance at a glance',
                          style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 220,
                child: monthlyEarnings.isEmpty
                    ? const Center(
                        child: Text(
                          'No earnings data yet',
                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      )
                    : _EarningsBarChart(monthlyEarnings: monthlyEarnings),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionTitle(
          title: 'Monthly Breakdown',
          subtitle: 'See which periods delivered your strongest income.',
        ),
        if (monthlyEarnings.isEmpty)
          const PremiumEmptyState(
            icon: Icons.payments_outlined,
            title: 'No payouts yet',
            subtitle: 'Complete your first few bookings to unlock a detailed earnings timeline.',
          )
        else
          ...monthlyEarnings.take(6).map((m) {
            final earnings = (m['earnings'] as num?)?.toDouble() ?? 0;
            final bookings = (m['bookings_completed'] as num?)?.toInt() ?? 0;
            final month = m['month']?.toString() ?? '';
            final maxEarnings = monthlyEarnings.fold<double>(1, (prev, e) {
              final value = (e['earnings'] as num?)?.toDouble() ?? 0;
              return value > prev ? value : prev;
            });
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PremiumGlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                month,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '$bookings jobs completed',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            currencyFmt.format(earnings),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: maxEarnings > 0 ? earnings / maxEarnings : 0,
                        minHeight: 8,
                        backgroundColor: AppColors.primary.withAlpha(18),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _EarningsBarChart extends StatelessWidget {
  final List monthlyEarnings;
  const _EarningsBarChart({required this.monthlyEarnings});

  @override
  Widget build(BuildContext context) {
    if (monthlyEarnings.isEmpty) {
      return const Center(
        child: Text('No data yet', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    final data = monthlyEarnings.take(7).toList();
    final maxY = data.fold<double>(1, (p, e) {
      final v = (e['earnings'] as num?)?.toDouble() ?? 0;
      return v > p ? v : p;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF4338CA),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final m = data[group.x.toInt()];
              final month = m['month']?.toString() ?? '';
              return BarTooltipItem(
                '$month
₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= data.length) return const SizedBox.shrink();
                final month = (data[i]['month']?.toString() ?? '').take(3).join();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    month,
                    style: const TextStyle(color: Color(0xFF7C83A3), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 4,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: const Color(0xFFE5E7F4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          final earnings = (data[i]['earnings'] as num?)?.toDouble() ?? 0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: earnings,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: AppColors.primaryGradient,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

extension on String {
  Iterable<String> take(int n) => split('').take(n);
}
