import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api_service.dart';
import '../../models/models.dart';

/// Smart location service that provides:
/// - Auto-detect user location
/// - Real-time nearby available providers
/// - Proximity-based ranking
/// - Background location updates during active bookings
class SmartLocationService extends ChangeNotifier {
  SmartLocationService._();
  static final SmartLocationService instance = SmartLocationService._();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  List<Professional> _nearbyProviders = [];
  List<Professional> get nearbyProviders => _nearbyProviders;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  double _radiusKm = 10.0;
  double get radiusKm => _radiusKm;
  set radiusKm(double value) {
    _radiusKm = value;
    if (_currentPosition != null) refreshNearbyProviders();
  }

  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionStream;

  /// Initialize and auto-detect location
  Future<void> init() async {
    await _detectLocation();
    // Auto-refresh nearby providers every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_currentPosition != null) refreshNearbyProviders();
    });
  }

  /// Detect current location with permission handling
  Future<bool> _detectLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied';
        notifyListeners();
        return false;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // Only update when moved 100m
        ),
      );
      _error = null;
      notifyListeners();
      await refreshNearbyProviders();
      return true;
    } catch (e) {
      _error = 'Could not detect location: $e';
      notifyListeners();
      return false;
    }
  }

  /// Force refresh location
  Future<void> refreshLocation() async {
    await _detectLocation();
  }

  /// Fetch nearby available providers with proximity-based ranking
  Future<void> refreshNearbyProviders() async {
    if (_currentPosition == null) return;
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('/search', queryParams: {
        'lat': _currentPosition!.latitude.toString(),
        'lng': _currentPosition!.longitude.toString(),
        'radius': _radiusKm.toString(),
        'sort_by': 'distance',
        'available_now': 'true',
        'limit': '20',
      });
      _nearbyProviders = (res['data'] as List)
          .map((e) => Professional.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Could not load nearby providers';
    }

    _loading = false;
    notifyListeners();
  }

  /// Start live tracking during an active booking (provider location updates)
  void startLiveTracking() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  /// Stop live tracking
  void stopLiveTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Calculate distance between user and a provider
  double? distanceTo(double lat, double lng) {
    if (_currentPosition == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000; // Return in km
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
