import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

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
    notifyListeners();
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
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
  }
}
