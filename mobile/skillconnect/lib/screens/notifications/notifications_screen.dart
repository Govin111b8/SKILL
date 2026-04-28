import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    RealtimeService.instance.stream.listen((e) { if (mounted) _load(); });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        TextButton(
          onPressed: _items.any((n) => n.isUnread)
              ? () async {
                  try { await NotificationsService.markAllRead(); } catch (_) {}
                  _load();
                }
              : null,
          child: const Text('Mark all read'),
        ),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _items.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ])))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          final cs = Theme.of(context).colorScheme;
                          final icon = _iconFor(n.type);
                          return ListTile(
                            tileColor: n.isUnread ? cs.primary.withValues(alpha: 0.06) : null,
                            onTap: () => _open(n),
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Icon(icon, color: cs.primary, size: 20),
                            ),
                            title: Text(n.title, style: TextStyle(fontWeight: n.isUnread ? FontWeight.bold : FontWeight.w500)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (n.body != null) Text(n.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(DateFormat('MMM d, h:mm a').format(n.createdAt.toLocal()),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ]),
                            trailing: n.isUnread ? Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)) : null,
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _iconFor(String t) {
    if (t.startsWith('booking_')) return Icons.event_note;
    if (t == 'message') return Icons.chat_bubble_outline;
    if (t.contains('review')) return Icons.star_outline;
    if (t.contains('kyc')) return Icons.verified_user_outlined;
    return Icons.notifications_outlined;
  }
}
