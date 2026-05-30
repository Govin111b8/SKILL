import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
// ignore: unused_import
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class AgentLeaderboardScreen extends StatefulWidget {
  const AgentLeaderboardScreen({super.key});

  @override
  State<AgentLeaderboardScreen> createState() => _AgentLeaderboardScreenState();
}

class _AgentLeaderboardScreenState extends State<AgentLeaderboardScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;
  String? _error;
  String _period = 'month';

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
      final res = await ApiService.get('/agents/leaderboard', auth: true, queryParams: {'period': _period});
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['agents'] as List? ?? const [])
              : const [];
      _agents = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(50).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _changePeriod(String value) {
    if (_period == value) return;
    HapticFeedback.mediumImpact();
    setState(() => _period = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final currentId = auth.user?['id']?.toString();
    final podium = _agents.take(3).toList();
    final rest = _agents.length > 3 ? _agents.sublist(3) : const <Map<String, dynamic>>[];

    return PremiumScrollScaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: PremiumHeroHeader(
                  title: 'Leaderboard',
                  subtitle: 'Top performing agents rising through referrals, bookings, and consistency.',
                  icon: Icons.leaderboard_rounded,
                  gradient: const [Color(0xFFD97706), Color(0xFFEF4444)],
                  chips: [
                    _PeriodChip(
                      label: 'This month',
                      selected: _period == 'month',
                      onTap: () => _changePeriod('month'),
                    ),
                    _PeriodChip(
                      label: 'This quarter',
                      selected: _period == 'quarter',
                      onTap: () => _changePeriod('quarter'),
                    ),
                    _PeriodChip(
                      label: 'All time',
                      selected: _period == 'all',
                      onTap: () => _changePeriod('all'),
                    ),
                  ],
                  trailing: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: Colors.white.withAlpha(36)),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: PremiumLoadingList(itemCount: 6, itemHeight: 104),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PremiumEmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: 'Could not load leaderboard',
                  subtitle: _error!,
                  actionLabel: 'Retry',
                  onAction: _load,
                  gradient: const [AppColors.error, Color(0xFFF97316)],
                ),
              )
            else if (_agents.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: PremiumEmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'No rankings yet',
                  subtitle: 'Leaderboard results will appear here once agents start closing more referrals.',
                  gradient: AppColors.warmGradient,
                ),
              )
            else ...[
              if (podium.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (podium.length > 1)
                          Expanded(
                            child: _PodiumCard(
                              agent: podium[1],
                              position: 2,
                              height: 182,
                              currency: _currency,
                              isCurrent: _isCurrentAgent(podium[1], currentId),
                            ),
                          ),
                        if (podium.isNotEmpty)
                          Expanded(
                            child: _PodiumCard(
                              agent: podium[0],
                              position: 1,
                              height: 220,
                              currency: _currency,
                              isCurrent: _isCurrentAgent(podium[0], currentId),
                            ),
                          ),
                        if (podium.length > 2)
                          Expanded(
                            child: _PodiumCard(
                              agent: podium[2],
                              position: 3,
                              height: 164,
                              currency: _currency,
                              isCurrent: _isCurrentAgent(podium[2], currentId),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: PremiumSectionTitle(
                  title: 'All rankings',
                  subtitle: 'See where every agent stands across your current competition window.',
                  trailing: PremiumStatusPill(
                    label: '${_agents.length} ranked',
                    color: AppColors.primary,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                sliver: SliverList.separated(
                  itemCount: rest.length,
                  itemBuilder: (context, index) {
                    final agent = rest[index];
                    final isCurrent = _isCurrentAgent(agent, currentId);
                    return _LeaderboardRow(
                      agent: agent,
                      currency: _currency,
                      isCurrent: isCurrent,
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isCurrentAgent(Map<String, dynamic> agent, String? currentId) {
    return currentId != null && (agent['id']?.toString() == currentId || agent['agent_id']?.toString() == currentId);
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha(32) : Colors.white.withAlpha(16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white.withAlpha(selected ? 70 : 40)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  final int position;
  final double height;
  final NumberFormat currency;
  final bool isCurrent;

  const _PodiumCard({
    required this.agent,
    required this.position,
    required this.height,
    required this.currency,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = switch (position) {
      1 => const [Color(0xFFFDE68A), Color(0xFFF59E0B)],
      2 => const [Color(0xFFE5E7EB), Color(0xFF94A3B8)],
      _ => const [Color(0xFFF5CBA7), Color(0xFFB45309)],
    };
    final amount = ((agent['earnings'] ?? agent['total_commission'] ?? 0) as num).toDouble();
    final score = (agent['performance_score'] ?? 0).toString();

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.all(position == 1 ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: isCurrent ? AppColors.primary : Colors.white.withAlpha(120), width: isCurrent ? 2 : 1.2),
        boxShadow: AppShadows.lg(gradient.last),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            position == 1 ? Icons.emoji_events_rounded : Icons.workspace_premium_rounded,
            color: Colors.white,
            size: position == 1 ? 36 : 30,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: position == 1 ? 70 : 62,
            height: position == 1 ? 70 : 62,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(32),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                '#${agent['rank'] ?? position}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: position == 1 ? 20 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            agent['name']?.toString() ?? 'Agent',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            currency.format(amount),
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontWeight: FontWeight.w800,
              fontSize: position == 1 ? 16 : 14,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Score $score',
            style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> agent;
  final NumberFormat currency;
  final bool isCurrent;

  const _LeaderboardRow({
    required this.agent,
    required this.currency,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final amount = ((agent['earnings'] ?? agent['total_commission'] ?? 0) as num).toDouble();
    final score = (agent['performance_score'] ?? 0).toString();
    final referrals = (agent['referrals_count'] ?? 0).toString();
    final bookings = (agent['bookings_count'] ?? 0).toString();

    final card = PremiumGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCurrent ? AppColors.primaryGradient : [Colors.white, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: isCurrent ? Colors.transparent : Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                '${agent['rank'] ?? ''}',
                style: TextStyle(
                  color: isCurrent ? Colors.white : AppColors.surfaceDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withAlpha(14),
            child: Text(
              _initials(agent['name']?.toString()),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        agent['name']?.toString() ?? 'Agent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const PremiumStatusPill(label: 'You', color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  agent['city']?.toString() ?? 'City not set',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PremiumStatusPill(label: 'Score $score', color: AppColors.success),
                    PremiumStatusPill(label: '$referrals referrals', color: AppColors.warning),
                    PremiumStatusPill(label: '$bookings bookings', color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(amount),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Commission',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isCurrent) return card;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(AppRadius.xl + 2),
        boxShadow: AppShadows.md(AppColors.primary),
      ),
      padding: const EdgeInsets.all(1.5),
      child: card,
    );
  }

  String _initials(String? name) {
    final value = (name ?? 'Agent').trim();
    if (value.isEmpty) return 'A';
    final parts = value.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
    return '${parts.first.characters.take(1)}${parts.last.characters.take(1)}'.toUpperCase();
  }
}
