// Helper functions for safe type conversion from JSON
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
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Unknown',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: json['role']?.toString() ?? 'customer',
    location: _toStringOrNull(json['location']),
    avatarUrl: _toStringOrNull(json['avatar_url']),
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
    id: _toInt(json['id']),
    name: json['name']?.toString() ?? 'Unknown',
    description: _toStringOrNull(json['description']),
    parentId: json['parent_id'] == null ? null : _toInt(json['parent_id']),
    children: (json['children'] as List?)?.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList() ?? const [],
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
  final int kycLevel;
  final int trustScore;
  final bool govIdVerified;

  Professional({
    required this.id, this.userId, required this.name, this.email, this.location,
    this.headline, this.bio, this.yearsOfExperience, this.pricingEstimate,
    this.availabilityStatus, this.averageRating = 0, this.reviewCount = 0,
    this.completedJobs = 0, this.responseTimeHours, this.subscriptionPlan,
    this.categories = const [], this.distance,
    this.kycLevel = 0, this.trustScore = 0, this.govIdVerified = false,
  });

  factory Professional.fromJson(Map<String, dynamic> json) => Professional(
    id: json['id']?.toString() ?? '',
    userId: _toStringOrNull(json['user_id']),
    name: json['name']?.toString() ?? 'Unknown',
    email: _toStringOrNull(json['email']),
    location: _toStringOrNull(json['location']),
    headline: _toStringOrNull(json['headline']),
    bio: _toStringOrNull(json['bio']),
    yearsOfExperience: json['years_of_experience'] == null ? null : _toInt(json['years_of_experience']),
    pricingEstimate: _toStringOrNull(json['pricing_estimate']),
    availabilityStatus: _toStringOrNull(json['availability_status']),
    averageRating: _toDouble(json['average_rating']),
    reviewCount: _toInt(json['review_count']),
    completedJobs: _toInt(json['completed_jobs']),
    responseTimeHours: json['response_time_hours'] == null ? null : _toDouble(json['response_time_hours']),
    subscriptionPlan: _toStringOrNull(json['subscription_plan']),
    categories: (json['categories'] as List?)?.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList() ?? const [],
    distance: json['distance'] == null ? null : _toDouble(json['distance']),
    kycLevel: _toInt(json['kyc_level']),
    trustScore: _toInt(json['trust_score']),
    govIdVerified: json['government_id_verified'] == true || json['government_id_verified']?.toString() == 'true',
  );
}

class PortfolioItem {
  final String id;
  final String professionalId;
  final String title;
  final String? description;
  final String mediaType;
  final String mediaUrl;
  final DateTime createdAt;

  PortfolioItem({required this.id, required this.professionalId, required this.title, this.description, required this.mediaType, required this.mediaUrl, required this.createdAt});

  factory PortfolioItem.fromJson(Map<String, dynamic> json) => PortfolioItem(
    id: json['id']?.toString() ?? '',
    professionalId: json['professional_id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: _toStringOrNull(json['description']),
    mediaType: json['media_type']?.toString() ?? 'image',
    mediaUrl: json['media_url']?.toString() ?? '',
    createdAt: _toDate(json['created_at']),
  );
}

class Contact {
  final String id;
  final String customerId;
  final String professionalId;
  final String contactType;
  final String? message;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final String? professionalName;
  final String? customerEmail;

  Contact({required this.id, required this.customerId, required this.professionalId, required this.contactType, this.message, required this.status, required this.createdAt, this.customerName, this.professionalName, this.customerEmail});

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id']?.toString() ?? '',
    customerId: json['customer_id']?.toString() ?? '',
    professionalId: json['professional_id']?.toString() ?? '',
    contactType: json['contact_type']?.toString() ?? '',
    message: _toStringOrNull(json['message']),
    status: json['status']?.toString() ?? 'pending',
    createdAt: _toDate(json['created_at']),
    customerName: _toStringOrNull(json['customer_name']),
    professionalName: _toStringOrNull(json['professional_name']),
    customerEmail: _toStringOrNull(json['customer_email']),
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
    id: json['id']?.toString() ?? '',
    professionalId: json['professional_id']?.toString() ?? '',
    customerId: json['customer_id']?.toString() ?? '',
    reviewerName: _toStringOrNull(json['reviewer_name']),
    rating: _toInt(json['rating']),
    comment: _toStringOrNull(json['comment']),
    createdAt: _toDate(json['created_at']),
  );
}
