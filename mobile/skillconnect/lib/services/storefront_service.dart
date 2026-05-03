import '../models/models.dart';
import 'api_service.dart';

/// Service for fetching and updating professional storefront data.
class StorefrontService {
  /// Fetch the full storefront data (profile + portfolio + reviews + rating distribution).
  static Future<Map<String, dynamic>> fetchStorefront(String professionalId) async {
    final res = await ApiService.get('/storefront/$professionalId');
    return res['data'] as Map<String, dynamic>;
  }

  /// Update storefront-specific fields (auth required, owner only).
  static Future<Map<String, dynamic>> updateStorefront(String professionalId, Map<String, dynamic> data) async {
    final res = await ApiService.put('/storefront/$professionalId', data, auth: true);
    return res['data'] as Map<String, dynamic>;
  }

  /// Parse a full storefront response into structured data.
  static StorefrontData parseStorefront(Map<String, dynamic> data) {
    final professional = Professional.fromJson(data);
    final portfolio = (data['portfolio'] as List?)
        ?.map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final reviews = (data['reviews'] as List?)
        ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final ratingDistribution = <int, int>{};
    if (data['rating_distribution'] != null) {
      (data['rating_distribution'] as Map<String, dynamic>).forEach((k, v) {
        ratingDistribution[int.tryParse(k) ?? 0] = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
      });
    }
    return StorefrontData(
      professional: professional,
      portfolio: portfolio,
      reviews: reviews,
      ratingDistribution: ratingDistribution,
    );
  }
}

/// Holds all parsed storefront data for easy consumption by widgets.
class StorefrontData {
  final Professional professional;
  final List<PortfolioItem> portfolio;
  final List<Review> reviews;
  final Map<int, int> ratingDistribution;

  StorefrontData({
    required this.professional,
    required this.portfolio,
    required this.reviews,
    required this.ratingDistribution,
  });
}
