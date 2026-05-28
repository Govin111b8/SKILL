import 'dart:convert';

class ProfessionalBadge {
  final String id;
  final String professionalId;
  final String badgeType;
  final String label;
  final String emoji;
  final String description;
  final DateTime earnedAt;
  final Map<String, dynamic> metadata;

  ProfessionalBadge({
    required this.id,
    required this.professionalId,
    required this.badgeType,
    required this.label,
    required this.emoji,
    required this.description,
    required this.earnedAt,
    this.metadata = const {},
  });

  factory ProfessionalBadge.fromJson(Map<String, dynamic> json) {
    final badgeType = json['badge_type']?.toString() ?? json['type']?.toString() ?? 'rising_pro';
    return ProfessionalBadge(
      id: json['id']?.toString() ?? badgeType,
      professionalId: json['professional_id']?.toString() ?? '',
      badgeType: badgeType,
      label: json['label']?.toString() ?? badgeLabel(badgeType),
      emoji: json['emoji']?.toString() ?? badgeEmoji(badgeType),
      description: json['description']?.toString() ?? _badgeDescription(badgeType),
      earnedAt: _toDate(json['earned_at'] ?? json['created_at']),
      metadata: _toMetadata(json['metadata']),
    );
  }

  static String badgeLabel(String type) {
    switch (type) {
      case 'fast_responder':
        return 'Fast Responder';
      case 'customer_favorite':
        return 'Customer Favorite';
      case 'top_rated':
        return 'Top Rated';
      case 'elite':
      case 'elite_professional':
        return 'Elite Professional';
      case 'rising_pro':
      default:
        return 'Rising Pro';
    }
  }

  static String badgeEmoji(String type) {
    switch (type) {
      case 'fast_responder':
        return '⚡';
      case 'customer_favorite':
        return '⭐';
      case 'top_rated':
        return '🏆';
      case 'elite':
      case 'elite_professional':
        return '💎';
      case 'rising_pro':
      default:
        return '🌱';
    }
  }

  static String _badgeDescription(String type) {
    switch (type) {
      case 'fast_responder':
        return 'Responds quickly and keeps customers updated.';
      case 'customer_favorite':
        return 'Loved by customers for consistent, high-quality work.';
      case 'top_rated':
        return 'Ranks among the best professionals in this category.';
      case 'elite':
      case 'elite_professional':
        return 'Outstanding trust, service quality, and repeat business.';
      case 'rising_pro':
      default:
        return 'A verified professional building strong trust on SkillConnect.';
    }
  }
}

Map<String, dynamic> _toMetadata(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return const {};
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
