import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _loading = true;

  User? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isProfessional => _user?.isProfessional ?? false;

  AuthProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userId = prefs.getInt('user_id');
    final userName = prefs.getString('user_name');
    final userEmail = prefs.getString('user_email');
    final userRole = prefs.getString('user_role');
    if (_token != null && userId != null) {
      _user = User(
        id: userId,
        email: userEmail ?? '',
        name: userName ?? '',
        phone: prefs.getString('user_phone') ?? '',
        role: userRole ?? 'customer',
        location: prefs.getString('user_location') ?? '',
      );
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveToStorage(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_location', user.location);
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
    _token = data['token'];
    _user = User.fromJson(data['user']);
    await _saveToStorage(_user!, _token!);
    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> formData) async {
    final data = await ApiService.post('/auth/register', formData);
    _token = data['token'];
    _user = User.fromJson(data['user']);
    await _saveToStorage(_user!, _token!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
