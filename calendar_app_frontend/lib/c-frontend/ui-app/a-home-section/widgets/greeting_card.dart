// lib/c-frontend/home/widgets/greeting_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/c-frontend/utils/location/location_service.dart';
import 'package:hexora/c-frontend/utils/weather/weather_greeting_card.dart';
import 'package:hexora/c-frontend/utils/weather/weather_service.dart';

class GreetingCard extends StatefulWidget {
  final User user;
  final DaySummary daySummary;
  final double tempMax;
  final double tempMin;

  const GreetingCard({
    super.key,
    required this.user,
    required this.daySummary,
    required this.tempMax,
    required this.tempMin,
  });

  @override
  State<GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  WeatherSnapshot? _snapshot;
  String? _resolvedLocation;

  @override
  void initState() {
    super.initState();
    _initWeather();
  }

  @override
  void didUpdateWidget(covariant GreetingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.location != widget.user.location) {
      debugPrint(
          '[GreetingCard] User changed or location changed. Refetching weather...');
      _initWeather();
    }
  }

  Future<void> _initWeather() async {
    final storedLocation = widget.user.location?.trim();
    if (storedLocation != null && storedLocation.isNotEmpty) {
      debugPrint(
          '[GreetingCard] Using stored user.location="$storedLocation" for weather.');
      _resolvedLocation = storedLocation;
      await _fetchWeather(storedLocation);
      return;
    }

    debugPrint(
        '[GreetingCard] No stored user.location. Attempting GPS-based lookup...');
    final gpsCity = await _locationService.getCurrentCityName();
    if (!mounted) return;

    if (gpsCity == null) {
      debugPrint(
          '[GreetingCard] Could not determine location from GPS. Using fallback data.');
      setState(() {
        _resolvedLocation = null;
        _snapshot = null;
      });
      return;
    }

    debugPrint('[GreetingCard] Auto-detected city: "$gpsCity"');
    _resolvedLocation = gpsCity;
    await _fetchWeather(gpsCity);
  }

  Future<void> _fetchWeather(String location) async {
    debugPrint(
        '[GreetingCard] _fetchWeather for userId=${widget.user.id}, using location="$location"');

    try {
      final result =
          await _weatherService.fetchDailySummary(location: location);

      if (!mounted) return;

      debugPrint('[GreetingCard] Weather fetch success. Snapshot: $result');
      setState(() {
        _snapshot = result;
      });
    } catch (e, st) {
      debugPrint('[GreetingCard] Weather fetch failed: $e');
      debugPrint('[GreetingCard] Stacktrace:\n$st');

      if (!mounted) return;

      setState(() {
        _snapshot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final displayName = (user.name.isNotEmpty ? user.name : user.userName);
    final prettyName = displayName.isEmpty
        ? 'User'
        : displayName[0].toUpperCase() + displayName.substring(1);

    final snapshot = _snapshot;
    final summary = snapshot?.summary ?? widget.daySummary;
    final tempMax = snapshot?.tempMax ?? widget.tempMax;
    final tempMin = snapshot?.tempMin ?? widget.tempMin;

    final location =
        snapshot?.cityName ?? _resolvedLocation ?? user.location?.trim();

    debugPrint(
        '[GreetingCard] build(): using summary=$summary tempMax=$tempMax tempMin=$tempMin location="$location" (hasSnapshot=${snapshot != null})');

    return WeatherGreetingCard(
      userName: prettyName,
      summary: summary,
      tempMax: tempMax,
      tempMin: tempMin,
      location: (location == null || location.isEmpty) ? null : location,
    );
  }
}
