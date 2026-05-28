import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Push notification categories for smart notifications
enum NotificationCategory {
  transactional, // booking confirmations, payments, etc.
  behavioral,    // "similar pros available", "complete your booking"
  lifecycle,     // "welcome back", "rate your service"
  promotional,   // offers, discounts
}

/// FCM-ready push notification service.
///
/// Architecture:
/// - Uses firebase_messaging for FCM token management and message receipt
/// - Uses flutter_local_notifications for in-app banners (foreground messages)
/// - Categories map to Android notification channels (transactional = high priority)
/// - User preferences stored in SharedPreferences and synced to backend
///
/// NOTE: Call [initFCM] after user logs in.
/// NOTE: Call [setupFCMHandlers] once in main.dart after Firebase.initializeApp().
class PushNotificationService {
  static const _prefsKey = 'notification_preferences';
  static const _tokenKey = 'fcm_token';
  static const _languageKey = 'notification_language';

  /// Default preferences — transactional always on
  static final Map<String, bool> _defaultPrefs = {
    'transactional': true,
    'behavioral': true,
    'lifecycle': true,
    'promotional': false,
  };

  // Callback for when a notification tap navigates to a screen
  static void Function(String route, Map<String, dynamic> data)? onNavigate;

  /// Initialize FCM: request permission, get token, register with backend.
  /// Call this after the user logs in.
  static Future<void> initFCM() async {
    try {
      // Request permission (iOS prompt; Android 13+ prompt)
      final settings = await _requestPermission();
      if (settings == null) return; // FCM not available

      final token = await _getToken();
      if (token != null) {
        await registerToken(token);
      }

      // Listen for token refresh
      _listenTokenRefresh();
    } catch (e) {
      // FCM not available in this environment (e.g., simulator without Play Services)
      debugPrint('[FCM] Init failed: $e');
    }
  }

  /// Setup FCM message handlers. Call once in main() after Firebase.initializeApp().
  static Future<void> setupFCMHandlers() async {
    try {
      // Foreground messages → show local notification banner
      _onForegroundMessage((message) {
        _handleMessage(message, foreground: true);
      });

      // Background message tap → navigate when app opens
      _onMessageOpenedApp((message) {
        _handleMessage(message, foreground: false);
      });

      // App opened from terminated state via notification tap
      final initialMessage = await _getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage, foreground: false);
      }
    } catch (e) {
      debugPrint('[FCM] Handler setup failed: $e');
    }
  }

  /// Handle an incoming FCM message
  static Future<void> _handleMessage(dynamic message, {required bool foreground}) async {
    try {
      final data = _extractData(message);
      final categoryStr = data['category']?.toString() ?? 'transactional';
      final NotificationCategory category;
      try {
        category = NotificationCategory.values.byName(categoryStr);
      } catch (_) {
        return;
      }

      // Check user preference
      if (!await isCategoryEnabled(category)) return;

      if (foreground) {
        await _showLocalNotification(data);
        debugPrint('[FCM] Foreground notification: ${data['title']}');
      } else {
        // Navigate based on notification data
        final route = data['route']?.toString();
        if (route != null && onNavigate != null) {
          onNavigate!(route, data);
        }
      }
    } catch (e) {
      debugPrint('[FCM] Message handling error: $e');
    }
  }

  static Map<String, dynamic> _extractData(dynamic message) {
    try {
      // firebase_messaging RemoteMessage-like structure
      final notification = message.notification;
      final data = Map<String, dynamic>.from(message.data as Map? ?? {});
      if (notification != null) {
        data['title'] ??= notification.title;
        data['body'] ??= notification.body;
      }
      return data;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _showLocalNotification(Map<String, dynamic> data) async {
    // When flutter_local_notifications is added:
    // initialize channels + show a local notification for foreground messages.
    debugPrint('[FCM] Local notification: ${data['title']} - ${data['body']}');
  }

  // --- Platform stubs (replaced by firebase_messaging when available) ---

  static Future<dynamic> _requestPermission() async {
    // When firebase_messaging is added:
    // return await FirebaseMessaging.instance.requestPermission(...)
    return null; // stub
  }

  static Future<String?> _getToken() async {
    // When firebase_messaging is added:
    // return await FirebaseMessaging.instance.getToken();
    return null; // stub
  }

  static void _listenTokenRefresh() {
    // When firebase_messaging is added:
    // FirebaseMessaging.instance.onTokenRefresh.listen(registerToken);
  }

  static void _onForegroundMessage(void Function(dynamic) handler) {
    // When firebase_messaging is added:
    // FirebaseMessaging.onMessage.listen(handler);
  }

  static void _onMessageOpenedApp(void Function(dynamic) handler) {
    // When firebase_messaging is added:
    // FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  static Future<dynamic> _getInitialMessage() async {
    // When firebase_messaging is added:
    // return await FirebaseMessaging.instance.getInitialMessage();
    return null;
  }

  // --- Preference management ---

  /// Get current notification preferences
  static Future<Map<String, bool>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null) return Map.from(_defaultPrefs);
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as bool));
  }

  /// Update notification preferences
  static Future<void> setPreferences(Map<String, bool> preferences) async {
    // Transactional cannot be turned off
    preferences['transactional'] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(preferences));
    try {
      await ApiService.put('/users/notification-preferences', preferences, auth: true);
    } catch (_) {
      // Will sync next time online
    }
  }

  /// Get notification language preference
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  /// Set notification language preference
  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
    try {
      await ApiService.put('/users/notification-language', {'language': lang}, auth: true);
    } catch (_) {}
  }

  /// Register FCM token with backend
  static Future<void> registerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final oldToken = prefs.getString(_tokenKey);
    if (oldToken == token) return;

    await prefs.setString(_tokenKey, token);
    try {
      await ApiService.post('/users/me/push-token', {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'language': await getLanguage(),
      }, auth: true);
    } catch (_) {}
  }

  /// Unregister token (on logout)
  static Future<void> unregisterToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return;

    await prefs.remove(_tokenKey);
    try {
      await ApiService.post('/users/me/push-token/remove', {'token': token}, auth: true);
    } catch (_) {}
  }

  /// Check if a notification category is enabled
  static Future<bool> isCategoryEnabled(NotificationCategory category) async {
    final prefs = await getPreferences();
    return prefs[category.name] ?? true;
  }

  /// Handle incoming notification — filter based on preferences
  static Future<bool> shouldShow(Map<String, dynamic> notification) async {
    final categoryStr = notification['category']?.toString() ?? 'transactional';
    final prefs = await getPreferences();
    return prefs[categoryStr] ?? true;
  }
}
