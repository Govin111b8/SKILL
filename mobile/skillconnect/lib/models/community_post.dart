import 'dart:convert';

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String title;
  final String content;
  final String? category;
  final List<String> mediaUrls;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.title,
    required this.content,
    this.category,
    this.mediaUrls = const [],
    required this.likesCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id']?.toString() ?? '',
        authorId: json['author_id']?.toString() ?? json['professional_id']?.toString() ?? '',
        authorName: json['author_name']?.toString() ?? 'Professional',
        authorAvatar: _toStringOrNull(json['author_avatar'] ?? json['avatar_url']),
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        category: _toStringOrNull(json['category']),
        mediaUrls: _toStringList(json['media_urls'] ?? json['mediaUrls']),
        likesCount: _toInt(json['likes_count'] ?? json['like_count']),
        isLiked: json['is_liked'] == true || json['user_liked'] == true || json['liked'] == true,
        createdAt: _toDate(json['created_at']),
      );
}

List<String> _toStringList(dynamic value) {
  if (value is List) return value.whereType<dynamic>().map((item) => item.toString()).toList();
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.whereType<dynamic>().map((item) => item.toString()).toList();
      }
    } catch (_) {
      return [value];
    }
  }
  return const [];
}

int _toInt(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? defaultValue;
}

double _toDouble(dynamic v, [double defaultValue = 0.0]) {
  if (v == null) return defaultValue;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? defaultValue;
}

String? _toStringOrNull(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

DateTime _toDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}
