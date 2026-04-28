import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
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
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _items.isEmpty
                  ? _EmptyView(isPro: isPro)
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final otherName = isPro ? booking.customerName : booking.professionalName;
    final statusColor = bookingStatusColor(booking.status);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text((otherName ?? '?')[0].toUpperCase(),
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(otherName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (booking.categoryName != null)
                  Text(booking.categoryName!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(prettyStatus(booking.status),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(booking.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            if (booking.description != null) ...[
              const SizedBox(height: 4),
              Text(booking.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(DateFormat('MMM d, h:mm a').format(booking.createdAt.toLocal()),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const Spacer(),
              if (booking.quotedAmount != null)
                Text('₹${booking.quotedAmount!.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isPro;
  const _EmptyView({required this.isPro});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(isPro ? 'No booking requests yet' : 'No bookings yet',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              isPro
                  ? 'Customer requests will appear here.'
                  : 'Browse professionals and request a service to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ]),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

Color bookingStatusColor(String s) {
  switch (s) {
    case 'requested': return const Color(0xFFF59E0B);
    case 'quoted': return const Color(0xFF6366F1);
    case 'accepted': return const Color(0xFF10B981);
    case 'scheduled': return const Color(0xFF06B6D4);
    case 'in_progress': return const Color(0xFF8B5CF6);
    case 'completed': return const Color(0xFF22C55E);
    case 'cancelled': return const Color(0xFF94A3B8);
    case 'disputed': return const Color(0xFFEF4444);
    case 'refunded': return const Color(0xFFF97316);
    default: return Colors.grey;
  }
}

String prettyStatus(String s) =>
    s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
