export 'story.dart';
export 'follow.dart';
export 'user_points.dart';
export 'badge.dart';
export 'community_post.dart';
export 'featured_slot.dart';

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
  // Storefront fields
  final String? announcement;
  final String? whatsappNumber;
  final String? instagramHandle;
  final String? websiteUrl;
  final String? coverImageUrl;
  final String? accentColor;
  final bool showRating;
  final String? returnPolicy;
  final String? operatingHours;
  final String? operatingDays;

  Professional({
    required this.id, this.userId, required this.name, this.email, this.location,
    this.headline, this.bio, this.yearsOfExperience, this.pricingEstimate,
    this.availabilityStatus, this.averageRating = 0, this.reviewCount = 0,
    this.completedJobs = 0, this.responseTimeHours, this.subscriptionPlan,
    this.categories = const [], this.distance,
    this.kycLevel = 0, this.trustScore = 0, this.govIdVerified = false,
    this.announcement, this.whatsappNumber, this.instagramHandle,
    this.websiteUrl, this.coverImageUrl, this.accentColor,
    this.showRating = true, this.returnPolicy, this.operatingHours, this.operatingDays,
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
    announcement: _toStringOrNull(json['announcement']),
    whatsappNumber: _toStringOrNull(json['whatsapp_number']),
    instagramHandle: _toStringOrNull(json['instagram_handle']),
    websiteUrl: _toStringOrNull(json['website_url']),
    coverImageUrl: _toStringOrNull(json['cover_image_url']),
    accentColor: _toStringOrNull(json['accent_color']),
    showRating: json['show_rating'] != false,
    returnPolicy: _toStringOrNull(json['return_policy']),
    operatingHours: _toStringOrNull(json['operating_hours']),
    operatingDays: _toStringOrNull(json['operating_days']),
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

class Booking {
  final String id;
  final String customerId;
  final String professionalId;
  final int? categoryId;
  final String title;
  final String? description;
  final String? serviceAddress;
  final DateTime? scheduledFor;
  final double? quotedAmount;
  final double? finalAmount;
  final String currency;
  final String status;
  final String? cancellationReason;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined fields
  final String? customerName;
  final String? customerAvatar;
  final String? professionalName;
  final String? professionalAvatar;
  final String? categoryName;
  final List<BookingStatusLog> statusLog;

  Booking({
    required this.id, required this.customerId, required this.professionalId,
    this.categoryId, required this.title, this.description, this.serviceAddress,
    this.scheduledFor, this.quotedAmount, this.finalAmount, this.currency = 'INR',
    required this.status, this.cancellationReason, this.startedAt, this.completedAt,
    required this.createdAt, required this.updatedAt,
    this.customerName, this.customerAvatar, this.professionalName, this.professionalAvatar,
    this.categoryName, this.statusLog = const [],
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id']?.toString() ?? '',
    customerId: json['customer_id']?.toString() ?? '',
    professionalId: json['professional_id']?.toString() ?? '',
    categoryId: json['category_id'] == null ? null : _toInt(json['category_id']),
    title: json['title']?.toString() ?? '',
    description: _toStringOrNull(json['description']),
    serviceAddress: _toStringOrNull(json['service_address']),
    scheduledFor: json['scheduled_for'] == null ? null : _toDate(json['scheduled_for']),
    quotedAmount: json['quoted_amount'] == null ? null : _toDouble(json['quoted_amount']),
    finalAmount: json['final_amount'] == null ? null : _toDouble(json['final_amount']),
    currency: json['currency']?.toString() ?? 'INR',
    status: json['status']?.toString() ?? 'requested',
    cancellationReason: _toStringOrNull(json['cancellation_reason']),
    startedAt: json['started_at'] == null ? null : _toDate(json['started_at']),
    completedAt: json['completed_at'] == null ? null : _toDate(json['completed_at']),
    createdAt: _toDate(json['created_at']),
    updatedAt: _toDate(json['updated_at']),
    customerName: _toStringOrNull(json['customer_name']),
    customerAvatar: _toStringOrNull(json['customer_avatar']),
    professionalName: _toStringOrNull(json['professional_name']),
    professionalAvatar: _toStringOrNull(json['professional_avatar']),
    categoryName: _toStringOrNull(json['category_name']),
    statusLog: (json['status_log'] as List?)?.map((e) => BookingStatusLog.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
  );
}

class BookingStatusLog {
  final String id;
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final String? changedByName;
  final DateTime createdAt;

  BookingStatusLog({required this.id, this.fromStatus, required this.toStatus, this.note, this.changedByName, required this.createdAt});

  factory BookingStatusLog.fromJson(Map<String, dynamic> json) => BookingStatusLog(
    id: json['id']?.toString() ?? '',
    fromStatus: _toStringOrNull(json['from_status']),
    toStatus: json['to_status']?.toString() ?? '',
    note: _toStringOrNull(json['note']),
    changedByName: _toStringOrNull(json['changed_by_name']),
    createdAt: _toDate(json['created_at']),
  );
}

class MessageThread {
  final String id;
  final String customerId;
  final String professionalId;
  final String? bookingId;
  final int customerUnread;
  final int proUnread;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final String? otherName;
  final String? otherAvatar;
  final String? bookingTitle;

  MessageThread({
    required this.id, required this.customerId, required this.professionalId, this.bookingId,
    this.customerUnread = 0, this.proUnread = 0, this.lastMessage, this.lastSenderId,
    this.lastMessageAt, this.otherName, this.otherAvatar, this.bookingTitle,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
    id: json['id']?.toString() ?? '',
    customerId: json['customer_id']?.toString() ?? '',
    professionalId: json['professional_id']?.toString() ?? '',
    bookingId: _toStringOrNull(json['booking_id']),
    customerUnread: _toInt(json['customer_unread']),
    proUnread: _toInt(json['pro_unread']),
    lastMessage: _toStringOrNull(json['last_message']),
    lastSenderId: _toStringOrNull(json['last_sender_id']),
    lastMessageAt: json['last_message_at'] == null ? null : _toDate(json['last_message_at']),
    otherName: _toStringOrNull(json['other_name']),
    otherAvatar: _toStringOrNull(json['other_avatar']),
    bookingTitle: _toStringOrNull(json['booking_title']),
  );
}

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final String messageType;
  final bool isSystem;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? senderName;

  ChatMessage({
    required this.id, required this.threadId, required this.senderId,
    required this.body, this.messageType = 'text', this.isSystem = false,
    this.readAt, required this.createdAt, this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ?? '',
    threadId: json['thread_id']?.toString() ?? '',
    senderId: json['sender_id']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    messageType: json['message_type']?.toString() ?? 'text',
    isSystem: json['is_system'] == true || json['message_type'] == 'system',
    readAt: json['read_at'] == null ? null : _toDate(json['read_at']),
    createdAt: _toDate(json['created_at']),
    senderName: _toStringOrNull(json['sender_name']),
  );
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final String? relatedId;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id, required this.type, required this.title, this.body,
    this.relatedId, this.data = const {}, this.readAt, required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    body: _toStringOrNull(json['body']),
    relatedId: _toStringOrNull(json['related_id']),
    data: (json['data'] as Map<String, dynamic>?) ?? const {},
    readAt: json['read_at'] == null ? null : _toDate(json['read_at']),
    createdAt: _toDate(json['created_at']),
  );
}
