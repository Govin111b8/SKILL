class Story {
  final String id;
  final String professionalId;
  final String professionalName;
  final String? professionalAvatar;
  final String mediaUrl;
  final String mediaType;
  final String? textOverlay;
  final String? ctaUrl;
  final String? ctaLabel;
  final int viewCount;
  final bool isViewed;
  final DateTime expiresAt;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    this.professionalAvatar,
    required this.mediaUrl,
    required this.mediaType,
    this.textOverlay,
    this.ctaUrl,
    this.ctaLabel,
    required this.viewCount,
    required this.isViewed,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id']?.toString() ?? '',
        professionalId: json['professional_id']?.toString() ?? json['professionalId']?.toString() ?? '',
        professionalName: json['professional_name']?.toString() ?? json['professionalName']?.toString() ?? 'Professional',
        professionalAvatar: _toStringOrNull(json['professional_avatar'] ?? json['avatar_url'] ?? json['professionalAvatar']),
        mediaUrl: json['media_url']?.toString() ?? json['mediaUrl']?.toString() ?? '',
        mediaType: _normalizeMediaType(json['media_type'] ?? json['mediaType'], json['media_url'] ?? json['mediaUrl']),
        textOverlay: _toStringOrNull(json['text_overlay'] ?? json['textOverlay']),
        ctaUrl: _toStringOrNull(json['cta_url'] ?? json['ctaUrl']),
        ctaLabel: _toStringOrNull(json['cta_label'] ?? json['ctaLabel']),
        viewCount: _toInt(json['view_count'] ?? json['viewCount']),
        isViewed: json['is_viewed'] == true || json['viewed'] == true || json['isViewed'] == true,
        expiresAt: _toDate(json['expires_at'] ?? json['expiresAt']),
        createdAt: _toDate(json['created_at'] ?? json['createdAt']),
      );

  static String _normalizeMediaType(dynamic value, dynamic urlValue) {
    final valueString = value?.toString().toLowerCase();
    if (valueString == 'image' || valueString == 'video') return valueString!;
    final url = urlValue?.toString().toLowerCase() ?? '';
    const videoExts = ['.mp4', '.mov', '.webm', '.m4v', '.mkv'];
    if (videoExts.any(url.endsWith)) return 'video';
    return 'image';
  }
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
