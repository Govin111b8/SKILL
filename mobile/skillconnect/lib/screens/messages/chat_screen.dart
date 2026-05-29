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
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withAlpha(40),
                    child: Text(
                      widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        if (_otherTyping)
                          const Text('typing...', style: TextStyle(fontSize: 12, color: Colors.white70))
                        else
                          const Text('online', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  StreamBuilder<ConnectionStatus>(
                    stream: RealtimeService.instance.statusStream,
                    initialData: RealtimeService.instance.status,
                    builder: (_, snap) {
                      final s = snap.data ?? ConnectionStatus.disconnected;
                      if (s == ConnectionStatus.connected) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          s == ConnectionStatus.connecting ? Icons.sync : Icons.cloud_off,
                          size: 18,
                          color: s == ConnectionStatus.connecting ? Colors.amber : Colors.red.shade200,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withAlpha(15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(height: 16),
                              Text('Say hello 👋', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _Bubble(message: _messages[i], isMe: _messages[i].senderId == _myId),
                        )),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, -2))],
                      ),
                      child: Row(children: [
                        IconButton(
                          onPressed: _sending ? null : _sendImage,
                          icon: Icon(Icons.image_outlined, color: Colors.grey.shade500, size: 22),
                          tooltip: 'Send image',
                        ),
                        VoiceNoteRecorder(
                          onRecordingComplete: (filePath, duration) {
                            _sendVoiceNote(filePath, duration);
                          },
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FA),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _ctrl,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _sending ? null : _send,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                              shape: BoxShape.circle,
                            ),
                            child: _sending
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ]),
                    ),
                  ),
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
            color: Colors.black.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? const Color(0xFF6366F1).withAlpha(50)
                    : Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail if it's an image message
              if (message.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                message.body,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 14.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white.withAlpha(180) : Colors.grey.shade400,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.readAt != null ? Icons.done_all : Icons.done,
                      size: 13,
                      color: message.readAt != null ? Colors.lightBlueAccent : Colors.white.withAlpha(160),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
