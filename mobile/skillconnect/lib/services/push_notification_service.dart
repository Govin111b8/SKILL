import 'dart:convert';
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

/// Push notification service with:
/// - Categorized notifications (transactional/behavioral/lifecycle)
/// - User preference controls
/// - Regional language support
/// - FCM token management
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
    // Sync to backend
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
    if (oldToken == token) return; // Already registered

    await prefs.setString(_tokenKey, token);
    try {
      await ApiService.post('/notifications/register-device', {
        'token': token,
        'platform': 'android',
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
      await ApiService.post('/notifications/unregister-device', {
        'token': token,
      }, auth: true);
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
