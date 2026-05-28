import '../models/models.dart';
import 'api_service.dart';

class CommunityService {
  static Future<List<CommunityPost>> getPosts({String? category, int page = 1}) async {
    final res = await ApiService.get('/community/posts', queryParams: {
      if (category != null && category.isNotEmpty) 'category': category,
      'page': page.toString(),
    });
    final data = res['data'];
    final list = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['items'] as List? ?? data['posts'] as List? ?? const [])
            : const [];
    return list.whereType<Map>().map((item) => CommunityPost.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  static Future<CommunityPost> getPost(String id) async {
    final res = await ApiService.get('/community/posts/$id', auth: true);
    return CommunityPost.fromJson(Map<String, dynamic>.from((res['data'] as Map?) ?? res));
  }

  static Future<CommunityPost> createPost(String title, String content, String? category, List<String> mediaUrls) async {
    final res = await ApiService.post('/community/posts', {
      'title': title,
      'content': content,
      if (category != null && category.isNotEmpty) 'category': category,
      'media_urls': mediaUrls,
    }, auth: true);
    return CommunityPost.fromJson(Map<String, dynamic>.from((res['data'] as Map?) ?? res));
  }

  static Future<bool> likePost(String id) async {
    final res = await ApiService.post('/community/posts/$id/like', {}, auth: true);
    return res['liked'] == true;
  }

  static Future<void> unlikePost(String id) async {
    try {
      await ApiService.delete('/community/posts/$id/like', auth: true);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        await ApiService.post('/community/posts/$id/like', {}, auth: true);
        return;
      }
      rethrow;
    }
  }
}
