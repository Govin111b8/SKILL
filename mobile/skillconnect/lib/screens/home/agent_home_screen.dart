import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';
import '../agent/agent_leaderboard_screen.dart';
import '../agent/agent_wallet_screen.dart';
import '../referrals/referrals_screen.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  String? _referralCode;

  late final AnimationController _pulseCtrl;
  late final AnimationController _orbCtrl;

  // Agent commission color
  static const _agentGreen = Color(0xFF10B981);
  static const _agentGreenDark = Color(0xFF059669);
  static const _agentTeal = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/agent/dashboard');
      _stats = res['data'] as Map<String, dynamic>?;
      _referralCode = _stats?['referral_code'] as String? ?? 'SC-AGENT';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _copyReferralCode() {
    if (_referralCode == null) return;
    HapticFeedback.heavyImpact();
    Clipboard.setData(ClipboardData(text: _referralCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral code copied!'),
        backgroundColor: _agentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: _loading
          ? const Center(
              child: PremiumLoadingList(itemCount: 4, itemHeight: 90))
          : _error != null
              ? Center(
                  child: PremiumEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Could not load dashboard',
                    subtitle: _error!,
                    actionLabel: 'Retry',
                    onAction: _load,
                    gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // ── Hero SliverAppBar ──────────────────────────────────────
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: _agentGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 82),
            title: const Text(
              'Agent Hub',
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
                  colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
                ),
              ),
              child: Stack(
                children: [
                  // Animated orbs
                  AnimatedBuilder(
                    animation: _orbCtrl,
                    builder: (_, __) => Stack(children: [
                      Positioned(
                        top: -20 + math.sin(_orbCtrl.value * math.pi) * 15,
                        right: -20,
                        child: _Orb(color: Colors.white.withAlpha(25), size: 180),
                      ),
                      Positioned(
                        bottom: 50,
                        left: -30,
                        child: _Orb(color: Colors.white.withAlpha(15), size: 150),
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
                          Row(children: [
                            // Pulse dot
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withAlpha(
                                          (100 * _pulseCtrl.value).round()),
                                      blurRadius: 8 + 8 * _pulseCtrl.value,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'Active Agent',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            'Commission: ₹${_stats?['pending_commission'] ?? '0'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_stats?['successful_referrals'] ?? 0} successful referrals this month',
                            style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12),
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
              // ── Referral Code Card ───────────────────────────────
              _ReferralCodeCard(
                code: _referralCode ?? 'SC-AGENT',
                onCopy: _copyReferralCode,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Stat Row ─────────────────────────────────────────
              _StatsRow(stats: _stats),
              const SizedBox(height: AppSpacing.lg),

              // ── Quick Actions ────────────────────────────────────
              PremiumSectionTitle(
                title: 'Quick Actions',
                subtitle: 'Grow your network',
                trailing: null,
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickActions(
                onLeaderboard: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AgentLeaderboardScreen())),
                onWallet: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AgentWalletScreen())),
                onReferrals: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ReferralsScreen())),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Recent Activity ──────────────────────────────────
              PremiumSectionTitle(
                title: 'Recent Commissions',
                subtitle: 'Your earnings history',
                trailing: null,
              ),
              const SizedBox(height: AppSpacing.md),
              ...List.generate(
                3,
                (i) => _ActivityTile(
                  name: ['Rahul Kumar', 'Priya Sharma', 'Amit Singh'][i],
                  service: ['Plumbing', 'Beauty', 'Electrician'][i],
                  amount: ['₹150', '₹200', '₹175'][i],
                  daysAgo: i + 1,
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  const _ReferralCodeCard({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR REFERRAL CODE',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onCopy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: Colors.white.withAlpha(50)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.copy_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Copy',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Share and earn ₹150 per successful booking',
                  style: TextStyle(
                      color: Colors.white.withAlpha(180), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Referrals', '${stats?['total_referrals'] ?? 0}',
          Icons.group_add_rounded, const Color(0xFF6366F1)),
      _StatItem('Earnings', '₹${stats?['total_earnings'] ?? 0}',
          Icons.currency_rupee_rounded, const Color(0xFF10B981)),
      _StatItem('Pending', '₹${stats?['pending_commission'] ?? 0}',
          Icons.pending_rounded, const Color(0xFFF59E0B)),
    ];
    return Row(
      children: items.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: s == items.first ? 0 : 8),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: AppShadows.sm(Colors.black),
            ),
            child: Column(children: [
              Icon(s.icon, color: s.color, size: 22),
              const SizedBox(height: 8),
              Text(s.value,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: s.color)),
              const SizedBox(height: 2),
              Text(s.label,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onLeaderboard, onWallet, onReferrals;
  const _QuickActions(
      {required this.onLeaderboard,
      required this.onWallet,
      required this.onReferrals});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _ActionBtn('Leaderboard', Icons.leaderboard_rounded,
          const Color(0xFF6366F1), onLeaderboard),
      const SizedBox(width: 10),
      _ActionBtn('Wallet', Icons.account_balance_wallet_rounded,
          const Color(0xFF10B981), onWallet),
      const SizedBox(width: 10),
      _ActionBtn('Referrals', Icons.share_rounded,
          const Color(0xFFF59E0B), onReferrals),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String name, service, amount;
  final int daysAgo;
  const _ActivityTile(
      {required this.name,
      required this.service,
      required this.amount,
      required this.daysAgo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: AppShadows.sm(Colors.black),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withAlpha(25),
          child: Text(name[0],
              style: const TextStyle(
                  color: Color(0xFF10B981), fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            Text(service,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amount,
              style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          Text('$daysAgo day${daysAgo > 1 ? 's' : ''} ago',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

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
