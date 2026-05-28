import '../models/models.dart';
import 'api_service.dart';

class PointsService {
  static Future<UserPoints> getMyPoints() async {
    try {
      final res = await ApiService.get('/gamification/points', auth: true);
      return UserPoints.fromJson(_asMap(res['data'] ?? res));
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      final fallback = await Future.wait([
        ApiService.get('/referrals/loyalty', auth: true),
        ApiService.get('/users/profile', auth: true),
      ]);
      final loyalty = _asMap(fallback[0]);
      final profile = _asMap(fallback[1]['data'] ?? fallback[1]);
      return UserPoints.fromJson({
        'user_id': profile['id'],
        'points_balance': loyalty['balance'] ?? profile['loyalty_balance'] ?? 0,
        'lifetime_points': loyalty['balance'] ?? profile['loyalty_balance'] ?? 0,
        'level': profile['level'] ?? _inferLevel((loyalty['balance'] as num?)?.toInt() ?? 0),
        'recent_transactions': loyalty['points'] ?? const [],
      });
    }
  }

  static Future<List<PointTransaction>> getTransactionHistory() async {
    try {
      final res = await ApiService.get('/gamification/points/history', auth: true);
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['transactions'] as List? ?? const [])
              : const [];
      return list.whereType<Map>().map((item) => PointTransaction.fromJson(Map<String, dynamic>.from(item))).toList();
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      final res = await ApiService.get('/referrals/loyalty', auth: true);
      final list = (res['points'] as List? ?? const []);
      return list.whereType<Map>().map((item) => PointTransaction.fromJson(Map<String, dynamic>.from(item))).toList();
    }
  }

  static Future<Map<String, dynamic>> redeemPoints(int points, [String? bookingId]) async {
    final res = await ApiService.post('/gamification/points/redeem', {
      'points': points,
      if (bookingId != null && bookingId.isNotEmpty) 'booking_id': bookingId,
    }, auth: true);
    return _asMap(res['data'] ?? res);
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final res = await ApiService.get('/gamification/leaderboard', auth: true);
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['leaderboard'] as List? ?? const [])
              : const [];
      return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int _inferLevel(int lifetimePoints) {
    if (lifetimePoints >= 3000) return 4;
    if (lifetimePoints >= 1500) return 3;
    if (lifetimePoints >= 500) return 2;
    return 1;
  }
}
