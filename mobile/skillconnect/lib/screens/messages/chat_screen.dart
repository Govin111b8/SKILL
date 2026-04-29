import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';

class ChatScreen extends StatefulWidget {
  /// Provide either threadId OR (otherUserId + openWith) to bootstrap a thread.
  final String? threadId;
  final String otherName;
  final String? bookingId;
  final String? otherUserId;
  // When opening fresh: 'professional' means I'm customer talking to a pro;
  // 'customer' means I'm pro talking to a customer.
  final String? openWith;

  const ChatScreen({
    super.key,
    this.threadId,
    required this.otherName,
    this.bookingId,
    this.otherUserId,
    this.openWith,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _threadId;
  List<ChatMessage> _messages = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  StreamSubscription? _wsSub;
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _myId = (context.read<AuthService>().user?['id'] ?? '').toString();
    _bootstrap();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      if (_threadId == null) {
        if (widget.threadId != null) {
          _threadId = widget.threadId;
        } else if (widget.otherUserId != null && widget.openWith != null) {
          // 'professional' → I'm customer requesting thread with a pro USER (we need professional_id, not user_id, ideally)
          // For booking-driven flow, otherUserId is the pro/customer USER. We open thread by customer_id or by professional_id depending.
          final t = widget.openWith == 'customer'
              ? await MessagingService.openThread(customerId: widget.otherUserId!, bookingId: widget.bookingId)
              : await MessagingService.openThread(professionalId: widget.otherUserId!, bookingId: widget.bookingId);
          _threadId = t.id;
        }
      }
      if (_threadId != null) {
        _messages = await MessagingService.listMessages(_threadId!);
      }
      _wsSub = RealtimeService.instance.stream.listen(_onWs);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onWs(Map<String, dynamic> ev) {
    final t = ev['type']?.toString();
    if (t != 'message' && t != 'new_message') return;
    final msg = ev['message'] ?? ev['data'] ?? ev;
    if (msg is! Map) return;
    if (msg['thread_id']?.toString() != _threadId) return;
    final m = ChatMessage.fromJson(Map<String, dynamic>.from(msg));
    if (_messages.any((x) => x.id == m.id)) return;
    setState(() => _messages = [..._messages, m]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _threadId == null || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      final m = await MessagingService.sendMessage(_threadId!, text);
      if (!_messages.any((x) => x.id == m.id)) {
        setState(() => _messages = [..._messages, m]);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e'), backgroundColor: Colors.red));
      _ctrl.text = text;
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Text(widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : '?', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.otherName, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(onPressed: _bootstrap, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                ])))
              : Column(children: [
                  Expanded(child: _messages.isEmpty
                      ? Center(child: Text('Say hello 👋', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _Bubble(message: _messages[i], isMe: _messages[i].senderId == _myId),
                        )),
                  SafeArea(top: false, child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                    ),
                    child: Row(children: [
                      Expanded(child: TextField(
                        controller: _ctrl,
                        minLines: 1, maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Type a message...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        onSubmitted: (_) => _send(),
                      )),
                      IconButton(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.send, color: cs.primary),
                      ),
                    ]),
                  )),
                ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: isMe ? null : Border.all(color: cs.outlineVariant),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message.body, style: TextStyle(color: isMe ? Colors.white : cs.onSurface, fontSize: 14.5)),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(DateFormat('h:mm a').format(message.createdAt.toLocal()),
                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : cs.onSurfaceVariant)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(message.readAt != null ? Icons.done_all : Icons.done, size: 12,
                    color: message.readAt != null ? Colors.lightBlueAccent : Colors.white70),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
