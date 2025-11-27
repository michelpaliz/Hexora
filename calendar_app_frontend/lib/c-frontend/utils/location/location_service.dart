import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
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

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String?>[
        place.locality,
        place.subAdministrativeArea,
        place.country,
      ].where((p) => p != null && p!.trim().isNotEmpty).toList();

      final label = parts.join(', ');
      debugPrint('[LocationService] Resolved city: "$label"');
      return label.isEmpty ? null : label;
    } catch (e, st) {
      debugPrint('[LocationService] Error resolving city: $e');
      debugPrint('$st');
      return null;
    }
  }
}
