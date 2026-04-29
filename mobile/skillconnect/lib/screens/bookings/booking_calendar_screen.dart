import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import 'booking_detail_screen.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _bookings = await BookingService.list();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Booking> _getEventsForDay(DateTime day) {
    return _bookings.where((b) {
      final d = b.scheduledFor ?? b.createdAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Booking>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              TableCalendar<Booking>(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2027, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  markerSize: 6,
                  todayDecoration: BoxDecoration(color: cs.primary.withAlpha(50), shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(formatButtonShowsNext: false, titleCentered: true),
              ),
              const Divider(height: 1),
              // Events list
              Expanded(
                child: selectedEvents.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.event_available, size: 48, color: cs.primary.withAlpha(100)),
                        const SizedBox(height: 8),
                        Text('No bookings on this day', style: Theme.of(context).textTheme.bodyMedium),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: selectedEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final b = selectedEvents[i];
                          return _CalendarEventCard(booking: b, onTap: () async {
                            HapticFeedback.selectionClick();
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(bookingId: b.id),
                            ));
                            _load();
                          });
                        },
                      ),
              ),
            ]),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  const _CalendarEventCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = booking.scheduledFor != null
        ? DateFormat('h:mm a').format(booking.scheduledFor!.toLocal())
        : 'Unscheduled';
    final statusColor = _statusColor(booking.status);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 4, height: 42,
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${booking.customerName ?? booking.professionalName ?? 'Unknown'} · $time',
                  style: Theme.of(context).textTheme.bodySmall),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Text(booking.status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'scheduled': return const Color(0xFF06B6D4);
      case 'in_progress': return const Color(0xFF8B5CF6);
      case 'completed': return const Color(0xFF22C55E);
      case 'cancelled': return const Color(0xFF94A3B8);
      case 'requested': return const Color(0xFFF59E0B);
      case 'quoted': return const Color(0xFF6366F1);
      case 'accepted': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }
}
