import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../widgets/book_now_sheet.dart';
import '../../widgets/skeleton_loader.dart';
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Service History')),
      body: _loading
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const SkeletonBookingCard(),
            )
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                ]))
              : _items.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history_rounded, size: 64, color: cs.primary.withAlpha(100)),
                      const SizedBox(height: 16),
                      Text('No completed services yet', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Your completed bookings will appear here', style: Theme.of(context).textTheme.bodySmall),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _HistoryCard(
                          booking: _items[i],
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
  final VoidCallback onTap;
  final VoidCallback onRebook;
  const _HistoryCard({required this.booking, required this.onTap, required this.onRebook});

  static final _dtFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final proName = booking.professionalName ?? 'Unknown';
    final initial = proName.isNotEmpty ? proName[0].toUpperCase() : '?';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primaryContainer,
                child: Text(initial, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(proName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(booking.title, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(_dtFmt.format((booking.completedAt ?? booking.createdAt).toLocal()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
              if (booking.categoryName != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.label_outline, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(booking.categoryName!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
              const Spacer(),
              if (booking.finalAmount != null || booking.quotedAmount != null)
                Text('₹${(booking.finalAmount ?? booking.quotedAmount)!.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: cs.primary)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRebook,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Book Again'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
