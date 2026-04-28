import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'realtime_service.dart';

class AuthService extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _loading = false;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;
  bool get isProfessional => _user?['role'] == 'professional';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    if (userData != null) _user = jsonDecode(userData);
    if (_token != null) {
      // Verify token is still valid by fetching fresh profile
      try {
        final res = await ApiService.get('/users/profile', auth: true);
        final fresh = res['data'] as Map<String, dynamic>?;
        if (fresh != null) {
          _user = fresh;
          await prefs.setString('user_data', jsonEncode(fresh));
        }
        RealtimeService.instance.connect(_token!);
      } catch (e) {
        // Token expired or network error — only clear if 401
        if (e is ApiException && e.statusCode == 401) {
          await _clearSession(prefs);
        } else {
          // Network offline — keep local session, reconnect when online
          if (_token != null) RealtimeService.instance.connect(_token!);
        }
      }
    }
    notifyListeners();
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _token = null;
    _user = null;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String location,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        'location': location,
      });
      await _saveAuth(res['data']['user'], res['data']['token']);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connection failed. Check your network.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> login({required String email, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.post('/auth/login', {'email': email, 'password': password});
      await _saveAuth(res['data']['user'], res['data']['token']);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connection failed. Check your network.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update local user data after profile edit (called from SettingsScreen).
  void updateLocalUser(Map<String, dynamic> updates) async {
    _user = {...?_user, ...updates};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_user));
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    RealtimeService.instance.disconnect();
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> _saveAuth(Map<String, dynamic> user, String token) async {
    _user = user;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user));
    RealtimeService.instance.connect(token);
  }
}
