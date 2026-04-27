import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your backend URL
  static String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<void> setBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved != null && saved.isNotEmpty) baseUrl = saved;
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final resp = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handle(resp);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(resp);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final resp = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(resp);
  }

  static Future<dynamic> delete(String endpoint) async {
    final resp = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );
    return _handle(resp);
  }

  static dynamic _handle(http.Response resp) {
    final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;
    if (resp.statusCode >= 200 && resp.statusCode < 300) return data;
    final msg = data is Map ? data['message'] ?? 'Error ${resp.statusCode}' : 'Error ${resp.statusCode}';
    throw ApiException(msg.toString(), resp.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
