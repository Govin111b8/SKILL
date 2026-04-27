class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? location;
  final String? avatarUrl;

  User({required this.id, required this.name, required this.email, required this.phone, required this.role, this.location, this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    phone: json['phone'] ?? '',
    role: json['role'],
    location: json['location'],
    avatarUrl: json['avatar_url'],
  );
}

class Category {
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final List<Category> children;

  Category({required this.id, required this.name, this.description, this.parentId, this.children = const []});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    parentId: json['parent_id'],
    children: (json['children'] as List?)?.map((c) => Category.fromJson(c)).toList() ?? [],
  );
}

class Professional {
  final String id;
  final String? userId;
  final String name;
  final String? email;
  final String? location;
  final String? headline;
  final String? bio;
  final int? yearsOfExperience;
  final String? pricingEstimate;
  final String? availabilityStatus;
  final double averageRating;
  final int reviewCount;
  final int completedJobs;
  final double? responseTimeHours;
  final String? subscriptionPlan;
  final List<Category> categories;
  final double? distance;

  Professional({
    required this.id, this.userId, required this.name, this.email, this.location,
    this.headline, this.bio, this.yearsOfExperience, this.pricingEstimate,
    this.availabilityStatus, this.averageRating = 0, this.reviewCount = 0,
    this.completedJobs = 0, this.responseTimeHours, this.subscriptionPlan,
    this.categories = const [], this.distance,
  });

  factory Professional.fromJson(Map<String, dynamic> json) => Professional(
    id: json['id'],
    userId: json['user_id'],
    name: json['name'] ?? 'Unknown',
    email: json['email'],
    location: json['location'],
    headline: json['headline'],
    bio: json['bio'],
    yearsOfExperience: json['years_of_experience'],
    pricingEstimate: json['pricing_estimate']?.toString(),
    availabilityStatus: json['availability_status'],
    averageRating: (json['average_rating'] ?? 0).toDouble(),
    reviewCount: int.tryParse(json['review_count']?.toString() ?? '0') ?? 0,
    completedJobs: json['completed_jobs'] ?? 0,
    responseTimeHours: (json['response_time_hours'] as num?)?.toDouble(),
    subscriptionPlan: json['subscription_plan'],
    categories: (json['categories'] as List?)?.map((c) => Category.fromJson(c)).toList() ?? [],
    distance: (json['distance'] as num?)?.toDouble(),
  );
}

class Review {
  final String id;
  final String professionalId;
  final String customerId;
  final String? reviewerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({required this.id, required this.professionalId, required this.customerId, this.reviewerName, required this.rating, this.comment, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'],
    professionalId: json['professional_id'],
    customerId: json['customer_id'],
    reviewerName: json['reviewer_name'],
    rating: json['rating'],
    comment: json['comment'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
