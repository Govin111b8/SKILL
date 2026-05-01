import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Event types tracked across the app
enum AnalyticsEvent {
  appOpen,
  appBackground,
  appResume,
  screenView,
  searchStarted,
  searchCompleted,
  searchNoResults,
  bookingStarted,
  bookingStepCompleted,
  bookingConfirmed,
  bookingCancelled,
  bookingDropOff,
  paymentStarted,
  paymentCompleted,
  paymentFailed,
  chatOpened,
  chatMessageSent,
  voiceNoteSent,
  imageSent,
  emergencyBooking,
  instantQuoteSubmitted,
  providerProfileViewed,
  providerCalled,
  rebookingUsed,
  notificationTapped,
  locationPermissionGranted,
  locationPermissionDenied,
  offlineActionQueued,
  offlineActionSynced,
}

/// Mobile analytics service for tracking user behavior,
/// funnel drop-offs, and performance metrics.
///
/// Tracks locally when offline, syncs in batches when online.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const _batchKey = 'analytics_batch';
  static const _sessionKey = 'analytics_session_id';
  static const _maxBatchSize = 50;
  static const _flushInterval = Duration(minutes: 2);

  final List<Map<String, dynamic>> _eventBuffer = [];
  Timer? _flushTimer;
  String _sessionId = '';
  DateTime? _sessionStart;
  DateTime? _lastScreenTime;
  String _lastScreen = '';

  /// Initialize analytics — call in main()
  Future<void> init() async {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    _sessionStart = DateTime.now();

    // Load any unsent events from last session
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_batchKey);
    if (stored != null && stored.isNotEmpty) {
      // Queue old events for flush
      for (final s in stored) {
        try {
          final parts = s.split('|');
          if (parts.length >= 3) {
            _eventBuffer.add({
              'event': parts[0],
              'timestamp': parts[1],
              'properties': parts.length > 2 ? parts[2] : '{}',
            });
          }
        } catch (_) {}
      }
      await prefs.remove(_batchKey);
    }

    // Start periodic flush
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());

    // Track app open
    track(AnalyticsEvent.appOpen);
  }

  /// Track a single event with optional properties
  void track(AnalyticsEvent event, {Map<String, dynamic>? properties}) {
    final eventData = {
      'event': event.name,
      'timestamp': DateTime.now().toIso8601String(),
      'session_id': _sessionId,
      'properties': properties ?? {},
    };
    _eventBuffer.add(eventData);

    // Auto-flush if buffer is large
    if (_eventBuffer.length >= _maxBatchSize) {
      flush();
    }
  }

  /// Track screen view with time-on-screen calculation
  void trackScreen(String screenName) {
    // Calculate time spent on previous screen
    if (_lastScreen.isNotEmpty && _lastScreenTime != null) {
      final duration = DateTime.now().difference(_lastScreenTime!);
      track(AnalyticsEvent.screenView, properties: {
        'screen': _lastScreen,
        'duration_ms': duration.inMilliseconds,
      });
    }
    _lastScreen = screenName;
    _lastScreenTime = DateTime.now();
  }

  /// Track booking funnel step
  void trackBookingStep(int step, String label, {String? bookingId}) {
    track(AnalyticsEvent.bookingStepCompleted, properties: {
      'step': step,
      'label': label,
      if (bookingId != null) 'booking_id': bookingId,
    });
  }

  /// Track booking drop-off (user left without completing)
  void trackBookingDropOff(int lastStep, String reason) {
    track(AnalyticsEvent.bookingDropOff, properties: {
      'last_step': lastStep,
      'reason': reason,
    });
  }

  /// Track search with results count
  void trackSearch(String query, int resultsCount, {Map<String, dynamic>? filters}) {
    track(
      resultsCount > 0 ? AnalyticsEvent.searchCompleted : AnalyticsEvent.searchNoResults,
      properties: {
        'query': query,
        'results_count': resultsCount,
        if (filters != null) 'filters': filters,
      },
    );
  }

  /// Flush events to backend
  Future<void> flush() async {
    if (_eventBuffer.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_eventBuffer);
    _eventBuffer.clear();

    try {
      await ApiService.post('/analytics/events', {
        'events': batch,
        'session_id': _sessionId,
        'session_duration_ms': _sessionStart != null
            ? DateTime.now().difference(_sessionStart!).inMilliseconds
            : 0,
      }, auth: true);
    } catch (_) {
      // Store locally for next attempt
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_batchKey) ?? [];
      for (final event in batch) {
        stored.add('${event['event']}|${event['timestamp']}|${event['properties']}');
      }
      // Keep max 200 events stored locally
      if (stored.length > 200) {
        stored.removeRange(0, stored.length - 200);
      }
      await prefs.setStringList(_batchKey, stored);
    }
  }

  /// Get session duration
  Duration get sessionDuration =>
      _sessionStart != null ? DateTime.now().difference(_sessionStart!) : Duration.zero;

  void dispose() {
    flush();
    _flushTimer?.cancel();
  }
}
