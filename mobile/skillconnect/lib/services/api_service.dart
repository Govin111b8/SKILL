import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'web_client.dart' if (dart.library.io) 'mobile_client.dart';

class ApiService {
  static const _timeout = Duration(seconds: 20);
  static String get _base => kIsWeb ? ApiConfig.baseUrl : ApiConfig.androidBaseUrl;

  static http.Client _createClient() => createPlatformClient();

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path, {bool auth = false, Map<String, String>? queryParams}) async {
    final client = _createClient();
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: queryParams);
      final response = await client.get(uri, headers: await _headers(auth: auth)).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection.', 408);
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final client = _createClient();
    try {
      final uri = Uri.parse('$_base$path');
      final response = await client.post(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection.', 408);
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final client = _createClient();
    try {
      final uri = Uri.parse('$_base$path');
      final response = await client.put(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection.', 408);
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> delete(String path, {bool auth = false}) async {
    final client = _createClient();
    try {
      final uri = Uri.parse('$_base$path');
      final response = await client.delete(uri, headers: await _headers(auth: auth)).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection.', 408);
    } finally {
      client.close();
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw ApiException('Empty response from server.', response.statusCode);
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid response format.', response.statusCode);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    // Extract nested error messages (e.g. from express-validator)
    final errors = data['errors'];
    String message = data['message']?.toString() ?? 'Something went wrong';
    if (errors is List && errors.isNotEmpty) {
      message = (errors.first as Map?)?['msg']?.toString() ?? message;
    }
    throw ApiException(message, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
