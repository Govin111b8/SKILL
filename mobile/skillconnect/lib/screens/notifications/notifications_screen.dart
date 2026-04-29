import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../bookings/booking_detail_screen.dart';
import '../messages/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _load();
    _wsSub = RealtimeService.instance.stream.listen((e) { if (mounted) _load(); });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await NotificationsService.list();
      _items = r.items;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _open(AppNotification n) async {
    HapticFeedback.selectionClick();
    if (n.isUnread) {
      try { await NotificationsService.markRead(n.id); } catch (_) {}
    }
    if (!mounted) return;
    final t = n.type;
    if (t.startsWith('booking_') && n.relatedId != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: n.relatedId!)));
    } else if (t == 'message' && n.relatedId != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(threadId: n.relatedId!, otherName: n.title)));
    }
    _load();
  }

  // Group notifications by date bucket
  List<_Group> _buildGroups() {
    if (_items.isEmpty) return [];
    final now = DateTime.now();
    final todayStart    = DateTime(now.year, now.month, now.day);
    final yesterdayStart= todayStart.subtract(const Duration(days: 1));
    final weekStart     = todayStart.subtract(const Duration(days: 7));

    final groups = <String, List<AppNotification>>{};
    for (final n in _items) {
      final d = n.createdAt.toLocal();
      final String key;
      if (d.isAfter(todayStart))      key = 'Today';
      else if (d.isAfter(yesterdayStart)) key = 'Yesterday';
      else if (d.isAfter(weekStart))  key = 'This week';
      else                             key = 'Older';
      groups.putIfAbsent(key, () => []).add(n);
    }
    // Maintain display order
    final order = ['Today', 'Yesterday', 'This week', 'Older'];
    return order.where((k) => groups.containsKey(k)).map((k) => _Group(k, groups[k]!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unreadCount = _items.where((n) => n.isUnread).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Notifications'),
          if (!_loading && unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
              child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        actions: [
          if (!_loading && _items.any((n) => n.isUnread))
            TextButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                try { await NotificationsService.markAllRead(); } catch (_) {}
                _load();
              },
              child: Text('Mark all read', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: 6,
              itemBuilder: (_, __) => const SkeletonNotificationTile(),
            )
          : _error != null
              ? EmptyStateWidget(
                  icon: Icons.wifi_off_rounded, iconColor: Colors.red,
                  title: 'Connection error',
                  subtitle: 'Could not load notifications. Pull down to retry.',
                  actionLabel: 'Try again', onAction: _load,
                )
              : _items.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.notifications_off_outlined,
                      iconColor: Color(0xFF6366F1),
                      title: 'All caught up!',
                      subtitle: 'No new notifications. We\'ll let you know when something happens.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _buildGroups().fold<int>(0, (sum, g) => sum + 1 + g.items.length),
                        itemBuilder: (_, idx) {
                          final groups = _buildGroups();
                          int pos = 0;
                          for (final group in groups) {
                            if (idx == pos) return _GroupHeader(group.label);
                            pos++;
                            for (final n in group.items) {
                              if (idx == pos) return _NotificationTile(notification: n, onTap: () => _open(n));
                              pos++;
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
    );
  }
}

class _Group {
  final String label;
  final List<AppNotification> items;
  const _Group(this.label, this.items);
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
  );
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  static final _timeFmt = DateFormat('h:mm a');
  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = _iconFor(n.type);
    final iconColor = _colorFor(n.type);
    final now = DateTime.now();
    final d = n.createdAt.toLocal();
    final timeStr = d.day == now.day ? _timeFmt.format(d) : _dateFmt.format(d);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.isUnread ? cs.primary.withAlpha(isDark ? 20 : 10) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon circle with type color
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconColor.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(n.title, style: TextStyle(fontWeight: n.isUnread ? FontWeight.w700 : FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(timeStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
              if (n.isUnread) ...[
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
              ],
            ]),
            if (n.body != null && n.body!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(n.body!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.4)),
            ],
          ])),
        ]),
      ),
    );
  }

  IconData _iconFor(String t) {
    if (t.startsWith('booking_')) return Icons.event_note_rounded;
    if (t == 'message')           return Icons.chat_bubble_rounded;
    if (t.contains('review'))     return Icons.star_rounded;
    if (t.contains('kyc'))        return Icons.verified_user_rounded;
    if (t.contains('payment'))    return Icons.payments_rounded;
    return Icons.notifications_rounded;
  }

  Color _colorFor(String t) {
    if (t.startsWith('booking_')) return const Color(0xFF6366F1);
    if (t == 'message')           return const Color(0xFF06B6D4);
    if (t.contains('review'))     return const Color(0xFFF59E0B);
    if (t.contains('kyc'))        return const Color(0xFF10B981);
    if (t.contains('payment'))    return const Color(0xFF22C55E);
    return const Color(0xFF6366F1);
  }
}

