import 'api_service.dart';

/// Thin wrapper around the professional availability API.
class AvailabilityService {
  AvailabilityService._();

  /// Set the calling professional's availability.
  /// [available] true → status 'available', false → status 'offline'.
  static Future<void> setAvailable(bool available) async {
    await ApiService.post(
      '/professionals/me/availability',
      {'status': available ? 'available' : 'offline'},
      auth: true,
    );
  }

  /// Fetch current availability status ('available' | 'busy' | 'offline').
  static Future<String> getStatus() async {
    final res = await ApiService.get('/professionals/me/availability', auth: true);
    return res['availability_status']?.toString() ?? 'offline';
  }
}
