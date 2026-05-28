import 'api_service.dart';

class WarrantyService {
  static Future<List<Map<String, dynamic>>> getWarranties() async {
    final res = await ApiService.get('/warranties', auth: true);
    final data = res['data'];
    final list = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['items'] as List? ?? data['warranties'] as List? ?? const [])
            : const [];
    return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<Map<String, dynamic>> getWarranty(String id) async {
    final res = await ApiService.get('/warranties/$id', auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }

  static Future<Map<String, dynamic>> claimWarranty(String id, String description, List<String> images) async {
    final res = await ApiService.post('/warranties/$id/claim', {
      'description': description,
      'reason': description,
      'images': images,
    }, auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }

  static Future<Map<String, dynamic>> addWarranty(String bookingId, String productName, String description, DateTime expiryDate) async {
    final res = await ApiService.post('/warranties', {
      'booking_id': bookingId,
      'product_name': productName,
      'description': description,
      'expiry_date': expiryDate.toIso8601String(),
    }, auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }
}
