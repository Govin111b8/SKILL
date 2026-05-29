import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/skeleton_loader.dart';
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

  // Demo stats shown when API unavailable
  static const _demoStats = {
    'total_users': 14832,
    'new_signups_today': 47,
    'active_bookings': 218,
    'gmv_today': 184500,
    'open_disputes': 12,
    'pending_kyc': 34,
    'revenue_today': 184500,
    'weekly_revenue': [
      {'day': 'Mon', 'amount': 98000},
      {'day': 'Tue', 'amount': 124000},
      {'day': 'Wed', 'amount': 143000},
      {'day': 'Thu', 'amount': 109000},
      {'day': 'Fri', 'amount': 167000},
      {'day': 'Sat', 'amount': 201000},
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
    // Auto-refresh every 30 s
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    // WebSocket live feed
    _wsSub = RealtimeService.instance.stream.listen((ev) {
      if (!mounted) return;
      final t = ev['type']?.toString() ?? '';
      if (t.isNotEmpty) {
        final message = ev['message']?.toString() ?? 'Platform event: $t';
        setState(() {
          _activityFeed.insert(0, {
            'type': t,
            'message': message,
            'time': 'Just now',
            'icon': t,
          });
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

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? Map<String, dynamic>.from(_demoStats);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _loading
                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _load,
                    tooltip: 'Refresh',
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _stats == null
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _KpiCard(label: 'Total Users', value: _fmt(stats['total_users']), icon: Icons.people_outline_rounded, color: const Color(0xFF6366F1), sub: '+${stats['new_signups_today'] ?? 0} today'),
                      _KpiCard(label: 'Active Bookings', value: _fmt(stats['active_bookings']), icon: Icons.calendar_month_rounded, color: const Color(0xFF10B981)),
                      _KpiCard(label: "GMV Today", value: _currencyFmt.format((stats['gmv_today'] as num?)?.toInt() ?? 0), icon: Icons.payments_outlined, color: const Color(0xFFF59E0B)),
                      _KpiCard(label: 'Open Disputes', value: _fmt(stats['open_disputes']), icon: Icons.report_problem_outlined, color: Colors.red, sub: '${stats['pending_kyc'] ?? 0} KYC pending'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Revenue chart
                  _RevenueChart(weeklyData: (stats['weekly_revenue'] as List? ?? _demoStats['weekly_revenue'] as List)),
                  const SizedBox(height: 20),
                  // Quick actions
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _QuickCard(title: 'Manage Users', icon: Icons.manage_accounts_outlined, badge: _fmt(stats['total_users']), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()))),
                      _QuickCard(title: 'Review KYC', icon: Icons.verified_user_outlined, badge: '${stats['pending_kyc'] ?? 0}', badgeColor: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKYCScreen()))),
                      _QuickCard(title: 'Resolve Disputes', icon: Icons.balance_outlined, badge: '${stats['open_disputes'] ?? 0}', badgeColor: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDisputesScreen()))),
                      _QuickCard(title: 'Complaints', icon: Icons.report_gmailerrorred_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminComplaintsScreen()))),
                      _QuickCard(title: 'Featured Slots', icon: Icons.star_outline_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeaturedSlotsScreen()))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Live activity feed
                  Row(children: [
                    Text('Live Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ..._activityFeed.take(10).map((item) => _ActivityTile(item: item)),
                ],
              ),
      ),
    );
  }

  String _fmt(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withAlpha(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12)),
        if (sub != null) Text(sub!, style: TextStyle(fontSize: 10, color: color)),
      ]),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;
  const _QuickCard({required this.title, required this.icon, required this.onTap, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          if (badge != null && badge != '0')
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List weeklyData;
  const _RevenueChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bars = weeklyData.map((d) {
      final m = d as Map;
      return BarChartGroupData(
        x: weeklyData.indexOf(d),
        barRods: [
          BarChartRodData(
            toY: ((m['amount'] as num?)?.toDouble() ?? 0) / 1000,
            color: cs.primary,
            width: 24,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('7-Day Revenue (₹ thousands)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: BarChart(BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: bars,
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= weeklyData.length) return const Text('');
                  final d = weeklyData[i] as Map;
                  return Text(d['day']?.toString() ?? '', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '₹${(rod.toY * 1000).toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ),
        )),
      ),
    ]);
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityTile({required this.item});

  IconData _icon(String type) {
    switch (type) {
      case 'booking': case 'booking_status': return Icons.calendar_month_outlined;
      case 'kyc': return Icons.verified_user_outlined;
      case 'dispute': case 'new_dispute': return Icons.balance_outlined;
      case 'signup': return Icons.person_add_outlined;
      case 'fraud': return Icons.warning_amber_outlined;
      case 'payment': return Icons.payments_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'booking': case 'booking_status': return const Color(0xFF6366F1);
      case 'kyc': return const Color(0xFF10B981);
      case 'dispute': case 'new_dispute': return Colors.red;
      case 'signup': return const Color(0xFF06B6D4);
      case 'fraud': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = item['type']?.toString() ?? '';
    final color = _color(type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withAlpha(8),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
          child: Icon(_icon(type), size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(item['message']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(width: 8),
        Text(item['time']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
      ]),
    );
  }
}
