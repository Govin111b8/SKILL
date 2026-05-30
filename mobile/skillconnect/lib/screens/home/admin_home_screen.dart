import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';
import '../admin/admin_users_screen.dart';
import '../admin/admin_kyc_screen.dart';
import '../admin/admin_disputes_screen.dart';
import '../admin/admin_complaints_screen.dart';
import '../admin/admin_featured_slots_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  late final AnimationController _shimmerCtrl;
  late final AnimationController _orbCtrl;

  // Admin dark theme colors
  static const _darkBg = Color(0xFF0F172A);
  static const _darkCard = Color(0xFF1E293B);
  static const _darkBorder = Color(0xFF334155);
  static const _accent = Color(0xFF6366F1);
  static const _accentLight = Color(0xFF818CF8);

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/stats');
      _stats = res['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: _loading
          ? Container(
              color: _darkBg,
              child: const Center(
                  child: CircularProgressIndicator(
                      color: _accent)),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Container(
      color: _darkBg,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 56),
          const SizedBox(height: 16),
          const Text('Dashboard Unavailable',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(_error!,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_accent, _accentLight]),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // ── Hero SliverAppBar ──────────────────────────────────────
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: _darkBg,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            title: const Text(
              'Admin Control',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
                ),
              ),
              child: Stack(
                children: [
                  // Orb decorations
                  AnimatedBuilder(
                    animation: _orbCtrl,
                    builder: (_, __) => Stack(children: [
                      Positioned(
                        top: -20 + math.sin(_orbCtrl.value * math.pi) * 12,
                        right: -20,
                        child: _DarkOrb(color: _accent.withAlpha(60), size: 200),
                      ),
                      Positioned(
                        bottom: 40,
                        left: -30,
                        child: _DarkOrb(color: _accentLight.withAlpha(30), size: 160),
                      ),
                    ]),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shield badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _accent.withAlpha(40),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: _accent.withAlpha(80)),
                            ),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_rounded,
                                      size: 14, color: _accentLight),
                                  SizedBox(width: 6),
                                  Text('SYSTEM ADMINISTRATOR',
                                      style: TextStyle(
                                          color: _accentLight,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2)),
                                ]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_stats?['total_users'] ?? 0} Total Users',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_stats?['pending_kyc'] ?? 0} KYC pending · ${_stats?['active_disputes'] ?? 0} disputes',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(children: [
              // ── Platform Stats ───────────────────────────────────
              _AdminStatsGrid(stats: _stats),
              const SizedBox(height: AppSpacing.lg),

              // ── User Management ──────────────────────────────────
              _SectionLabel('User Management', Icons.people_rounded),
              const SizedBox(height: AppSpacing.md),
              _AdminActionRow(items: [
                _AdminAction('Users', Icons.manage_accounts_rounded,
                    const Color(0xFF6366F1), () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
                }),
                _AdminAction('KYC Review', Icons.verified_user_rounded,
                    const Color(0xFF10B981), () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminKycScreen()));
                }),
              ]),
              const SizedBox(height: AppSpacing.lg),

              // ── Operations ───────────────────────────────────────
              _SectionLabel('Operations', Icons.settings_rounded),
              const SizedBox(height: AppSpacing.md),
              _AdminActionRow(items: [
                _AdminAction('Bookings', Icons.calendar_month_rounded,
                    const Color(0xFF0EA5E9), () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen()));
                }),
                _AdminAction('Complaints', Icons.report_rounded,
                    const Color(0xFFEF4444), () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AdminComplaintsScreen()));
                }),
              ]),
              const SizedBox(height: AppSpacing.lg),

              // ── Finance & Analytics ──────────────────────────────
              _SectionLabel('Finance & Analytics', Icons.bar_chart_rounded),
              const SizedBox(height: AppSpacing.md),
              _AdminActionRow(items: [
                _AdminAction('Featured', Icons.star_rounded,
                    const Color(0xFFF59E0B), () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AdminFeaturedSlotsScreen()));
                }),
                _AdminAction('Disputes', Icons.gavel_rounded,
                    const Color(0xFF8B5CF6), () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDisputesScreen()));
                }),
              ]),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _AdminStatsGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _AdminStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    const dark = _AdminHomeScreenState._darkCard;
    const border = _AdminHomeScreenState._darkBorder;
    final items = [
      _Stat('Bookings', '${stats?["total_bookings"] ?? 0}',
          Icons.calendar_today_rounded, const Color(0xFF0EA5E9)),
      _Stat('Revenue', '₹${stats?["total_revenue"] ?? 0}',
          Icons.currency_rupee_rounded, const Color(0xFF10B981)),
      _Stat('Pros', '${stats?["total_professionals"] ?? 0}',
          Icons.work_rounded, const Color(0xFF6366F1)),
      _Stat('Disputes', '${stats?["active_disputes"] ?? 0}',
          Icons.gavel_rounded, const Color(0xFFEF4444)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: items
          .map((s) => Container(
                decoration: BoxDecoration(
                  color: dark,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: s.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.value,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18)),
                          Text(s.label,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ]),
                ),
              ))
          .toList(),
    );
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: _AdminHomeScreenState._accentLight, size: 18),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15)),
    ]);
  }
}

class _AdminActionRow extends StatelessWidget {
  final List<_AdminAction> items;
  const _AdminActionRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: item.onTap,
            child: Container(
              margin: EdgeInsets.only(
                  left: item == items.first ? 0 : 10),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: _AdminHomeScreenState._darkCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                    color: item.color.withAlpha(60)),
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Tap to manage',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10)),
                      ]),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: Colors.grey.shade600),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AdminAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AdminAction(this.label, this.icon, this.color, this.onTap);
}

class _DarkOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _DarkOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}
