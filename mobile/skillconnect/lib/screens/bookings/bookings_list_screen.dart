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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF1B6EF3),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
              title: const Text(
                'My Bookings',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B6EF3), Color(0xFF4F46E5)],
                  ),
                ),
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                height: 56,
                color: Colors.transparent,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (key, label) = _filters[i];
                    final selected = _filter == key;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = key);
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected ? const Color(0xFF1B6EF3) : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const SkeletonBookingCard(),
              )
            : _error != null
                ? RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(children: [_ErrorView(error: _error!, onRetry: _load)]))
                : _items.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(children: [_EmptyView(isPro: isPro, filter: _filter)]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF6366F1),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _BookingCard(
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
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service icon circle
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: widget.statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _serviceIcon(widget.booking.categoryName),
                            color: widget.statusColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.booking.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: widget.statusColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: widget.statusColor.withAlpha(60)),
                                    ),
                                    child: Text(
                                      widget.prettyStatus,
                                      style: TextStyle(
                                        color: widget.statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Provider / customer name
                              if (otherName != null)
                                Text(
                                  otherName,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              // Date + amount row
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 13, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    _dtFmt.format(widget.booking.createdAt.toLocal()),
                                    style: TextStyle(
                                        color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                  const Spacer(),
                                  if (widget.booking.quotedAmount != null ||
                                      widget.booking.finalAmount != null)
                                    Text(
                                      '₹${(widget.booking.finalAmount ?? widget.booking.quotedAmount)!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF6366F1),
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

                  // Active booking progress strip
                  if (isActive)
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withAlpha(12),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Service in progress',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF8B5CF6), size: 16),
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
    final String emoji = filter != 'all' ? '🔍' : (isPro ? '📋' : '📅');
    final String title = filter != 'all'
        ? 'No ${filter.replaceAll('_', ' ')} bookings'
        : (isPro ? 'No requests yet' : 'No bookings yet');
    final String subtitle = filter != 'all'
        ? 'Try a different filter to see your bookings.'
        : (isPro
            ? 'Complete your profile so customers can find and book you.'
            : 'Browse professionals and book a service to get started.');

    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5)),
          if (!isPro && filter == 'all') ...[
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
              child: const Text('Browse Services'),
            ),
          ],
        ],
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
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Connection error',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onRetry,
            child: const Text('Try Again'),
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
