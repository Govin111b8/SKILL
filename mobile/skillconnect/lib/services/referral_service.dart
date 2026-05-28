import 'api_service.dart';

class ReferralService {
  static Future<Map<String, dynamic>> getReferralSummary() async {
    try {
      final res = await ApiService.get('/referrals/summary', auth: true);
      return _asMap(res['data'] ?? res);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      final res = await ApiService.get('/referrals/stats', auth: true);
      return _asMap(res);
    }
  }

  static Future<String> getReferralCode() async {
    try {
      final res = await ApiService.get('/referrals/my-code', auth: true);
      final data = _asMap(res['data'] ?? res);
      return _extractCode(data);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      final summary = await getReferralSummary();
      final existingCode = _extractCode(summary);
      if (existingCode.isNotEmpty) return existingCode;
      final generated = await ApiService.post('/referrals/generate', {}, auth: true);
      return _extractCode(_asMap(generated['data'] ?? generated['referral_code'] ?? generated));
    }
  }

  static Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final res = await ApiService.post('/referrals/apply', {
      'code': code,
    }, auth: true);
    return _asMap(res['data'] ?? res['referral'] ?? res);
  }

  static Future<List<Map<String, dynamic>>> getReferralEarnings() async {
    try {
      final res = await ApiService.get('/referrals/earnings', auth: true);
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['earnings'] as List? ?? const [])
              : const [];
      return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      final summary = await getReferralSummary();
      final list = (summary['referrals'] as List? ?? const []);
      return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _extractCode(Map<String, dynamic> data) {
    final nested = _asMap(data['referral_code']);
    return data['code']?.toString() ?? data['referral_code']?.toString() ?? nested['code']?.toString() ?? '';
  }
}
