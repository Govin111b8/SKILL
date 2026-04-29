import 'dart:async' as dart_async;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
import 'chat_screen.dart';

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
    setState(() { _loading = true; _error = null; });
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
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _items.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                        itemBuilder: (_, i) => _ThreadTile(
                          thread: _items[i],
                          isPro: isPro,
                          myUserId: myUserId,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                threadId: _items[i].id,
                                otherName: _items[i].otherName ?? 'Chat',
                                bookingId: _items[i].bookingId,
                              ),
                            ));
                            _load();
                          },
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
    final cs = Theme.of(context).colorScheme;
    final unread = isPro ? thread.proUnread : thread.customerUnread;
    final name = thread.otherName ?? 'Unknown';
    final preview = thread.lastMessage ?? 'Tap to start chatting';
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: cs.primaryContainer,
        child: Text(name[0].toUpperCase(), style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
      ),
      title: Row(children: [
        Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold))),
        if (thread.lastMessageAt != null)
          Text(_relativeTime(thread.lastMessageAt!),
              style: TextStyle(fontSize: 11, color: unread > 0 ? cs.primary : Colors.grey.shade600)),
      ]),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Expanded(child: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: unread > 0 ? Colors.black87 : Colors.grey.shade600,
                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal))),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ]),
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
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      const Text('No conversations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Messages with customers/professionals will appear here.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
    ]),
  ));
}
