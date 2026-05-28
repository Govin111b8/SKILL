class Follow {
  final String id;
  final String followerId;
  final String followingId;
  final String? followingName;
  final String? followingAvatar;
  final String? followingHeadline;
  final double? followingRating;
  final DateTime createdAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    this.followingName,
    this.followingAvatar,
    this.followingHeadline,
    this.followingRating,
    required this.createdAt,
  });

  factory Follow.fromJson(Map<String, dynamic> json) => Follow(
        id: json['id']?.toString() ?? json['professional_id']?.toString() ?? json['following_id']?.toString() ?? '',
        followerId: json['follower_id']?.toString() ?? '',
        followingId: json['following_id']?.toString() ?? json['professional_id']?.toString() ?? '',
        followingName: _toStringOrNull(json['following_name'] ?? json['name']),
        followingAvatar: _toStringOrNull(json['following_avatar'] ?? json['avatar_url']),
        followingHeadline: _toStringOrNull(json['following_headline'] ?? json['headline']),
        followingRating: json['following_rating'] == null && json['average_rating'] == null && json['rating'] == null
            ? null
            : _toDouble(json['following_rating'] ?? json['average_rating'] ?? json['rating']),
        createdAt: _toDate(json['created_at'] ?? json['followed_at']),
      );
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
