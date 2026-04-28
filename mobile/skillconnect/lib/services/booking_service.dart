import '../models/models.dart';
import 'api_service.dart';

class BookingService {
  static Future<List<Booking>> list({String? status, String? role}) async {
    final qp = <String, String>{};
    if (status != null) qp['status'] = status;
    if (role != null) qp['role'] = role;
    final res = await ApiService.get('/bookings', auth: true, queryParams: qp.isEmpty ? null : qp);
    return (res['data'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Booking> get(String id) async {
    final res = await ApiService.get('/bookings/$id', auth: true);
    return Booking.fromJson(res['data'] as Map<String, dynamic>);
  }

  static Future<Booking> create({
    required String professionalId,
    required String title,
    String? description,
    int? categoryId,
    String? serviceAddress,
    DateTime? preferredDate,
  }) async {
    final body = <String, dynamic>{
      'professional_id': professionalId,
      'title': title,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (serviceAddress != null) 'service_address': serviceAddress,
      if (preferredDate != null) 'preferred_date': preferredDate.toIso8601String(),
    };
    final res = await ApiService.post('/bookings', body, auth: true);
    return Booking.fromJson(res['data'] as Map<String, dynamic>);
  }

  static Future<Booking> transition(String id, String to, {String? note, Map<String, dynamic>? payload}) async {
    final res = await ApiService.post('/bookings/$id/transition', {
      'to': to,
      if (note != null) 'note': note,
      if (payload != null) 'payload': payload,
    }, auth: true);
    return Booking.fromJson(res['data'] as Map<String, dynamic>);
  }
}

class MessagingService {
  static Future<List<MessageThread>> listThreads() async {
    final res = await ApiService.get('/messages/threads', auth: true);
    return (res['data'] as List).map((e) => MessageThread.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<MessageThread> openThread({String? professionalId, String? customerId, String? bookingId}) async {
    final res = await ApiService.post('/messages/threads', {
      if (professionalId != null) 'professional_id': professionalId,
      if (customerId != null) 'customer_id': customerId,
      if (bookingId != null) 'booking_id': bookingId,
    }, auth: true);
    return MessageThread.fromJson(res['data'] as Map<String, dynamic>);
  }

  static Future<List<ChatMessage>> listMessages(String threadId) async {
    final res = await ApiService.get('/messages/threads/$threadId', auth: true);
    return (res['data'] as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ChatMessage> sendMessage(String threadId, String body) async {
    final res = await ApiService.post('/messages/threads/$threadId', {'body': body}, auth: true);
    return ChatMessage.fromJson(res['data'] as Map<String, dynamic>);
  }
}

class NotificationsService {
  static Future<({List<AppNotification> items, int unreadCount})> list({bool unreadOnly = false}) async {
    final res = await ApiService.get('/notifications', auth: true,
        queryParams: unreadOnly ? {'unread_only': 'true'} : null);
    final items = (res['data'] as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    final unread = (res['unread_count'] as int?) ?? 0;
    return (items: items, unreadCount: unread);
  }

  static Future<int> unreadCount() async {
    final res = await ApiService.get('/notifications', auth: true, queryParams: {'unread_only': 'true'});
    return (res['unread_count'] as int?) ?? 0;
  }

  static Future<void> markRead(String id) =>
      ApiService.put('/notifications/$id/read', {}, auth: true);

  static Future<void> markAllRead() =>
      ApiService.put('/notifications/read-all', {}, auth: true);

  static Future<List<dynamic>> listFavorites() async {
    final res = await ApiService.get('/notifications/favorites', auth: true);
    return res['data'] as List;
  }

  static Future<bool> toggleFavorite(String professionalId) async {
    final res = await ApiService.post('/notifications/favorites/$professionalId', {}, auth: true);
    return res['favored'] as bool? ?? false;
  }
}
