import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<List<Placemark>> _placemarkFromCoordinatesSafe(
    double latitude,
    double longitude,
  ) async {
    if (kIsWeb) {
      // The geocoding web implementation can throw internal null-check errors.
      // Keep location flow stable and skip reverse geocoding on web for now.
      return const <Placemark>[];
    }
    try {
      return await placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      debugPrint('[LocationService] Reverse geocoding failed: $e');
      return const <Placemark>[];
    }
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationService] Location services are disabled.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] Location permission denied.');
      return false;
    }

    return true;
  }

  Future<String?> getCurrentCityName() async {
    final allowed = await _ensurePermission();
    if (!allowed) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      debugPrint(
          '[LocationService] Position lat=${position.latitude}, lon=${position.longitude}');

      final placemarks = await _placemarkFromCoordinatesSafe(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String?>[
        place.locality,
        place.subAdministrativeArea,
        place.country,
      ].where((p) => p != null && p.trim().isNotEmpty).toList();

      final label = parts.join(', ');
      debugPrint('[LocationService] Resolved city: "$label"');
      return label.isEmpty ? null : label;
    } catch (e) {
      debugPrint('[LocationService] Error resolving city: $e');
      return null;
    }
  }
}
