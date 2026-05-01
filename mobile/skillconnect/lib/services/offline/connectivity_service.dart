import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Network status enum
enum NetworkStatus { online, slow, offline }

/// Service that monitors network connectivity and provides status updates.
/// Used for connectivity-aware UI (banners, disabling animations, etc.)
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkStatus _status = NetworkStatus.online;
  NetworkStatus get status => _status;
  bool get isOnline => _status != NetworkStatus.offline;
  bool get isSlow => _status == NetworkStatus.slow;

  final _statusController = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Whether to use low-data mode (disable animations, compress images)
  bool _lowDataMode = false;
  bool get lowDataMode => _lowDataMode;
  set lowDataMode(bool value) {
    _lowDataMode = value;
    notifyListeners();
  }

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    NetworkStatus newStatus;
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      newStatus = NetworkStatus.offline;
    } else if (results.contains(ConnectivityResult.mobile)) {
      // Mobile data - may be slow
      newStatus = NetworkStatus.online;
    } else {
      newStatus = NetworkStatus.online;
    }

    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
      // Auto-enable low data mode when offline
      if (_status == NetworkStatus.offline) {
        _lowDataMode = true;
      }
      notifyListeners();
    }
  }

  /// Mark network as slow (called when request latency > threshold)
  void markSlow() {
    if (_status == NetworkStatus.online) {
      _status = NetworkStatus.slow;
      _statusController.add(_status);
      notifyListeners();
    }
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    super.dispose();
  }
}
