class Review {
  final int id;
  final int professionalId;
  final int customerId;
  final int contactId;
  final int rating;
  final String comment;
  final String reviewerName;
  final String createdAt;

  Review({
    required this.id,
    required this.professionalId,
    required this.customerId,
    required this.contactId,
    required this.rating,
    required this.comment,
    required this.reviewerName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      professionalId: json['professional_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      contactId: json['contact_id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      reviewerName: json['reviewer_name'] ?? json['name'] ?? 'Anonymous',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PortfolioItem {
  final int id;
  final int professionalId;
  final String title;
  final String description;
  final String mediaType;
  final String mediaUrl;

  PortfolioItem({
    required this.id,
    required this.professionalId,
    required this.title,
    required this.description,
    required this.mediaType,
    required this.mediaUrl,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] ?? 0,
      professionalId: json['professional_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      mediaUrl: json['media_url'] ?? '',
    );
  }
}

class Contact {
  final int id;
  final int customerId;
  final int professionalId;
  final String contactType;
  final String message;
  final String status;
  final String createdAt;
  final String? professionalName;
  final String? customerName;

  Contact({
    required this.id,
    required this.customerId,
    required this.professionalId,
    required this.contactType,
    required this.message,
    required this.status,
    required this.createdAt,
    this.professionalName,
    this.customerName,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      professionalId: json['professional_id'] ?? 0,
      contactType: json['contact_type'] ?? 'message',
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      professionalName: json['professional_name'],
      customerName: json['customer_name'],
    );
  }
}
