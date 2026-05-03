import 'dart:math';

/// Network quality simulation utility for testing.
/// Simulates 2G, 3G, 4G, and offline conditions.
/// Only active in debug/development mode.
///
/// Usage:
///   NetworkSimulator.instance.setCondition(NetworkCondition.slow2g);
///   // All API calls will now be delayed
///   NetworkSimulator.instance.reset();
class NetworkSimulator {
  NetworkSimulator._();
  static final NetworkSimulator instance = NetworkSimulator._();

  NetworkCondition _condition = NetworkCondition.normal;
  NetworkCondition get condition => _condition;

  bool _enabled = false;
  bool get enabled => _enabled;

  final _random = Random();

  /// Set network condition (only works in debug mode)
  void setCondition(NetworkCondition condition) {
    assert(() {
      _condition = condition;
      _enabled = condition != NetworkCondition.normal;
      return true;
    }());
  }

  /// Reset to normal network
  void reset() {
    _condition = NetworkCondition.normal;
    _enabled = false;
  }

  /// Simulate network delay — call before API requests in debug mode
  Future<void> simulateDelay() async {
    if (!_enabled) return;

    switch (_condition) {
      case NetworkCondition.slow2g:
        // 2G: 1500-5000ms delay, 30% failure rate
        await Future.delayed(Duration(milliseconds: 1500 + _random.nextInt(3500)));
        if (_random.nextDouble() < 0.3) {
          throw NetworkSimulationException('Simulated 2G network timeout');
        }
        break;
      case NetworkCondition.slow3g:
        // 3G: 500-2000ms delay, 10% failure rate
        await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)));
        if (_random.nextDouble() < 0.1) {
          throw NetworkSimulationException('Simulated 3G network error');
        }
        break;
      case NetworkCondition.good4g:
        // 4G: 50-200ms delay, 2% failure rate
        await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(150)));
        if (_random.nextDouble() < 0.02) {
          throw NetworkSimulationException('Simulated 4G network blip');
        }
        break;
      case NetworkCondition.offline:
        throw NetworkSimulationException('No network connection (simulated offline)');
      case NetworkCondition.flaky:
        // Flaky: random delays + 40% failure
        await Future.delayed(Duration(milliseconds: _random.nextInt(4000)));
        if (_random.nextDouble() < 0.4) {
          throw NetworkSimulationException('Simulated flaky network');
        }
        break;
      case NetworkCondition.normal:
        break;
    }
  }

  /// Get simulated bandwidth limit in bytes/sec
  int get bandwidthBytesPerSec {
    switch (_condition) {
      case NetworkCondition.slow2g:
        return 15000; // ~15 KB/s (2G EDGE)
      case NetworkCondition.slow3g:
        return 200000; // ~200 KB/s (3G)
      case NetworkCondition.good4g:
        return 5000000; // ~5 MB/s (4G)
      case NetworkCondition.offline:
        return 0;
      case NetworkCondition.flaky:
        return 50000 + _random.nextInt(200000);
      case NetworkCondition.normal:
        return -1; // No limit
    }
  }
}

enum NetworkCondition {
  normal,    // No simulation
  slow2g,    // EDGE-like: very slow, frequent failures
  slow3g,    // Moderate: some delay, occasional failures
  good4g,    // Fast: minimal delay
  offline,   // Complete offline
  flaky,     // Unpredictable: random delays and failures
}

class NetworkSimulationException implements Exception {
  final String message;
  NetworkSimulationException(this.message);
  @override
  String toString() => 'NetworkSimulationException: $message';
}
