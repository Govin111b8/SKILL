import 'api_service.dart';

class CollectionService {
  static Future<List<Map<String, dynamic>>> getCollections() async {
    final res = await ApiService.get('/collections', auth: true);
    final data = res['data'];
    final list = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['items'] as List? ?? data['collections'] as List? ?? const [])
            : const [];
    return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<Map<String, dynamic>> createCollection(String name, bool isPublic) async {
    final res = await ApiService.post('/collections', {
      'name': name,
      'title': name,
      'is_public': isPublic,
    }, auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }

  static Future<Map<String, dynamic>> addToCollection(String collectionId, String itemType, String itemId) async {
    final res = await ApiService.post('/collections/$collectionId/items', {
      'item_type': itemType,
      'item_id': itemId,
    }, auth: true);
    return Map<String, dynamic>.from((res['data'] as Map?) ?? res);
  }

  static Future<void> removeFromCollection(String collectionId, String itemId) async {
    await ApiService.delete('/collections/$collectionId/items/$itemId', auth: true);
  }

  static Future<void> deleteCollection(String id) async {
    await ApiService.delete('/collections/$id', auth: true);
  }
}
