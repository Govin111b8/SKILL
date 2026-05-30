import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/points_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final _pointsController = TextEditingController();
  final _bookingController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  UserPoints? _userPoints;
  List<PointTransaction> _transactions = [];
  bool _loading = true;
  bool _redeeming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _bookingController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PointsService.getMyPoints(),
        PointsService.getTransactionHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _userPoints = results[0] as UserPoints;
        _transactions = results[1] as List<PointTransaction>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _redeem() async {
    final points = int.tryParse(_pointsController.text.trim());
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid points amount.')));
      return;
    }
    setState(() => _redeeming = true);
    try {
      await PointsService.redeemPoints(points, _bookingController.text.trim().isEmpty ? null : _bookingController.text.trim());
      if (!mounted) return;
      _pointsController.clear();
      _bookingController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points redeemed successfully.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not redeem points: $e')));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _levelDetails(_userPoints);

    return PremiumScrollScaffold(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.huge),
          children: [
            PremiumHeroHeader(
              title: 'Loyalty & Points',
              subtitle: 'Unlock rewards, redeem instantly, and grow your premium status.',
              icon: Icons.workspace_premium_rounded,
              gradient: const [Color(0xFF1E1B4B), Color(0xFF312E81)],
              chips: [
                PremiumStatChip(
                  label: 'Level ${_userPoints?.level ?? 1}',
                  color: Colors.white,
                  icon: Icons.bolt_rounded,
                ),
                PremiumStatChip(
                  label: '${_userPoints?.pointsBalance ?? 0} pts',
                  color: Colors.white,
                  icon: Icons.stars_rounded,
                ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumLoadingList(itemCount: 5, itemHeight: 120),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumEmptyState(
                  icon: Icons.stars_rounded,
                  title: 'Could not load loyalty points',
                  subtitle: _error!,
                  actionLabel: 'Retry',
                  onAction: _load,
                  gradient: AppColors.warmGradient,
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildPointsCard(details),
              ),
              PremiumSectionTitle(
                title: 'Tier journey',
                subtitle: 'Move up tiers to unlock better rewards and recognition.',
              ),
              SizedBox(
                height: 156,
                child: Builder(
                  builder: (context) {
                    final currentLevel = _userPoints?.level ?? 1;
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      children: [
                        _buildTierCard('Bronze', Icons.shield_moon_rounded, const [Color(0xFF9A6B46), Color(0xFF7C4A25)], details.label == 'Bronze' || currentLevel >= 1),
                        _buildTierCard('Silver', Icons.shield_rounded, const [Color(0xFF94A3B8), Color(0xFF64748B)], details.label == 'Silver' || currentLevel >= 2),
                        _buildTierCard('Gold', Icons.workspace_premium_rounded, const [Color(0xFFFBBF24), Color(0xFFF59E0B)], details.label == 'Gold' || currentLevel >= 3),
                        _buildTierCard('Platinum', Icons.auto_awesome_rounded, const [Color(0xFF38BDF8), Color(0xFF6366F1)], details.label == 'Platinum' || currentLevel >= 4),
                      ],
                    );
                  },
                ),
              ),
              PremiumSectionTitle(
                title: 'Points breakdown',
                subtitle: 'Track what you have earned and redeemed so far.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildBreakdownCard(),
              ),
              PremiumSectionTitle(
                title: 'Redeem rewards',
                subtitle: 'Apply your points to bookings for instant savings.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildRedeemCard(context),
              ),
              PremiumSectionTitle(
                title: 'Recent transactions',
                subtitle: 'Every earn and redeem event appears here in real time.',
              ),
              if (_transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PremiumEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No points activity yet',
                    subtitle: 'Earn points from bookings, referrals, and future loyalty campaigns.',
                  ),
                )
              else
                ..._transactions.map((tx) => Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                      child: _buildTransactionTile(tx),
                    )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(_LevelMeta details) {
    final points = _userPoints?.pointsBalance ?? 0;

    return PremiumGlassCard(
      gradient: const [Color(0xFF1E1B4B), Color(0xFF312E81)],
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(22),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: Colors.white.withAlpha(35)),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 30),
              ),
              const Spacer(),
              const PremiumStatusPill(label: 'Elite tier', color: Colors.amberAccent),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Points balance',
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _heroMetric('Lifetime points', '${_userPoints?.lifetimePoints ?? 0}'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _heroMetric('Current level', 'Level ${_userPoints?.level ?? 1}'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: details.progress,
              minHeight: 10,
              backgroundColor: Colors.white.withAlpha(30),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            details.pointsToNext == 0 ? 'You are at the top loyalty tier.' : '${details.pointsToNext} points to ${details.nextLabel}',
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(170),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(String label, IconData icon, List<Color> colors, bool unlocked) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: PremiumGlassCard(
        gradient: unlocked
            ? colors
            : [
                Colors.white.withAlpha(160),
                Colors.white.withAlpha(100),
              ],
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: unlocked ? Colors.white : Colors.grey.shade600),
                const Spacer(),
                Icon(
                  unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  color: unlocked ? Colors.white : Colors.grey.shade600,
                  size: 18,
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: unlocked ? Colors.white : AppColors.surfaceDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              unlocked ? 'Unlocked' : 'Locked',
              style: TextStyle(
                color: unlocked ? Colors.white.withAlpha(210) : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    final earned = _transactions.where((tx) => tx.type == 'earn' || tx.points >= 0).fold<int>(0, (sum, tx) => sum + tx.points.abs());
    final redeemed = _transactions.where((tx) => tx.type != 'earn' && tx.points < 0).fold<int>(0, (sum, tx) => sum + tx.points.abs());

    return PremiumGlassCard(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Row(
        children: [
          Expanded(
            child: PremiumMetricCard(
              label: 'Earned',
              value: '$earned pts',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PremiumMetricCard(
              label: 'Redeemed',
              value: '$redeemed pts',
              icon: Icons.redeem_rounded,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemCard(BuildContext context) {
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;
    final estimatedDiscount = (points / 10).floorToDouble();

    return PremiumGlassCard(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.warmGradient),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              '10 points = ₹1 off',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Turn your points into instant booking savings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.surfaceDark,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInputField(
            controller: _pointsController,
            label: 'Points to redeem',
            icon: Icons.stars_rounded,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInputField(
            controller: _bookingController,
            label: 'Booking ID (optional)',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated discount',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _currency.format(estimatedDiscount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.surfaceDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (_redeeming)
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.warmGradient),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                PremiumGradientButton(
                  label: 'Redeem',
                  icon: Icons.local_fire_department_rounded,
                  colors: AppColors.warmGradient,
                  onPressed: _redeem,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(170),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withAlpha(220)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(PointTransaction tx) {
    final isEarn = tx.type == 'earn' || tx.points >= 0;
    final pointsValue = tx.points.abs();

    return PremiumGlassCard(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isEarn ? AppColors.success : AppColors.error).withAlpha(18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              isEarn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isEarn ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.reason,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarn ? '+' : '-'}$pointsValue',
                style: TextStyle(
                  color: isEarn ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PremiumStatusPill(
                label: isEarn ? 'Earned' : 'Redeemed',
                color: isEarn ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _LevelMeta _levelDetails(UserPoints? userPoints) {
    final level = userPoints?.level ?? 1;
    final lifetimePoints = userPoints?.lifetimePoints ?? 0;
    if (level >= 4 || lifetimePoints >= 3000) {
      return const _LevelMeta(label: 'Platinum', nextLabel: 'Platinum', progress: 1, pointsToNext: 0);
    }
    if (level == 3 || lifetimePoints >= 1500) {
      final pointsToNext = (3000 - lifetimePoints).clamp(0, 3000);
      final progress = ((lifetimePoints - 1500) / 1500).clamp(0, 1).toDouble();
      return _LevelMeta(label: 'Gold', nextLabel: 'Platinum', progress: progress, pointsToNext: pointsToNext);
    }
    if (level == 2 || lifetimePoints >= 500) {
      final pointsToNext = (1500 - lifetimePoints).clamp(0, 1500);
      final progress = ((lifetimePoints - 500) / 1000).clamp(0, 1).toDouble();
      return _LevelMeta(label: 'Silver', nextLabel: 'Gold', progress: progress, pointsToNext: pointsToNext);
    }
    final pointsToNext = (500 - lifetimePoints).clamp(0, 500);
    final progress = (lifetimePoints / 500).clamp(0, 1).toDouble();
    return _LevelMeta(label: 'Bronze', nextLabel: 'Silver', progress: progress, pointsToNext: pointsToNext);
  }
}

class _LevelMeta {
  final String label;
  final String nextLabel;
  final double progress;
  final int pointsToNext;

  const _LevelMeta({required this.label, required this.nextLabel, required this.progress, required this.pointsToNext});
}
