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
      if (t.startsWith('booking_')) _load();
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isPro = auth.isProfessional;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final (key, label) = _filters[i];
                final selected = _filter == key;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) { setState(() => _filter = key); _load(); },
                );
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const SkeletonBookingCard(),
            )
          : _error != null
              ? RefreshIndicator(onRefresh: _load, child: ListView(children: [_ErrorView(error: _error!, onRetry: _load)]))
              : _items.isEmpty
                  ? RefreshIndicator(onRefresh: _load, child: ListView(children: [_EmptyView(isPro: isPro, filter: _filter)]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _BookingCard(
                          booking: _items[i],
                          isPro: isPro,
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(bookingId: _items[i].id),
                            ));
                            _load();
                          },
                        ),
                      ),
                    ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isPro;
  final VoidCallback onTap;
  const _BookingCard({required this.booking, required this.isPro, required this.onTap});

  static final _dtFmt = DateFormat('MMM d, h:mm a');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherName = isPro ? booking.customerName : booking.professionalName;
    final statusColor = bookingStatusColor(booking.status);
    final initial = (otherName?.isNotEmpty == true) ? otherName![0].toUpperCase() : '?';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Status-colored left bar
              Container(width: 3, height: 40, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? const Color(0xFF334155) : cs.primaryContainer,
                child: Text(initial, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(otherName ?? 'Unknown', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (booking.categoryName != null)
                  Text(booking.categoryName!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withAlpha(18), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withAlpha(50))),
                child: Text(prettyStatus(booking.status), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(booking.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (booking.description != null) ...[
              const SizedBox(height: 3),
              Text(booking.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.schedule_rounded, size: 13, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(_dtFmt.format(booking.createdAt.toLocal()), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
              const Spacer(),
              if (booking.quotedAmount != null || booking.finalAmount != null)
                Text(
                  '₹${(booking.finalAmount ?? booking.quotedAmount)!.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: cs.primary),
                ),
            ]),
          ]),
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
    if (filter != 'all') {
      return EmptyStateWidget(
        icon: Icons.filter_list_off_rounded,
        iconColor: const Color(0xFF6366F1),
        title: 'No ${filter.replaceAll('_', ' ')} bookings',
        subtitle: 'Try a different filter to see your bookings.',
      );
    }
    return EmptyStateWidget(
      icon: isPro ? Icons.work_outline_rounded : Icons.calendar_today_rounded,
      iconColor: const Color(0xFF6366F1),
      title: isPro ? 'No booking requests yet' : 'No bookings yet',
      subtitle: isPro
          ? 'Complete your profile so customers can find and book you.'
          : 'Browse professionals and book a service to get started.',
      actionLabel: isPro ? null : 'Browse services',
      onAction: isPro ? null : () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => EmptyStateWidget(
    icon: Icons.wifi_off_rounded,
    iconColor: Colors.red,
    title: 'Connection error',
    subtitle: 'Could not load bookings. Check your connection and try again.',
    actionLabel: 'Try again',
    onAction: onRetry,
  );
}

Color bookingStatusColor(String s) {
  switch (s) {
    case 'requested':  return const Color(0xFFF59E0B);
    case 'quoted':     return const Color(0xFF6366F1);
    case 'accepted':   return const Color(0xFF10B981);
    case 'scheduled':  return const Color(0xFF06B6D4);
    case 'in_progress':return const Color(0xFF8B5CF6);
    case 'completed':  return const Color(0xFF22C55E);
    case 'cancelled':  return const Color(0xFF94A3B8);
    case 'disputed':   return const Color(0xFFEF4444);
    case 'refunded':   return const Color(0xFFF97316);
    default: return Colors.grey;
  }
}

String prettyStatus(String s) =>
    s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
