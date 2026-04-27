class Professional {
  final int id;
  final int userId;
  final String name;
  final String headline;
  final String bio;
  final int yearsOfExperience;
  final String pricingEstimate;
  final double? latitude;
  final double? longitude;
  final int serviceLocationRadiusKm;
  final String availabilityStatus;
  final double reputationScore;
  final int completedJobs;
  final double responseTimeHours;
  final double averageRating;
  final int reviewCount;
  final String? avatarUrl;
  final String location;
  final List<String> categories;
  final double? distance;

  Professional({
    required this.id,
    required this.userId,
    required this.name,
    required this.headline,
    required this.bio,
    required this.yearsOfExperience,
    required this.pricingEstimate,
    this.latitude,
    this.longitude,
    required this.serviceLocationRadiusKm,
    required this.availabilityStatus,
    required this.reputationScore,
    required this.completedJobs,
    required this.responseTimeHours,
    required this.averageRating,
    required this.reviewCount,
    this.avatarUrl,
    required this.location,
    required this.categories,
    this.distance,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    List<String> cats = [];
    if (json['categories'] is List) {
      cats = (json['categories'] as List).map((c) {
        if (c is Map) return c['name']?.toString() ?? '';
        return c.toString();
      }).where((s) => s.isNotEmpty).toList();
    } else if (json['category_names'] is String) {
      cats = (json['category_names'] as String).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return Professional(
      id: json['id'] ?? json['professional_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      headline: json['headline'] ?? '',
      bio: json['bio'] ?? '',
      yearsOfExperience: json['years_of_experience'] ?? 0,
      pricingEstimate: json['pricing_estimate']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      serviceLocationRadiusKm: json['service_location_radius_km'] ?? 25,
      availabilityStatus: json['availability_status'] ?? 'available',
      reputationScore: _toDouble(json['reputation_score']) ?? 0.0,
      completedJobs: json['completed_jobs'] ?? 0,
      responseTimeHours: _toDouble(json['response_time_hours']) ?? 24.0,
      averageRating: _toDouble(json['average_rating']) ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      avatarUrl: json['avatar_url'],
      location: json['location'] ?? '',
      categories: cats,
      distance: _toDouble(json['distance']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  bool get isAvailable => availabilityStatus == 'available';
}
