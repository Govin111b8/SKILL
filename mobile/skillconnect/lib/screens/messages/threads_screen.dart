import 'dart:async' as dart_async;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
import 'chat_screen.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class ThreadsScreen extends StatefulWidget {
  const ThreadsScreen({super.key});
  @override
  State<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends State<ThreadsScreen> {
  List<MessageThread> _items = [];
  bool _loading = true;
  String? _error;
  dart_async.StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _load();
    _wsSub = RealtimeService.instance.stream.listen((event) {
      if (!mounted) return;
      final t = event['type']?.toString() ?? '';
      if (t == 'message' || t == 'new_message') _load();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await MessagingService.listThreads();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isPro = auth.isProfessional;
    final myUserId = auth.user?['id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: AppShadows.lg(AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(28),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: Colors.white.withAlpha(40)),
                              ),
                              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Messages',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              isPro
                                  ? 'Keep every client conversation warm, quick, and professional.'
                                  : 'Talk to professionals, share details, and book with confidence.',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                PremiumStatChip(
                                  label: '${_items.length} threads',
                                  icon: Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                ),
                                PremiumStatChip(
                                  label: '${_items.fold<int>(0, (sum, t) => sum + (isPro ? t.proUnread : t.customerUnread))} unread',
                                  icon: Icons.mark_chat_unread_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(24),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const PremiumLoadingList(itemCount: 5, itemHeight: 108)
                    : _error != null
                        ? PremiumEmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Unable to load messages',
                            subtitle: _error!,
                            actionLabel: 'Retry',
                            onAction: _load,
                            gradient: AppColors.warmGradient,
                          )
                        : _items.isEmpty
                            ? const _EmptyView()
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: AppColors.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    AppSpacing.xxxl,
                                  ),
                                  itemCount: _items.length,
                                  itemBuilder: (_, i) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                    child: _ThreadTile(
                                      thread: _items[i],
                                      isPro: isPro,
                                      myUserId: myUserId,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              threadId: _items[i].id,
                                              otherName: _items[i].otherName ?? 'Chat',
                                              bookingId: _items[i].bookingId,
                                            ),
                                          ),
                                        );
                                        _load();
                                      },
                                    ),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final MessageThread thread;
  final bool isPro;
  final String myUserId;
  final VoidCallback onTap;
  const _ThreadTile({required this.thread, required this.isPro, required this.myUserId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = isPro ? thread.proUnread : thread.customerUnread;
    final name = thread.otherName ?? 'Unknown';
    final preview = thread.lastMessage ?? 'Tap to start chatting';
    final hasUnread = unread > 0;
    final hue = name.codeUnits.fold(0, (a, b) => a + b) % 360;
    final avatarColor = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.55).toColor();

    return PremiumGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [avatarColor.withAlpha(220), avatarColor],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.md(avatarColor.withAlpha(120)),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.surfaceDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (thread.lastMessageAt != null)
                      Text(
                        _relativeTime(thread.lastMessageAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? AppColors.primary : Colors.grey.shade500,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnread ? const Color(0xFF334155) : const Color(0xFF64748B),
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (thread.bookingId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(16),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'Booking chat',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '$unread new',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF94A3B8)),
                          SizedBox(width: 4),
                          Text(
                            'Caught up',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('MMM d').format(dt.toLocal());
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => const PremiumEmptyState(
        icon: Icons.mark_chat_read_rounded,
        title: 'No conversations yet',
        subtitle: 'Messages with customers and professionals will appear here once a conversation begins.',
      );
}
