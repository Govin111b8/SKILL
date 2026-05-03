import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../api_service.dart';
import 'connectivity_service.dart';

/// Represents a queued offline action that will be synced when online.
class OfflineAction {
  final String id;
  final String type; // 'booking', 'message', 'image_upload'
  final String method; // 'POST', 'PUT'
  final String path;
  final Map<String, dynamic> body;
  final DateTime createdAt;
  int retryCount;

  OfflineAction({
    required this.id,
    required this.type,
    required this.method,
    required this.path,
    required this.body,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'method': method,
    'path': path,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'] as String,
    type: json['type'] as String,
    method: json['method'] as String,
    path: json['path'] as String,
    body: Map<String, dynamic>.from(json['body'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );
}

/// Offline action queue service.
/// Queues actions when offline and auto-syncs them when connectivity resumes.
class OfflineQueueService {
  static const _boxName = 'offline_queue';
  static const _maxRetries = 5;
  static Timer? _syncTimer;
  static bool _syncing = false;

  static final _pendingController = StreamController<int>.broadcast();
  static Stream<int> get pendingCountStream => _pendingController.stream;

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
    // Listen for connectivity changes
    ConnectivityService.instance.statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        syncAll();
      }
    });
    // Periodic retry every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ConnectivityService.instance.isOnline) syncAll();
    });
  }

  /// Add an action to the offline queue
  static Future<void> enqueue(OfflineAction action) async {
    final box = Hive.box<String>(_boxName);
    await box.put(action.id, jsonEncode(action.toJson()));
    _emitCount();
  }

  /// Get all pending actions
  static List<OfflineAction> getPending() {
    final box = Hive.box<String>(_boxName);
    return box.values
        .map((e) => OfflineAction.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get count of pending actions
  static int get pendingCount {
    final box = Hive.box<String>(_boxName);
    return box.length;
  }

  /// Sync all pending actions
  static Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;

    try {
      final pending = getPending();
      for (final action in pending) {
        try {
          if (action.method == 'POST') {
            await ApiService.post(action.path, action.body, auth: true);
          } else if (action.method == 'PUT') {
            await ApiService.put(action.path, action.body, auth: true);
          }
          // Success - remove from queue
          await _remove(action.id);
        } on ApiException catch (e) {
          if (e.statusCode >= 400 && e.statusCode < 500) {
            // Client error - don't retry (invalid data)
            await _remove(action.id);
          } else {
            // Server error - increment retry
            action.retryCount++;
            if (action.retryCount >= _maxRetries) {
              await _remove(action.id);
            } else {
              await _update(action);
            }
          }
        } catch (_) {
          // Network error - stop syncing, will retry later
          break;
        }
      }
    } finally {
      _syncing = false;
      _emitCount();
    }
  }

  static Future<void> _remove(String id) async {
    final box = Hive.box<String>(_boxName);
    await box.delete(id);
  }

  static Future<void> _update(OfflineAction action) async {
    final box = Hive.box<String>(_boxName);
    await box.put(action.id, jsonEncode(action.toJson()));
  }

  static void _emitCount() {
    _pendingController.add(pendingCount);
  }

  static void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
