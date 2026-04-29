import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_config.dart';

class UploadService {
  static String get _base => kIsWeb ? ApiConfig.baseUrl : ApiConfig.androidBaseUrl;

  /// Upload a file and return its URL path (e.g. /uploads/abc.jpg)
  static Future<String> uploadFile(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final uri = Uri.parse('$_base/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['url'] as String;
    }
    throw Exception(data['message'] ?? 'Upload failed');
  }

  /// Upload avatar and return new avatar URL
  static Future<String> uploadAvatar(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final uri = Uri.parse('$_base/upload/avatar');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['avatar_url'] as String;
    }
    throw Exception(data['message'] ?? 'Upload failed');
  }
}
