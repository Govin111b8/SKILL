import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

/// Singleton WebSocket client for real-time push.
/// Reconnects automatically with exponential backoff.
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

  /// Stream of events of a specific type
  Stream<Map<String, dynamic>> on(String type) =>
      stream.where((e) => e['type'] == type);

  bool get isConnected => _channel != null;

  void connect(String token) {
    // Always reset disposed flag when explicitly reconnecting
    _disposed = false;
    if (_token == token && _channel != null) return;
    _token = token;
    _backoffMs = 1000;
    _reconnectTimer?.cancel();
    _open();
  }

  void _open() {
    if (_disposed || _token == null) return;
    try {
      final url = _wsUrl(_token!);
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(data);
            _backoffMs = 1000; // reset on successful traffic
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
      } catch (_) {}
    });
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
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
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  String _wsUrl(String token) {
    if (kIsWeb) {
      // Same-origin: derive from current location
      final loc = Uri.base;
      final scheme = loc.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${loc.host}${loc.hasPort ? ':${loc.port}' : ''}/ws?token=$token';
    }
    // Mobile: use codespace public URL (https → wss)
    final base = Uri.parse(ApiConfig.androidBaseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${base.host}${base.hasPort ? ':${base.port}' : ''}/ws?token=$token';
  }
}
