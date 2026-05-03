import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
import '../../services/upload_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/voice/voice_note_widget.dart';

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
  StreamSubscription? _statusSub;
  String _myId = '';
  bool _otherTyping = false;
  Timer? _typingTimer;
  bool _iAmTyping = false;
  String? _otherUserId; // resolved user ID of the other party

  @override
  void initState() {
    super.initState();
    _myId = (context.read<AuthService>().user?['id'] ?? '').toString();
    _ctrl.addListener(_onTextChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _statusSub?.cancel();
    _typingTimer?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _scroll.dispose();
    // Send typing stopped
    if (_iAmTyping && _threadId != null && _otherUserId != null) {
      RealtimeService.instance.sendTyping(threadId: _threadId!, toUserId: _otherUserId!, typing: false);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (_threadId == null || _otherUserId == null) return;
    if (_ctrl.text.isNotEmpty && !_iAmTyping) {
      _iAmTyping = true;
      RealtimeService.instance.sendTyping(threadId: _threadId!, toUserId: _otherUserId!, typing: true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_iAmTyping) {
        _iAmTyping = false;
        RealtimeService.instance.sendTyping(threadId: _threadId!, toUserId: _otherUserId!, typing: false);
      }
    });
  }

  Future<void> _bootstrap() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      if (_threadId == null) {
        if (widget.threadId != null) {
          _threadId = widget.threadId;
        } else if (widget.otherUserId != null && widget.openWith != null) {
          final t = widget.openWith == 'customer'
              ? await MessagingService.openThread(customerId: widget.otherUserId!, bookingId: widget.bookingId)
              : await MessagingService.openThread(professionalId: widget.otherUserId!, bookingId: widget.bookingId);
          _threadId = t.id;
          // Resolve other user ID from thread
          _otherUserId = widget.otherUserId;
        }
      }
      if (_threadId != null) {
        _messages = await MessagingService.listMessages(_threadId!);
        // Send read receipt immediately
        RealtimeService.instance.sendReadReceipt(_threadId!);
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

    // Handle typing indicators
    if (t == 'typing') {
      if (ev['threadId']?.toString() == _threadId && ev['userId']?.toString() != _myId) {
        setState(() => _otherTyping = ev['typing'] == true);
        // Auto-clear typing after 5s (in case stop event is missed)
        if (_otherTyping) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _otherTyping) setState(() => _otherTyping = false);
          });
        }
      }
      return;
    }

    // Handle read receipts — mark all sent messages as read
    if (t == 'messages_read') {
      if (ev['threadId']?.toString() == _threadId) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.senderId == _myId && m.readAt == null) {
              return ChatMessage(
                id: m.id, threadId: m.threadId, senderId: m.senderId,
                body: m.body, messageType: m.messageType, isSystem: m.isSystem,
                readAt: DateTime.now(), createdAt: m.createdAt, senderName: m.senderName,
              );
            }
            return m;
          }).toList();
        });
      }
      return;
    }

    // Handle new message
    if (t != 'message' && t != 'new_message') return;
    final msg = ev['message'] ?? ev['data'] ?? ev;
    if (msg is! Map) return;
    if (msg['thread_id']?.toString() != _threadId) return;
    final m = ChatMessage.fromJson(Map<String, dynamic>.from(msg));
    if (_messages.any((x) => x.id == m.id)) return;
    setState(() {
      _messages = [..._messages, m];
      _otherTyping = false; // they sent a message, so they stopped typing
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    // Send read receipt since we're looking at the chat
    if (m.senderId != _myId) {
      RealtimeService.instance.sendReadReceipt(_threadId!);
    }
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
    // Stop typing
    _typingTimer?.cancel();
    if (_iAmTyping && _otherUserId != null) {
      _iAmTyping = false;
      RealtimeService.instance.sendTyping(threadId: _threadId!, toUserId: _otherUserId!, typing: false);
    }
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

  Future<void> _sendVoiceNote(String filePath, Duration duration) async {
    if (_threadId == null) return;
    setState(() => _sending = true);
    try {
      // Send voice note as a message with audio indicator
      final durationStr = '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
      final m = await MessagingService.sendMessage(_threadId!, '🎤 Voice note ($durationStr)');
      if (!_messages.any((x) => x.id == m.id)) {
        setState(() => _messages = [..._messages, m]);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _sendImage() async {
    if (_threadId == null) return;
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
    if (result == null) return;

    setState(() => _sending = true);
    try {
      // Upload image
      final imageUrl = await UploadService.uploadFile(result.path, 'chat_images');
      // Send as image message
      final m = await MessagingService.sendMessage(_threadId!, '📷 Image', imageUrl: imageUrl);
      if (!_messages.any((x) => x.id == m.id)) {
        setState(() => _messages = [..._messages, m]);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      AnalyticsService.instance.track(AnalyticsEvent.imageSent);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image send failed: $e'), backgroundColor: Colors.red));
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
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.otherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
              if (_otherTyping)
                Text('typing...', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w500)),
            ],
          )),
        ]),
        actions: [
          StreamBuilder<ConnectionStatus>(
            stream: RealtimeService.instance.statusStream,
            initialData: RealtimeService.instance.status,
            builder: (_, snap) {
              final s = snap.data ?? ConnectionStatus.disconnected;
              if (s == ConnectionStatus.connected) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  s == ConnectionStatus.connecting ? Icons.sync : Icons.cloud_off,
                  size: 18,
                  color: s == ConnectionStatus.connecting ? Colors.orange : Colors.red,
                ),
              );
            },
          ),
        ],
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
                      // Image attach button
                      IconButton(
                        onPressed: _sending ? null : _sendImage,
                        icon: Icon(Icons.image_outlined, color: cs.onSurfaceVariant, size: 22),
                        tooltip: 'Send image',
                      ),
                      // Voice note recorder
                      VoiceNoteRecorder(
                        onRecordingComplete: (filePath, duration) {
                          // Send voice note as message with audio attachment
                          _sendVoiceNote(filePath, duration);
                        },
                      ),
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

    // System messages: centered, muted style
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(180),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

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
