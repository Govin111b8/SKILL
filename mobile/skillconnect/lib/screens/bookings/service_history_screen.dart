import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../widgets/book_now_sheet.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';
import 'booking_detail_screen.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<Booking> _items = [];
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
      _items = await BookingService.list(status: 'completed');
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalSpend = _items.fold<double>(0, (sum, b) => sum + (b.finalAmount ?? b.quotedAmount ?? 0));

    Widget content;
    if (_loading) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: const [
          PremiumHeroHeader(
            title: 'Service History',
            subtitle: 'Loading your premium archive of completed services and trusted professionals.',
            icon: Icons.history_rounded,
            gradient: AppColors.heroGradient,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PremiumLoadingList(itemCount: 4, itemHeight: 140),
          ),
        ],
      );
    } else if (_error != null) {
      content = RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const PremiumHeroHeader(
              title: 'Service History',
              subtitle: 'Your completed jobs are safely stored and will appear again once you reconnect.',
              icon: Icons.history_rounded,
              gradient: AppColors.heroGradient,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PremiumEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Unable to load history',
                subtitle: _error!,
                actionLabel: 'Retry',
                onAction: _load,
                gradient: AppColors.warmGradient,
              ),
            ),
          ],
        ),
      );
    } else if (_items.isEmpty) {
      content = RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: const [
            PremiumHeroHeader(
              title: 'Service History',
              subtitle: 'Your finished bookings will turn into a beautiful timeline right here.',
              icon: Icons.history_rounded,
              gradient: AppColors.heroGradient,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PremiumEmptyState(
                icon: Icons.history_toggle_off_rounded,
                title: 'No completed services yet',
                subtitle: 'Once a service is completed, it will appear here with quick rebooking access.',
              ),
            ),
          ],
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            PremiumHeroHeader(
              title: 'Service History',
              subtitle: 'Revisit trusted professionals, review completed work, and rebook in seconds.',
              icon: Icons.history_rounded,
              gradient: AppColors.heroGradient,
              trailing: _HistoryHeroStat(value: '${_items.length}', label: 'Completed'),
              chips: [
                PremiumStatChip(label: '${_items.length} services', icon: Icons.check_circle_rounded, color: Colors.white),
                PremiumStatChip(label: '₹${totalSpend.toStringAsFixed(0)} spent', icon: Icons.currency_rupee_rounded, color: Colors.white),
              ],
            ),
            const PremiumSectionTitle(
              title: 'Your premium timeline',
              subtitle: 'Every completed job, ready for review or rebooking.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: List.generate(
                  _items.length,
                  (i) => _HistoryCard(
                    booking: _items[i],
                    isLast: i == _items.length - 1,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(bookingId: _items[i].id),
                      ));
                      _load();
                    },
                    onRebook: () => _rebook(_items[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Service History', style: TextStyle(fontWeight: FontWeight.w800)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
          ),
        ),
      ),
      body: PremiumBackground(
        child: SafeArea(top: false, child: content),
      ),
    );
  }

  void _rebook(Booking booking) {
    HapticFeedback.mediumImpact();
    showBookNowSheet(
      context,
      professionalId: booking.professionalId,
      professionalName: booking.professionalName ?? 'Professional',
      categories: booking.categoryId != null
          ? [{'id': booking.categoryId, 'name': booking.categoryName ?? 'Service'}]
          : [],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Booking booking;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onRebook;
  const _HistoryCard({required this.booking, required this.isLast, required this.onTap, required this.onRebook});

  static final _dtFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final proName = booking.professionalName ?? 'Unknown';
    final initial = proName.isNotEmpty ? proName[0].toUpperCase() : '?';
    final amount = booking.finalAmount ?? booking.quotedAmount;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.successGradient),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.sm(AppColors.success),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 150,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.success.withAlpha(140), AppColors.primary.withAlpha(0)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PremiumGlassCard(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const PremiumStatusPill(label: 'Completed', color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _HistoryInfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: _dtFmt.format((booking.completedAt ?? booking.createdAt).toLocal()),
                      ),
                      if (booking.categoryName != null)
                        _HistoryInfoChip(
                          icon: Icons.label_outline_rounded,
                          label: booking.categoryName!,
                        ),
                      if (amount != null)
                        _HistoryInfoChip(
                          icon: Icons.currency_rupee_rounded,
                          label: amount.toStringAsFixed(0),
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PremiumGradientButton(
                    label: 'Book Again',
                    icon: Icons.replay_rounded,
                    onPressed: onRebook,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HistoryHeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(220), fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

class _HistoryInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _HistoryInfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.surfaceDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(110),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withAlpha(150)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: chipColor),
          ),
        ],
      ),
    );
  }
}
