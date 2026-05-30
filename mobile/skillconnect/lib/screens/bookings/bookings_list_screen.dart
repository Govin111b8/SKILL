import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';
import 'booking_detail_screen.dart';
import 'booking_calendar_screen.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  List<Booking> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  static const _filters = [
    ('all', 'All'),
    ('requested', 'New'),
    ('quoted', 'Quoted'),
    ('accepted', 'Accepted'),
    ('scheduled', 'Scheduled'),
    ('in_progress', 'Active'),
    ('completed', 'Done'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _wsSub = RealtimeService.instance.stream.listen((event) {
      if (!mounted) return;
      final t = event['type']?.toString() ?? '';
      if (t == 'booking' || t.startsWith('booking_') || t == 'notification') _load();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _items = await BookingService.list(status: _filter == 'all' ? null : _filter);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'requested':   return const Color(0xFFF59E0B);
      case 'quoted':      return const Color(0xFF6366F1);
      case 'accepted':    return const Color(0xFF10B981);
      case 'scheduled':   return const Color(0xFF06B6D4);
      case 'in_progress': return const Color(0xFF8B5CF6);
      case 'completed':   return const Color(0xFF22C55E);
      case 'cancelled':   return const Color(0xFF94A3B8);
      case 'disputed':    return const Color(0xFFEF4444);
      case 'refunded':    return const Color(0xFFF97316);
      default: return Colors.grey;
    }
  }

  String _prettyStatus(String s) =>
      s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isPro = auth.isProfessional;
    final activeCount = _items.where((b) => b.status == 'in_progress' || b.status == 'scheduled').length;

    Widget content;
    if (_loading) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          PremiumHeroHeader(
            title: 'My Bookings',
            subtitle: isPro
                ? 'Stay on top of every customer request with a polished business view.'
                : 'Track upcoming services, quotes, and premium experiences in one place.',
            icon: Icons.calendar_month_rounded,
            gradient: AppColors.heroGradient,
            trailing: _HeroHighlight(label: 'Live', value: 'Sync'),
            chips: const [
              PremiumStatChip(label: 'Live updates', icon: Icons.bolt_rounded, color: Colors.white),
              PremiumStatChip(label: 'Premium flow', icon: Icons.auto_awesome_rounded, color: Colors.white),
            ],
          ),
          _FilterStrip(
            filters: _filters,
            selected: _filter,
            onSelected: (key) {
              HapticFeedback.selectionClick();
              setState(() => _filter = key);
              _load();
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PremiumLoadingList(itemCount: 4, itemHeight: 132),
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
            PremiumHeroHeader(
              title: 'My Bookings',
              subtitle: 'Your booking hub is ready as soon as your connection is back.',
              icon: Icons.calendar_month_rounded,
              gradient: AppColors.heroGradient,
              trailing: _HeroHighlight(label: 'Status', value: 'Offline'),
              chips: const [
                PremiumStatChip(label: 'Secure sync', icon: Icons.shield_rounded, color: Colors.white),
              ],
            ),
            _FilterStrip(
              filters: _filters,
              selected: _filter,
              onSelected: (key) {
                HapticFeedback.selectionClick();
                setState(() => _filter = key);
                _load();
              },
            ),
            _ErrorView(error: _error!, onRetry: _load),
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
          children: [
            PremiumHeroHeader(
              title: 'My Bookings',
              subtitle: isPro
                  ? 'New requests will appear here the moment customers reach out.'
                  : 'Your scheduled services and completed jobs will show up here beautifully.',
              icon: Icons.calendar_month_rounded,
              gradient: AppColors.heroGradient,
              trailing: _HeroHighlight(label: 'Count', value: '0'),
              chips: [
                PremiumStatChip(label: 'Filter: ${_filters.firstWhere((f) => f.$1 == _filter).$2}', icon: Icons.tune_rounded, color: Colors.white),
              ],
            ),
            _FilterStrip(
              filters: _filters,
              selected: _filter,
              onSelected: (key) {
                HapticFeedback.selectionClick();
                setState(() => _filter = key);
                _load();
              },
            ),
            _EmptyView(isPro: isPro, filter: _filter),
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
              title: 'My Bookings',
              subtitle: isPro
                  ? 'Manage every request, confirm schedules, and keep your business moving.'
                  : 'Follow every quote, service visit, and completion update with premium clarity.',
              icon: Icons.calendar_month_rounded,
              gradient: AppColors.heroGradient,
              trailing: _HeroHighlight(label: 'Total', value: '${_items.length}'),
              chips: [
                PremiumStatChip(label: '${_items.length} visible', icon: Icons.receipt_long_rounded, color: Colors.white),
                PremiumStatChip(label: '$activeCount active', icon: Icons.timelapse_rounded, color: Colors.white),
              ],
            ),
            _FilterStrip(
              filters: _filters,
              selected: _filter,
              onSelected: (key) {
                HapticFeedback.selectionClick();
                setState(() => _filter = key);
                _load();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: List.generate(
                  _items.length,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: i == _items.length - 1 ? 0 : AppSpacing.md),
                    child: _BookingCard(
                      booking: _items[i],
                      isPro: isPro,
                      statusColor: _statusColor(_items[i].status),
                      prettyStatus: _prettyStatus(_items[i].status),
                      animationDelay: i * 60,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    BookingDetailScreen(bookingId: _items[i].id)));
                        _load();
                      },
                    ),
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
        title: const Text('Bookings', style: TextStyle(fontWeight: FontWeight.w800)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            tooltip: 'Calendar view',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const BookingCalendarScreen())),
          ),
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(top: false, child: content),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final Booking booking;
  final bool isPro;
  final Color statusColor;
  final String prettyStatus;
  final int animationDelay;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.isPro,
    required this.statusColor,
    required this.prettyStatus,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  static final _dtFmt = DateFormat('MMM d, h:mm a');

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData _serviceIcon(String? category) {
    final c = category?.toLowerCase() ?? '';
    if (c.contains('plumb')) return Icons.plumbing_rounded;
    if (c.contains('electr')) return Icons.electrical_services_rounded;
    if (c.contains('clean')) return Icons.cleaning_services_rounded;
    if (c.contains('paint')) return Icons.format_paint_rounded;
    if (c.contains('tutor') || c.contains('teach')) return Icons.school_rounded;
    if (c.contains('salon') || c.contains('beauty')) return Icons.content_cut_rounded;
    if (c.contains('fitness') || c.contains('yoga')) return Icons.fitness_center_rounded;
    if (c.contains('repair') || c.contains('ac')) return Icons.build_rounded;
    return Icons.home_repair_service_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final otherName =
        widget.isPro ? widget.booking.customerName : widget.booking.professionalName;
    final isActive = widget.booking.status == 'in_progress';
    final amount = widget.booking.finalAmount ?? widget.booking.quotedAmount;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1.0,
            duration: AppDurations.fast,
            child: PremiumGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.statusColor.withAlpha(40),
                                    widget.statusColor.withAlpha(20),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: widget.statusColor.withAlpha(70)),
                              ),
                              child: Icon(
                                _serviceIcon(widget.booking.categoryName),
                                color: widget.statusColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.booking.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                            color: AppColors.surfaceDark,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      PremiumStatusPill(
                                        label: widget.prettyStatus,
                                        color: widget.statusColor,
                                      ),
                                    ],
                                  ),
                                  if (otherName != null) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      otherName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.md),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      _MetaChip(
                                        icon: Icons.schedule_rounded,
                                        label: _dtFmt.format(widget.booking.createdAt.toLocal()),
                                      ),
                                      if (widget.booking.categoryName != null)
                                        _MetaChip(
                                          icon: Icons.label_outline_rounded,
                                          label: widget.booking.categoryName!,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(110),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: Colors.white.withAlpha(160)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Booking moment',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.booking.scheduledFor != null
                                          ? DateFormat('EEE, MMM d • h:mm a').format(widget.booking.scheduledFor!.toLocal())
                                          : 'Scheduling in progress',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (amount != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Amount',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(AppRadius.xl),
                          bottomRight: Radius.circular(AppRadius.xl),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Service in progress · live updates enabled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isPro;
  final String filter;
  const _EmptyView({required this.isPro, required this.filter});

  @override
  Widget build(BuildContext context) {
    final String title = filter != 'all'
        ? 'No ${filter.replaceAll('_', ' ')} bookings'
        : (isPro ? 'No requests yet' : 'No bookings yet');
    final String subtitle = filter != 'all'
        ? 'Switch to another filter to view a different set of bookings.'
        : (isPro
            ? 'Your premium business queue will appear here when new customers book you.'
            : 'Browse top professionals and make your first booking to unlock this space.');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PremiumEmptyState(
        icon: filter != 'all' ? Icons.filter_alt_off_rounded : (isPro ? Icons.inbox_rounded : Icons.calendar_today_rounded),
        title: title,
        subtitle: subtitle,
        actionLabel: !isPro && filter == 'all' ? 'Browse Services' : null,
        onAction: !isPro && filter == 'all'
            ? () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false)
            : null,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: PremiumEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Connection error',
        subtitle: error,
        actionLabel: 'Try Again',
        onAction: onRetry,
        gradient: AppColors.warmGradient,
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  final List<(String, String)> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterStrip({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: PremiumGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final (key, label) = filters[i];
              final isSelected = selected == key;
              return GestureDetector(
                onTap: () => onSelected(key),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: AppColors.primaryGradient) : null,
                    color: isSelected ? null : Colors.white.withAlpha(120),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.white.withAlpha(150),
                    ),
                    boxShadow: isSelected ? AppShadows.sm(AppColors.primary) : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.surfaceDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroHighlight extends StatelessWidget {
  final String label;
  final String value;

  const _HeroHighlight({required this.label, required this.value});

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(215),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(110),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withAlpha(160)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.surfaceDark,
            ),
          ),
        ],
      ),
    );
  }
}

Color bookingStatusColor(String s) {
  switch (s) {
    case 'requested':   return const Color(0xFFF59E0B);
    case 'quoted':      return const Color(0xFF6366F1);
    case 'accepted':    return const Color(0xFF10B981);
    case 'scheduled':   return const Color(0xFF06B6D4);
    case 'in_progress': return const Color(0xFF8B5CF6);
    case 'completed':   return const Color(0xFF22C55E);
    case 'cancelled':   return const Color(0xFF94A3B8);
    case 'disputed':    return const Color(0xFFEF4444);
    case 'refunded':    return const Color(0xFFF97316);
    default: return Colors.grey;
  }
}

String prettyStatus(String s) =>
    s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
