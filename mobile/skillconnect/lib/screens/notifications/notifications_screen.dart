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
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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
    } else if (t.contains('review') && n.relatedId != null) {
      Navigator.pushNamed(context, '/professional', arguments: n.relatedId!);
    } else if (t.contains('kyc')) {
      // Navigate to KYC screen
      await Navigator.pushNamed(context, '/home');
    }
    _load();
  }

  // Group notifications by date bucket
  List<_Group> _buildGroups() {
    if (_items.isEmpty) return [];
    final now = DateTime.now();
    final todayStart    = DateTime(now.year, now.month, now.day);
    final yesterdayStart= todayStart.subtract(const Duration(days: 1));

    final groups = <String, List<AppNotification>>{};
    for (final n in _items) {
      final d = n.createdAt.toLocal();
      final String key;
      if (d.isAfter(todayStart))      key = 'Today';
      else if (d.isAfter(yesterdayStart)) key = 'Yesterday';
      else                             key = 'Earlier';
      groups.putIfAbsent(key, () => []).add(n);
    }
    final order = ['Today', 'Yesterday', 'Earlier'];
    return order.where((k) => groups.containsKey(k)).map((k) => _Group(k, groups[k]!)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((n) => n.isUnread).length;
    final groups = _buildGroups();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PremiumAppBar(
        title: 'Notifications',
        actions: [
          if (!_loading && _items.any((n) => n.isUnread))
            TextButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                try { await NotificationsService.markAllRead(); } catch (_) {}
                _load();
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const PremiumLoadingList(itemCount: 6, itemHeight: 96)
              : _error != null
                  ? PremiumEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Connection error',
                      subtitle: 'Could not load notifications. Pull down to retry.',
                      actionLabel: 'Try again',
                      onAction: () { _load(); },
                      gradient: const [AppColors.error, AppColors.warning],
                    )
                  : _items.isEmpty
                      ? const PremiumEmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'All caught up!',
                          subtitle: 'No new notifications. We'll let you know when something happens.',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxxl),
                            children: [
                              PremiumHeroHeader(
                                title: unreadCount > 0 ? '$unreadCount unread alerts' : 'Inbox cleared',
                                subtitle: unreadCount > 0
                                    ? 'Bookings, chats, reviews, and KYC updates in one premium feed.'
                                    : 'Everything important is already checked off.',
                                icon: Icons.notifications_active_rounded,
                                chips: [
                                  PremiumStatChip(
                                    label: '${_items.length} total',
                                    icon: Icons.inbox_rounded,
                                    color: Colors.white,
                                  ),
                                  PremiumStatChip(
                                    label: unreadCount > 0 ? '$unreadCount unread' : 'All read',
                                    icon: unreadCount > 0 ? Icons.brightness_1_rounded : Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              for (final group in groups) ...[
                                _GroupHeader(group.label),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  child: Column(
                                    children: group.items
                                        .map((n) => Padding(
                                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                              child: _NotificationTile(notification: n, onTap: () => _open(n)),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
  const _GroupHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.1),
        ),
      ],
    ),
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
    final icon = _iconFor(n.type);
    final iconColor = _colorFor(n.type);
    final now = DateTime.now();
    final d = n.createdAt.toLocal();
    final timeStr = d.day == now.day ? _timeFmt.format(d) : _dateFmt.format(d);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => false,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.warmGradient),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Icon(Icons.done_all_rounded, color: Colors.white),
      ),
      child: PremiumGlassCard(
        onTap: onTap,
        gradient: n.isUnread
            ? [AppColors.accent.withAlpha(18), Colors.white.withAlpha(225)]
            : [Colors.white.withAlpha(215), Colors.white.withAlpha(170)],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(14),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isUnread ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      if (n.isUnread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.sm(AppColors.accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (n.body != null && n.body!.isNotEmpty)
                    Text(
                      n.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
