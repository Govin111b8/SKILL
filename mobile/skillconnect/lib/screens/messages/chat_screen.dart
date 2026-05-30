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
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
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
                id: m.id,
                threadId: m.threadId,
                senderId: m.senderId,
                body: m.body,
                messageType: m.messageType,
                isSystem: m.isSystem,
                readAt: DateTime.now(),
                createdAt: m.createdAt,
                senderName: m.senderName,
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        colors: const [Color(0xFFF8FAFF), Color(0xFFF3F7FF), Color(0xFFEEF2FF)],
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: AppShadows.lg(AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withAlpha(28), Colors.white.withAlpha(14)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _otherTyping ? AppColors.warning : AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _otherTyping ? 'typing…' : 'online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withAlpha(220),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Icon(
                              s == ConnectionStatus.connecting ? Icons.sync : Icons.cloud_off,
                              size: 18,
                              color: s == ConnectionStatus.connecting ? Colors.amber : Colors.red.shade200,
                            ),
                          );
                        },
                      ),
                      _CircleIconButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const PremiumLoadingList(itemCount: 7, itemHeight: 72)
                    : _error != null
                        ? PremiumEmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Unable to open chat',
                            subtitle: _error!,
                            actionLabel: 'Retry',
                            onAction: _bootstrap,
                            gradient: AppColors.warmGradient,
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: _messages.isEmpty
                                    ? const PremiumEmptyState(
                                        icon: Icons.waving_hand_rounded,
                                        title: 'Say hello',
                                        subtitle: 'Start the conversation with a quick note, image, or voice message.',
                                      )
                                    : ListView.builder(
                                        controller: _scroll,
                                        padding: const EdgeInsets.fromLTRB(
                                          AppSpacing.lg,
                                          AppSpacing.sm,
                                          AppSpacing.lg,
                                          AppSpacing.xl,
                                        ),
                                        itemCount: _messages.length,
                                        itemBuilder: (_, i) => _Bubble(
                                          message: _messages[i],
                                          isMe: _messages[i].senderId == _myId,
                                        ),
                                      ),
                              ),
                              SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                  ),
                                  child: PremiumGlassCard(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.sm,
                                    ),
                                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: _sending ? null : _sendImage,
                                          icon: Icon(Icons.image_outlined, color: Colors.grey.shade600, size: 22),
                                          tooltip: 'Send image',
                                        ),
                                        VoiceNoteRecorder(
                                          onRecordingComplete: (filePath, duration) {
                                            _sendVoiceNote(filePath, duration);
                                          },
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(160),
                                              borderRadius: BorderRadius.circular(AppRadius.xl),
                                            ),
                                            child: TextField(
                                              controller: _ctrl,
                                              minLines: 1,
                                              maxLines: 4,
                                              textCapitalization: TextCapitalization.sentences,
                                              decoration: const InputDecoration(
                                                hintText: 'Type a message...',
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                border: InputBorder.none,
                                              ),
                                              onSubmitted: (_) => _send(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        GestureDetector(
                                          onTap: _sending ? null : _send,
                                          child: AnimatedContainer(
                                            duration: AppDurations.normal,
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                              shape: BoxShape.circle,
                                              boxShadow: AppShadows.md(AppColors.primary),
                                            ),
                                            child: _sending
                                                ? const Padding(
                                                    padding: EdgeInsets.all(14),
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  )
                                                : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // System messages: centered, muted style
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(10),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            message.body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.xl),
      topRight: const Radius.circular(AppRadius.xl),
      bottomLeft: Radius.circular(isMe ? AppRadius.xl : AppRadius.sm),
      bottomRight: Radius.circular(isMe ? AppRadius.sm : AppRadius.xl),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        child: Container(
          margin: EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.sm,
            left: isMe ? AppSpacing.huge : 0,
            right: isMe ? 0 : AppSpacing.huge,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isMe ? const LinearGradient(colors: [AppColors.primary, AppColors.accent]) : null,
                color: isMe ? null : Colors.white.withAlpha(210),
                borderRadius: radius,
                boxShadow: isMe ? AppShadows.md(AppColors.primary.withAlpha(120)) : AppShadows.sm(Colors.black12),
                border: isMe ? null : Border.all(color: Colors.white.withAlpha(180)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.network(
                          message.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            alignment: Alignment.center,
                            color: Colors.black.withAlpha(12),
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Text(
                      message.body,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 14.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(message.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white.withAlpha(190) : Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.readAt != null ? Icons.done_all : Icons.done,
                            size: 13,
                            color: message.readAt != null ? Colors.lightBlueAccent : Colors.white.withAlpha(170),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
