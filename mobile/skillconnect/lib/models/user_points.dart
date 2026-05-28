class UserPoints {
  final String userId;
  final int pointsBalance;
  final int lifetimePoints;
  final int level;
  final List<PointTransaction> recentTransactions;

  UserPoints({
    required this.userId,
    required this.pointsBalance,
    required this.lifetimePoints,
    required this.level,
    this.recentTransactions = const [],
  });

  factory UserPoints.fromJson(Map<String, dynamic> json) => UserPoints(
        userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
        pointsBalance: _toInt(json['points_balance'] ?? json['balance'] ?? json['loyalty_balance']),
        lifetimePoints: _toInt(json['lifetime_points'] ?? json['total_points'] ?? json['points_balance'] ?? json['balance'] ?? json['loyalty_balance']),
        level: _toInt(json['level'], 1),
        recentTransactions: _toTransactions(json['recent_transactions'] ?? json['transactions'] ?? json['points']),
      );
}

class PointTransaction {
  final String id;
  final String type;
  final int points;
  final String reason;
  final DateTime createdAt;

  PointTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.reason,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    final points = _toInt(json['points'] ?? json['amount']);
    final type = json['type']?.toString() ?? json['transaction_type']?.toString() ?? (points < 0 ? 'redeem' : 'earn');
    return PointTransaction(
      id: json['id']?.toString() ?? '',
      type: type,
      points: points,
      reason: json['reason']?.toString() ?? json['description']?.toString() ?? 'Points update',
      createdAt: _toDate(json['created_at'] ?? json['date']),
    );
  }
}

List<PointTransaction> _toTransactions(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => PointTransaction.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
