import 'package:flutter/material.dart';

/// Deep link routing configuration for SkillConnect.
/// Supports links like:
///   skillconnect://professional/{id}
///   skillconnect://booking/{id}
///   skillconnect://service/{categoryId}
///   https://skillconnect.app/professional/{id}
///   https://skillconnect.app/booking/{id}
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Parse a deep link URI and return the corresponding route settings.
  static RouteSettings? parse(Uri uri) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return null;

    switch (pathSegments[0]) {
      case 'professional':
        if (pathSegments.length >= 2) {
          return RouteSettings(name: '/professional', arguments: pathSegments[1]);
        }
        break;
      case 'booking':
        if (pathSegments.length >= 2) {
          return RouteSettings(name: '/booking', arguments: {'bookingId': pathSegments[1]});
        }
        break;
      case 'service':
      case 'category':
        if (pathSegments.length >= 2) {
          final id = int.tryParse(pathSegments[1]);
          if (id != null) {
            return RouteSettings(
              name: '/category',
              arguments: {'categoryId': id, 'categoryName': pathSegments.length > 2 ? pathSegments[2] : ''},
            );
          }
        }
        break;
      case 'search':
        final query = uri.queryParameters['q'];
        return RouteSettings(name: '/search', arguments: {'query': query});
      case 'emergency':
        return const RouteSettings(name: '/emergency');
      case 'referral':
        final code = uri.queryParameters['code'];
        return RouteSettings(name: '/referral', arguments: {'code': code});
    }
    return null;
  }

  /// Generate a shareable link for a professional profile.
  static String professionalLink(String professionalId, String name) {
    return 'https://skillconnect.app/professional/$professionalId';
  }

  /// Generate a shareable link for a service category.
  static String categoryLink(int categoryId, String name) {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'https://skillconnect.app/service/$categoryId/$slug';
  }

  /// Generate a shareable link for a booking (for sharing receipt/confirmation).
  static String bookingLink(String bookingId) {
    return 'https://skillconnect.app/booking/$bookingId';
  }
}
