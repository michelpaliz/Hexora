import 'dart:async';
import 'dart:convert';

import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class WeatherApiException implements Exception {
  final String message;
  final int? statusCode;

  const WeatherApiException(this.message, {this.statusCode});

  @override
  String toString() => 'WeatherApiException($statusCode): $message';
}

class WeatherForecastDayDto {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final double rainProbability;
  final double windSpeed;
  final String skyDescription;

  const WeatherForecastDayDto({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.rainProbability,
    required this.windSpeed,
    required this.skyDescription,
  });

  factory WeatherForecastDayDto.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date']?.toString() ?? '';
    final date = DateTime.tryParse(dateRaw);
    if (date == null) {
      throw const WeatherApiException('Invalid weather date in response');
    }

    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    return WeatherForecastDayDto(
      date: DateTime(date.year, date.month, date.day),
      minTemp: asDouble(json['minTemp']),
      maxTemp: asDouble(json['maxTemp']),
      rainProbability: asDouble(json['rainProbability']),
      windSpeed: asDouble(json['windSpeed']),
      skyDescription: (json['skyDescription']?.toString() ?? '').trim(),
    );
  }
}

class WeatherForecastResponseDto {
  final String location;
  final List<WeatherForecastDayDto> forecast;

  const WeatherForecastResponseDto({
    required this.location,
    required this.forecast,
  });

  factory WeatherForecastResponseDto.fromJson(Map<String, dynamic> json) {
    final rawForecast = json['forecast'];
    if (rawForecast is! List) {
      throw const WeatherApiException('Invalid weather response payload');
    }

    final days = rawForecast
        .whereType<Map>()
        .map((e) => WeatherForecastDayDto.fromJson(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return WeatherForecastResponseDto(
      location: (json['location']?.toString() ?? '').trim(),
      forecast: days,
    );
  }
}

class WeatherApiClient {
  final http.Client _httpClient;

  WeatherApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<WeatherForecastResponseDto> fetchDeniaForecast({int? days}) async {
    final uri = _weatherUri(days: days);

    http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const WeatherApiException('Weather request timed out');
    } catch (_) {
      throw const WeatherApiException('Failed to reach weather service');
    }

    if (response.statusCode != 200) {
      String message = 'Failed to load weather';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['error'] != null) {
          message = body['error'].toString();
        }
      } catch (_) {}
      throw WeatherApiException(message, statusCode: response.statusCode);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const WeatherApiException('Invalid weather response format');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const WeatherApiException('Unexpected weather response type');
    }

    return WeatherForecastResponseDto.fromJson(decoded);
  }

  Uri _weatherUri({int? days}) {
    final normalizedBase = _normalizeBase(ApiConstants.baseUrl);
    final baseWithApi = normalizedBase.endsWith('/api')
        ? normalizedBase
        : '$normalizedBase/api';
    final uri = Uri.parse('$baseWithApi/weather/denia');
    if (days == null || days <= 0) return uri;
    return uri.replace(queryParameters: {'days': days.toString()});
  }

  String _normalizeBase(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
    }
    if (trimmed.startsWith('/')) {
      final origin = Uri.base.origin;
      final v = trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
      return '$origin$v';
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  void dispose() {
    _httpClient.close();
  }
}
