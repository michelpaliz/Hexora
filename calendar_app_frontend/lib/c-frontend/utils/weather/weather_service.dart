// lib/a-models/weather/weather_service.dart
import 'dart:convert';

import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  final DaySummary summary;
  final double tempMax;
  final double tempMin;
  final String? cityName;

  const WeatherSnapshot({
    required this.summary,
    required this.tempMax,
    required this.tempMin,
    this.cityName,
  });

  @override
  String toString() =>
      'WeatherSnapshot(tempMax: $tempMax, tempMin: $tempMin, cityName: $cityName)';
}

class _CachedForecast {
  final Map<DateTime, WeatherSnapshot> entries;
  final DateTime fetchedAt;

  const _CachedForecast({required this.entries, required this.fetchedAt});
}

/// Simple weather service backed by wttr.in (no API key required).
class WeatherService {
  static const _host = 'wttr.in';
  static const Duration _cacheTtl = Duration(hours: 1);
  static final Map<String, _CachedForecast> _cache = {};

  Future<WeatherSnapshot?> fetchDailySummary({
    required String location,
  }) async {
    final cleaned = _normalizeLocation(location);
    if (cleaned.isEmpty) {
      // debugPrint('[WeatherService] Empty location, skipping fetch');
      return null;
    }

    final forecast = await _getForecast(cleaned);
    if (forecast == null) return null;

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    WeatherSnapshot? snapshot;
    for (final entry in forecast.entries.entries) {
      if (!entry.key.isBefore(todayKey)) {
        snapshot = entry.value;
        break;
      }
    }
    if (snapshot == null && forecast.entries.values.isNotEmpty) {
      snapshot = forecast.entries.values.first;
    }
    return snapshot;
  }

  Future<Map<DateTime, DaySummary>> fetchForecastSummaries({
    required String location,
    int days = 3,
  }) async {
    final cleaned = _normalizeLocation(location);
    if (cleaned.isEmpty) return const {};

    final forecast = await _getForecast(cleaned);
    if (forecast == null) return const {};

    final entries = forecast.entries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final limited = entries.take(days);
    return {
      for (final entry in limited) entry.key: entry.value.summary,
    };
  }

  String? _buildLocationLabel(Map<String, dynamic> data, String fallback) {
    final nearest = data['nearest_area'];
    if (nearest is! List || nearest.isEmpty) return fallback;
    final first = nearest.first;
    if (first is! Map<String, dynamic>) return fallback;

    final pieces = <String>[];
    void addFromList(dynamic entry) {
      if (entry is List && entry.isNotEmpty) {
        final firstEntry = entry.first;
        if (firstEntry is Map && firstEntry['value'] != null) {
          final value = firstEntry['value'].toString().trim();
          if (value.isNotEmpty) pieces.add(value);
        }
      }
    }

    addFromList(first['areaName']);
    addFromList(first['region']);
    addFromList(first['country']);

    if (pieces.isEmpty) return fallback;
    return pieces.toSet().join(', ');
  }

  Future<_CachedForecast?> _getForecast(String cleaned) async {
    final now = DateTime.now();
    final cached = _cache[cleaned];
    if (cached != null && now.difference(cached.fetchedAt) <= _cacheTtl) {
      return cached;
    }

    final entries = await _downloadForecast(cleaned);
    if (entries == null) {
      return cached;
    }

    final newCache =
        _CachedForecast(entries: entries, fetchedAt: DateTime.now());
    _cache[cleaned] = newCache;
    return newCache;
  }

  Future<Map<DateTime, WeatherSnapshot>?> _downloadForecast(
      String cleaned) async {
    final uri = Uri.https(
      _host,
      '/${Uri.encodeComponent(cleaned)}',
      {'format': 'j1'},
    );

    http.Response response;
    try {
      response = await http.get(uri);
    } catch (_) {
      return null; // network/TLS issues: skip weather silently
    }
    if (response.statusCode != 200) return null;

    final Map<String, dynamic> body = jsonDecode(response.body);
    final weatherList = body['weather'];
    if (weatherList is! List || weatherList.isEmpty) return null;

    final cityName = _buildLocationLabel(body, cleaned);
    final map = <DateTime, WeatherSnapshot>{};

    for (final item in weatherList) {
      if (item is! Map<String, dynamic>) continue;
      final dateStr = item['date']?.toString();
      DateTime? date;
      if (dateStr != null) {
        date = DateTime.tryParse(dateStr);
      }
      date ??= DateTime.now();
      final normalized = DateTime(date.year, date.month, date.day);

      final max = double.tryParse(item['maxtempC']?.toString() ?? '');
      final min = double.tryParse(item['mintempC']?.toString() ?? '');
      if (max == null || min == null) continue;

      final hourly = item['hourly'];
      Map<String, dynamic>? midday;
      if (hourly is List && hourly.isNotEmpty) {
        final index = (hourly.length / 2).floor();
        midday =
            hourly[index.clamp(0, hourly.length - 1)] as Map<String, dynamic>;
      }

      final weatherCode =
          int.tryParse(midday?['weatherCode']?.toString() ?? '') ?? 0;
      final precip =
          double.tryParse(midday?['precipMM']?.toString() ?? '') ?? 0.0;

      final summary = mapToDaySummary(
        weatherCode: weatherCode,
        precip: precip,
        tempMax: max,
        tempMin: min,
      );

      map[normalized] = WeatherSnapshot(
        summary: summary,
        tempMax: max,
        tempMin: min,
        cityName: cityName,
      );
    }

    if (map.isEmpty) return null;
    return map;
  }

  /// Some locations arrive already percent-encoded (e.g. `D%C3%A9nia`).
  /// Decode once before encoding again to avoid double-encoding in the URL.
  String _normalizeLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return trimmed;
    // Replace bad % sequences so decodeComponent doesn't throw.
    final sanitized =
        trimmed.replaceAllMapped(RegExp(r'%(?![0-9A-Fa-f]{2})'), (_) => '%25');
    try {
      return Uri.decodeComponent(sanitized);
    } catch (_) {
      // Last resort: strip any trailing incomplete percent encodings entirely.
      return sanitized.replaceAll(RegExp(r'%(?![0-9A-Fa-f]{2})'), '');
    }
  }
}
