import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';
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
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Booking>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w800)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
          ),
        ),
      ),
      body: PremiumBackground(
        child: SafeArea(
          top: false,
          child: _loading
              ? ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: const [
                    SizedBox(height: AppSpacing.md),
                    PremiumLoadingList(itemCount: 4, itemHeight: 120),
                  ],
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: PremiumGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Booking Calendar',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    DateFormat('MMM yyyy').format(_focusedDay),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'See every service day at a glance and jump into booking details with a tap.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
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
                                markerDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                markerSize: 6,
                                todayDecoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary.withAlpha(120)),
                                ),
                                selectedDecoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadows.sm(AppColors.primary),
                                ),
                                weekendTextStyle: const TextStyle(color: AppColors.surfaceDark, fontWeight: FontWeight.w600),
                                defaultTextStyle: const TextStyle(color: AppColors.surfaceDark, fontWeight: FontWeight.w600),
                                outsideTextStyle: TextStyle(color: Colors.grey.shade400),
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonShowsNext: false,
                                titleCentered: true,
                                titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                formatButtonDecoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                formatButtonTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                                weekendStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: PremiumGlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: _CalendarMetric(
                                label: 'Selected day',
                                value: _selectedDay != null ? DateFormat('MMM d').format(_selectedDay!) : 'Today',
                                icon: Icons.today_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _CalendarMetric(
                                label: 'Bookings',
                                value: '${selectedEvents.length}',
                                icon: Icons.event_note_rounded,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PremiumSectionTitle(
                      title: 'Scheduled for the day',
                      subtitle: 'Tap any booking for full details.',
                    ),
                    Expanded(
                      child: selectedEvents.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: PremiumEmptyState(
                                icon: Icons.event_available_rounded,
                                title: 'No bookings on this day',
                                subtitle: 'Choose another date to explore your premium service schedule.',
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                              itemCount: selectedEvents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
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
                  ],
                ),
        ),
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  const _CalendarEventCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = booking.scheduledFor != null
        ? DateFormat('h:mm a').format(booking.scheduledFor!.toLocal())
        : 'Unscheduled';
    final statusColor = _statusColor(booking.status);

    return PremiumGlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor, statusColor.withAlpha(120)]),
              borderRadius: BorderRadius.circular(AppRadius.pill),
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
                        booking.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PremiumStatusPill(
                      label: booking.status.replaceAll('_', ' '),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  booking.customerName ?? booking.professionalName ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      time,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _CalendarMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CalendarMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(110),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withAlpha(150)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
