import 'api_service.dart';

class DisputeService {
  static Future<List<Map<String, dynamic>>> getDisputes() async {
    final res = await ApiService.get('/disputes', auth: true);
    final data = res['data'];
    final list = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['items'] as List? ?? data['disputes'] as List? ?? const [])
            : const [];
    return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<Map<String, dynamic>> getDispute(String id) async {
    final res = await ApiService.get('/disputes/$id', auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }

  static Future<Map<String, dynamic>> createDispute(String bookingId, String reason, String description) async {
    final res = await ApiService.post('/disputes', {
      'booking_id': bookingId,
      'reason': reason,
      'issue_type': reason,
      'description': description,
    }, auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }

  static Future<Map<String, dynamic>> resolveDispute(String id, String resolution) async {
    final res = await ApiService.put('/disputes/$id/resolve', {
      'resolution': resolution,
    }, auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }
}
