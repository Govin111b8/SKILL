import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';
import 'admin_users_screen.dart';
import 'admin_kyc_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_featured_slots_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  final _activityFeed = <Map<String, dynamic>>[];
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static const _demoStats = {
    'total_users': 14832, 'new_signups_today': 47, 'active_bookings': 218,
    'gmv_today': 184500, 'open_disputes': 12, 'pending_kyc': 34, 'revenue_today': 184500,
    'weekly_revenue': [
      {'day': 'Mon', 'amount': 98000}, {'day': 'Tue', 'amount': 124000},
      {'day': 'Wed', 'amount': 143000}, {'day': 'Thu', 'amount': 109000},
      {'day': 'Fri', 'amount': 167000}, {'day': 'Sat', 'amount': 201000},
      {'day': 'Sun', 'amount': 184500},
    ],
  };

  static final _demoActivity = [
    {'type': 'booking', 'message': 'New booking #BK4821 — AC Service in Koramangala', 'time': '2 min ago', 'icon': 'booking'},
    {'type': 'kyc', 'message': 'KYC submitted by Ramesh Kumar (Plumber, Whitefield)', 'time': '5 min ago', 'icon': 'kyc'},
    {'type': 'dispute', 'message': 'Dispute #D091 opened — Customer: Ananya Reddy', 'time': '12 min ago', 'icon': 'dispute'},
    {'type': 'signup', 'message': 'New professional signup: Suresh Nair (Electrician)', 'time': '18 min ago', 'icon': 'signup'},
    {'type': 'booking', 'message': 'Booking #BK4819 marked complete — ₹1,800 settled', 'time': '22 min ago', 'icon': 'booking'},
    {'type': 'fraud', 'message': '⚠️ Fraud alert: suspicious login attempt (IP: 103.x.x)', 'time': '35 min ago', 'icon': 'fraud'},
  ];

  @override
  void initState() {
    super.initState();
    _activityFeed.addAll(_demoActivity);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    _wsSub = RealtimeService.instance.stream.listen((ev) {
      if (!mounted) return;
      final t = ev['type']?.toString() ?? '';
      if (t.isNotEmpty) {
        setState(() {
          _activityFeed.insert(0, {'type': t, 'message': ev['message']?.toString() ?? 'Platform event: $t', 'time': 'Just now', 'icon': t});
          if (_activityFeed.length > 20) _activityFeed.removeLast();
        });
        if (t == 'booking_status' || t == 'new_dispute' || t.startsWith('admin_')) _load();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    _error = null;
    try {
      final res = await ApiService.get('/admin/stats', auth: true);
      _stats = Map<String, dynamic>.from((res['data'] as Map?) ?? const {});
    } catch (e) {
      _stats = Map<String, dynamic>.from(_demoStats);
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> get _s => _stats ?? _demoStats;

  IconData _activityIcon(String type) {
    switch (type) {
      case 'booking': return Icons.calendar_today_rounded;
      case 'kyc': return Icons.verified_user_rounded;
      case 'dispute': return Icons.gavel_rounded;
      case 'signup': return Icons.person_add_rounded;
      case 'fraud': return Icons.warning_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'booking': return AppColors.primary;
      case 'kyc': return AppColors.success;
      case 'dispute': return AppColors.error;
      case 'signup': return AppColors.accent;
      case 'fraud': return AppColors.warning;
      default: return Colors.grey;
    }
  }

  static const _quickActions = [
    (Icons.people_rounded, 'Users', [Color(0xFF6366F1), Color(0xFF4F46E5)]),
    (Icons.verified_user_rounded, 'KYC', [Color(0xFF10B981), Color(0xFF059669)]),
    (Icons.gavel_rounded, 'Disputes', [Color(0xFFEF4444), Color(0xFFDC2626)]),
    (Icons.flag_rounded, 'Complaints', [Color(0xFFF59E0B), Color(0xFFD97706)]),
    (Icons.star_rounded, 'Featured', [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
  ];

  @override
  Widget build(BuildContext context) {
    final weekly = (_s['weekly_revenue'] as List? ?? []).cast<Map>();
    final maxAmt = weekly.isEmpty ? 1.0 : weekly.map((e) => (e['amount'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b);

    return PremiumScrollScaffold(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PremiumHeroHeader(
                title: 'Admin Dashboard',
                subtitle: 'Platform overview & controls',
                icon: Icons.admin_panel_settings_rounded,
                gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                chips: [
                  PremiumStatChip(label: 'Live', color: AppColors.success, icon: Icons.circle),
                  PremiumStatChip(label: '${_s['new_signups_today'] ?? 0} today', color: Colors.white, icon: Icons.person_add_rounded),
                ],
              ),
            ),

            // Metrics grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  PremiumMetricCard(label: 'Total Users', value: NumberFormat.compact().format(_s['total_users'] ?? 0), icon: Icons.people_rounded, color: AppColors.primary),
                  PremiumMetricCard(label: 'Active Bookings', value: '${_s['active_bookings'] ?? 0}', icon: Icons.calendar_today_rounded, color: AppColors.success),
                  PremiumMetricCard(label: 'GMV Today', value: _currencyFmt.format(_s['gmv_today'] ?? 0), icon: Icons.attach_money_rounded, color: AppColors.warning),
                  PremiumMetricCard(label: 'Open Disputes', value: '${_s['open_disputes'] ?? 0}', icon: Icons.gavel_rounded, color: AppColors.error),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15),
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(child: PremiumSectionTitle(title: 'Quick Actions', subtitle: 'Manage platform resources')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _quickActions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final action = _quickActions[i];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        switch (i) {
                          case 0: Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())); break;
                          case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKYCScreen())); break;
                          case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDisputesScreen())); break;
                          case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminComplaintsScreen())); break;
                          case 4: Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeaturedSlotsScreen())); break;
                        }
                      },
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: action.$3),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.md(action.$3.first),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(action.$1, color: Colors.white, size: 28),
                          const SizedBox(height: 6),
                          Text(action.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Revenue chart
            if (weekly.isNotEmpty) ...[
              SliverToBoxAdapter(child: PremiumSectionTitle(title: 'Weekly Revenue', subtitle: 'Last 7 days')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PremiumGlassCard(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currencyFmt.format(_s['revenue_today'] ?? 0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('Today\'s revenue', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              maxY: maxAmt * 1.2,
                              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= weekly.length) return const SizedBox.shrink();
                                  return Padding(padding: const EdgeInsets.only(top: 4), child: Text(weekly[idx]['day']?.toString() ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)));
                                })),
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              barGroups: weekly.asMap().entries.map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [BarChartRodData(
                                  toY: (e.value['amount'] as num?)?.toDouble() ?? 0,
                                  gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                  width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                )],
                              )).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Live activity
            SliverToBoxAdapter(child: PremiumSectionTitle(title: 'Live Activity', subtitle: 'Recent platform events')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final ev = _activityFeed[i];
                    final type = ev['icon']?.toString() ?? ev['type']?.toString() ?? '';
                    final color = _activityColor(type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: PremiumGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(AppRadius.lg)),
                            child: Icon(_activityIcon(type), color: color, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(ev['message']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: AppSpacing.sm),
                          Text(ev['time']?.toString() ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  },
                  childCount: _activityFeed.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
