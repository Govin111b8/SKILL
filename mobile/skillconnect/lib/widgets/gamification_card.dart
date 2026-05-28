import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../services/api_service.dart';

/// Gamification section showing points, streaks, and achievement badges.
class GamificationCard extends StatefulWidget {
  const GamificationCard({super.key});

  @override
  State<GamificationCard> createState() => _GamificationCardState();
}

class _GamificationCardState extends State<GamificationCard> {
  int _points = 0;
  int _streak = 0;
  int _bookingsCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/users/profile', auth: true);
      final data = res['data'] as Map<String, dynamic>? ?? {};
      if (mounted) setState(() {
        _points = (data['loyalty_points'] as num?)?.toInt() ?? 0;
        _streak = (data['booking_streak'] as num?)?.toInt() ?? 0;
        _bookingsCount = (data['total_bookings'] as num?)?.toInt() ?? 0;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || (_points == 0 && _streak == 0 && _bookingsCount == 0)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md(AppColors.primary),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: AppSpacing.sm),
            const Text('Your Rewards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                _getBadgeTitle(),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _StatItem(value: '$_points', label: 'Points', icon: Icons.star_rounded),
              _StatItem(value: '$_streak', label: 'Streak 🔥', icon: Icons.local_fire_department_rounded),
              _StatItem(value: '$_bookingsCount', label: 'Bookings', icon: Icons.check_circle_rounded),
            ],
          ),
          // Progress to next level
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_points % 500) / 500,
              backgroundColor: Colors.white.withAlpha(30),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${500 - (_points % 500)} points to next reward',
            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _getBadgeTitle() {
    if (_bookingsCount >= 50) return '🏆 Platinum';
    if (_bookingsCount >= 20) return '🥇 Gold';
    if (_bookingsCount >= 10) return '🥈 Silver';
    if (_bookingsCount >= 3) return '🥉 Bronze';
    return '⭐ New Member';
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
