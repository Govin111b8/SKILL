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

class FeaturedSlot {
  final String id;
  final String professionalId;
  final String? professionalName;
  final String? professionalAvatar;
  final String slotType;
  final String? categoryId;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final double pricePaid;
  final DateTime createdAt;

  FeaturedSlot({
    required this.id,
    required this.professionalId,
    this.professionalName,
    this.professionalAvatar,
    required this.slotType,
    this.categoryId,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    required this.pricePaid,
    required this.createdAt,
  });

  factory FeaturedSlot.fromJson(Map<String, dynamic> json) {
    final startsAt = _toDate(json['starts_at'] ?? json['start_at']);
    final endsAt = _toDate(json['ends_at'] ?? json['end_at']);
    final now = DateTime.now();
    return FeaturedSlot(
      id: json['id']?.toString() ?? '',
      professionalId: json['professional_id']?.toString() ?? '',
      professionalName: _toStringOrNull(json['professional_name'] ?? json['name']),
      professionalAvatar: _toStringOrNull(json['professional_avatar'] ?? json['avatar_url']),
      slotType: json['slot_type']?.toString() ?? json['type']?.toString() ?? 'homepage_banner',
      categoryId: _toStringOrNull(json['category_id'] ?? json['category']),
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: json['is_active'] == null ? now.isAfter(startsAt) && now.isBefore(endsAt) : json['is_active'] == true,
      pricePaid: _toDouble(json['price_paid'] ?? json['amount_paid']),
      createdAt: _toDate(json['created_at']),
    );
  }
}
