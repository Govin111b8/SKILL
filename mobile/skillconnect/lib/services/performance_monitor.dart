import 'dart:async';

/// Performance monitoring service that tracks:
/// - Cold start time
/// - Screen render times
/// - API response times
/// - Frame drop detection
/// - Memory usage on low-end devices
class PerformanceMonitor {
  PerformanceMonitor._();
  static final PerformanceMonitor instance = PerformanceMonitor._();

  DateTime? _appStartTime;
  DateTime? _firstFrameTime;
  final Map<String, List<int>> _screenLoadTimes = {};
  final Map<String, List<int>> _apiResponseTimes = {};
  final List<Map<String, dynamic>> _performanceEvents = [];

  /// Call at very start of main()
  void markAppStart() {
    _appStartTime = DateTime.now();
  }

  /// Call when first frame is rendered (after splash)
  void markFirstFrame() {
    _firstFrameTime = DateTime.now();
    if (_appStartTime != null) {
      final coldStartMs = _firstFrameTime!.difference(_appStartTime!).inMilliseconds;
      _performanceEvents.add({
        'type': 'cold_start',
        'duration_ms': coldStartMs,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Track screen load time
  Stopwatch startScreenLoad(String screenName) {
    final sw = Stopwatch()..start();
    // Return stopwatch — caller should call endScreenLoad when loaded
    return sw;
  }

  void endScreenLoad(String screenName, Stopwatch stopwatch) {
    stopwatch.stop();
    final ms = stopwatch.elapsedMilliseconds;
    _screenLoadTimes.putIfAbsent(screenName, () => []);
    _screenLoadTimes[screenName]!.add(ms);

    // Keep last 20 measurements per screen
    if (_screenLoadTimes[screenName]!.length > 20) {
      _screenLoadTimes[screenName]!.removeAt(0);
    }

    _performanceEvents.add({
      'type': 'screen_load',
      'screen': screenName,
      'duration_ms': ms,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track API call duration
  void trackApiCall(String endpoint, int durationMs, {bool success = true}) {
    _apiResponseTimes.putIfAbsent(endpoint, () => []);
    _apiResponseTimes[endpoint]!.add(durationMs);

    if (_apiResponseTimes[endpoint]!.length > 50) {
      _apiResponseTimes[endpoint]!.removeAt(0);
    }

    // Flag slow APIs (> 3 seconds)
    if (durationMs > 3000) {
      _performanceEvents.add({
        'type': 'slow_api',
        'endpoint': endpoint,
        'duration_ms': durationMs,
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get cold start time in milliseconds
  int? get coldStartMs {
    if (_appStartTime == null || _firstFrameTime == null) return null;
    return _firstFrameTime!.difference(_appStartTime!).inMilliseconds;
  }

  /// Get average screen load time
  double? averageScreenLoadMs(String screenName) {
    final times = _screenLoadTimes[screenName];
    if (times == null || times.isEmpty) return null;
    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get average API response time
  double? averageApiResponseMs(String endpoint) {
    final times = _apiResponseTimes[endpoint];
    if (times == null || times.isEmpty) return null;
    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get all performance metrics as a report
  Map<String, dynamic> getReport() {
    return {
      'cold_start_ms': coldStartMs,
      'screen_loads': _screenLoadTimes.map(
        (k, v) => MapEntry(k, {
          'avg_ms': v.isEmpty ? 0 : (v.reduce((a, b) => a + b) / v.length).round(),
          'max_ms': v.isEmpty ? 0 : v.reduce((a, b) => a > b ? a : b),
          'count': v.length,
        }),
      ),
      'api_responses': _apiResponseTimes.map(
        (k, v) => MapEntry(k, {
          'avg_ms': v.isEmpty ? 0 : (v.reduce((a, b) => a + b) / v.length).round(),
          'max_ms': v.isEmpty ? 0 : v.reduce((a, b) => a > b ? a : b),
          'count': v.length,
        }),
      ),
      'events_count': _performanceEvents.length,
    };
  }

  /// Get performance events for batch upload
  List<Map<String, dynamic>> getAndClearEvents() {
    final events = List<Map<String, dynamic>>.from(_performanceEvents);
    _performanceEvents.clear();
    return events;
  }
}
