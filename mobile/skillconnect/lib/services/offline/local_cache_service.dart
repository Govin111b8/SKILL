import 'package:hive_flutter/hive_flutter.dart';

/// Local caching service using Hive for offline-first support.
/// Caches user profile, bookings, nearby providers, and chat history.
class LocalCacheService {
  static const _userBox = 'user_cache';
  static const _bookingsBox = 'bookings_cache';
  static const _providersBox = 'providers_cache';
  static const _chatBox = 'chat_cache';
  static const _threadsBox = 'threads_cache';
  static const _metaBox = 'meta_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(_userBox),
      Hive.openBox<Map>(_bookingsBox),
      Hive.openBox<Map>(_providersBox),
      Hive.openBox<Map>(_chatBox),
      Hive.openBox<Map>(_threadsBox),
      Hive.openBox<String>(_metaBox),
    ]);
  }

  // ─── User Profile ───────────────────────────────────────────
  static Future<void> cacheUserProfile(Map<String, dynamic> user) async {
    final box = Hive.box<Map>(_userBox);
    await box.put('profile', user);
  }

  static Map<String, dynamic>? getCachedUserProfile() {
    final box = Hive.box<Map>(_userBox);
    final data = box.get('profile');
    return data?.cast<String, dynamic>();
  }

  // ─── Bookings ───────────────────────────────────────────────
  static Future<void> cacheBookings(List<Map<String, dynamic>> bookings) async {
    final box = Hive.box<Map>(_bookingsBox);
    await box.clear();
    for (int i = 0; i < bookings.length; i++) {
      await box.put(bookings[i]['id']?.toString() ?? '$i', bookings[i]);
    }
    await _setLastSync('bookings');
  }

  static List<Map<String, dynamic>> getCachedBookings() {
    final box = Hive.box<Map>(_bookingsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ─── Nearby Providers ───────────────────────────────────────
  static Future<void> cacheProviders(List<Map<String, dynamic>> providers) async {
    final box = Hive.box<Map>(_providersBox);
    await box.clear();
    for (int i = 0; i < providers.length; i++) {
      await box.put(providers[i]['id']?.toString() ?? '$i', providers[i]);
    }
    await _setLastSync('providers');
  }

  static List<Map<String, dynamic>> getCachedProviders() {
    final box = Hive.box<Map>(_providersBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ─── Chat Threads ──────────────────────────────────────────
  static Future<void> cacheThreads(List<Map<String, dynamic>> threads) async {
    final box = Hive.box<Map>(_threadsBox);
    await box.clear();
    for (final thread in threads) {
      await box.put(thread['id']?.toString() ?? '', thread);
    }
  }

  static List<Map<String, dynamic>> getCachedThreads() {
    final box = Hive.box<Map>(_threadsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ─── Chat Messages (per thread, last N) ────────────────────
  static Future<void> cacheMessages(String threadId, List<Map<String, dynamic>> messages) async {
    final box = Hive.box<Map>(_chatBox);
    // Keep last 50 messages per thread
    final trimmed = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
    await box.put(threadId, {'messages': trimmed});
  }

  static List<Map<String, dynamic>> getCachedMessages(String threadId) {
    final box = Hive.box<Map>(_chatBox);
    final data = box.get(threadId);
    if (data == null) return [];
    final messages = data['messages'];
    if (messages is List) {
      return messages.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ─── Meta ──────────────────────────────────────────────────
  static Future<void> _setLastSync(String key) async {
    final box = Hive.box<String>(_metaBox);
    await box.put('${key}_last_sync', DateTime.now().toIso8601String());
  }

  static DateTime? getLastSync(String key) {
    final box = Hive.box<String>(_metaBox);
    final val = box.get('${key}_last_sync');
    return val == null ? null : DateTime.tryParse(val);
  }

  /// Clear all cached data (on logout)
  static Future<void> clearAll() async {
    await Future.wait([
      Hive.box<Map>(_userBox).clear(),
      Hive.box<Map>(_bookingsBox).clear(),
      Hive.box<Map>(_providersBox).clear(),
      Hive.box<Map>(_chatBox).clear(),
      Hive.box<Map>(_threadsBox).clear(),
      Hive.box<String>(_metaBox).clear(),
    ]);
  }
}
