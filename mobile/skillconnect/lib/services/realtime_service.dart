import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

/// Connection status for the real-time service
enum ConnectionStatus { disconnected, connecting, connected }

/// Production-ready WebSocket client for real-time push.
/// Features: auto-reconnect, heartbeat, typing indicators, read receipts, presence.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  WebSocketChannel? _channel;
  String? _token;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _backoffMs = 1000;
  bool _disposed = false;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  /// Stream of events of a specific type
  Stream<Map<String, dynamic>> on(String type) =>
      stream.where((e) => e['type'] == type);

  bool get isConnected => _status == ConnectionStatus.connected;

  void connect(String token) {
    _disposed = false;
    if (_token == token && _channel != null) return;
    _token = token;
    _backoffMs = 1000;
    _reconnectTimer?.cancel();
    _setStatus(ConnectionStatus.connecting);
    _open();
  }

  void _setStatus(ConnectionStatus s) {
    if (_status == s) return;
    _status = s;
    _statusController.add(s);
  }

  void _open() {
    if (_disposed || _token == null) return;
    _setStatus(ConnectionStatus.connecting);
    try {
      final url = _wsUrl(_token!);
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            if (data['type'] == 'hello') {
              _setStatus(ConnectionStatus.connected);
            }
            if (data['type'] == 'pong') {
              _backoffMs = 1000;
              return; // Don't emit pong to listeners
            }
            _controller.add(data);
            _backoffMs = 1000;
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
      _startPing();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    _setStatus(ConnectionStatus.disconnected);
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
    if (_disposed || _token == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _backoffMs), _open);
    _backoffMs = (_backoffMs * 2).clamp(1000, 30000);
  }

  void disconnect() {
    _disposed = true;
    _token = null;
    _backoffMs = 1000;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  // ─── Real-time actions ─────────────────────────────────────

  /// Send typing indicator to another user
  void sendTyping({required String threadId, required String toUserId, bool typing = true}) {
    _send({'type': 'typing', 'threadId': threadId, 'to': toUserId, 'typing': typing});
  }

  /// Send read receipt for a thread (marks all messages in thread as read)
  void sendReadReceipt(String threadId) {
    _send({'type': 'read_receipt', 'threadId': threadId});
  }

  /// Report presence status (online/away/background)
  void sendPresence(String status) {
    _send({'type': 'presence', 'status': status});
  }

  void _send(Map<String, dynamic> data) {
    if (_channel == null || _status != ConnectionStatus.connected) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  String _wsUrl(String token) {
    if (kIsWeb) {
      final loc = Uri.base;
      final scheme = loc.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${loc.host}${loc.hasPort ? ':${loc.port}' : ''}/ws?token=$token';
    }
    final base = Uri.parse(ApiConfig.androidBaseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${base.host}${base.hasPort ? ':${base.port}' : ''}/ws?token=$token';
  }
}
