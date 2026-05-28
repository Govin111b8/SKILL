import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/points_service.dart';
import '../../widgets/skeleton_loader.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty & Points')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? _buildSkeleton()
            : _error != null
                ? ListView(
                    children: [
                      EmptyStateWidget(
                        icon: Icons.stars_rounded,
                        iconColor: Colors.red,
                        title: 'Could not load loyalty points',
                        subtitle: _error!,
                        actionLabel: 'Retry',
                        onAction: _load,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPointsCard(context, details),
                      const SizedBox(height: 16),
                      _buildRedeemCard(context),
                      const SizedBox(height: 20),
                      Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (_transactions.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.receipt_long_outlined,
                          title: 'No points activity yet',
                          subtitle: 'Earn points from bookings, referrals, and future loyalty campaigns.',
                        )
                      else
                        ..._transactions.map((tx) => _buildTransactionTile(context, tx)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonLoader(height: 200, radius: 24),
        SizedBox(height: 16),
        SkeletonLoader(height: 180, radius: 24),
        SizedBox(height: 20),
        SkeletonLoader(height: 22, width: 180),
        SizedBox(height: 12),
        SkeletonLoader(height: 84, radius: 16),
        SizedBox(height: 12),
        SkeletonLoader(height: 84, radius: 16),
        SizedBox(height: 12),
        SkeletonLoader(height: 84, radius: 16),
      ],
    );
  }

  Widget _buildPointsCard(BuildContext context, _LevelMeta details) {
    final points = _userPoints?.pointsBalance ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
              ),
              const Spacer(),
              Chip(
                backgroundColor: Colors.white.withAlpha(28),
                label: Text(details.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Points balance', style: TextStyle(color: Colors.white.withAlpha(190))),
          const SizedBox(height: 8),
          Text(
            '$points',
            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lifetime points', style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${_userPoints?.lifetimePoints ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current level', style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Level ${_userPoints?.level ?? 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: details.progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details.pointsToNext == 0 ? 'You are at the top loyalty tier.' : '${details.pointsToNext} points to ${details.nextLabel}',
            style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemCard(BuildContext context) {
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;
    final estimatedDiscount = (points / 10).floorToDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Redeem points', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Use your points for instant discounts on bookings. 10 points = ₹1 off.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Points to redeem',
              prefixIcon: Icon(Icons.stars_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bookingController,
            decoration: const InputDecoration(
              labelText: 'Booking ID (optional)',
              prefixIcon: Icon(Icons.receipt_long_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimated discount: ${_currency.format(estimatedDiscount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                onPressed: _redeeming ? null : _redeem,
                child: _redeeming
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Redeem'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, PointTransaction tx) {
    final isEarn = tx.type == 'earn' || tx.points >= 0;
    final pointsValue = tx.points.abs();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (isEarn ? Colors.green : Colors.orange).withAlpha(18),
            child: Icon(isEarn ? Icons.arrow_downward_rounded : Icons.redeem_rounded, color: isEarn ? Colors.green : Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.reason, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '${isEarn ? '+' : '-'}$pointsValue',
            style: TextStyle(
              color: isEarn ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
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
