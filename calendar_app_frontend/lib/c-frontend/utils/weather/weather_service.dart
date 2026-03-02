import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/c-frontend/utils/weather/weather_api_client.dart';

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

class WeatherForecastDayView {
  final DateTime date;
  final String summary;
  final String emoji;
  final double minTemp;
  final double maxTemp;
  final double rainProbability;
  final double windSpeed;

  const WeatherForecastDayView({
    required this.date,
    required this.summary,
    required this.emoji,
    required this.minTemp,
    required this.maxTemp,
    required this.rainProbability,
    required this.windSpeed,
  });
}

class WeatherBundle {
  final WeatherSnapshot? today;
  final List<WeatherForecastDayView> forecast;

  const WeatherBundle({
    required this.today,
    required this.forecast,
  });
}

class _CachedForecast {
  final Map<DateTime, WeatherSnapshot> entries;
  final List<WeatherForecastDayView> forecastDays;
  final DateTime fetchedAt;

  const _CachedForecast({
    required this.entries,
    required this.forecastDays,
    required this.fetchedAt,
  });
}

class WeatherService {
  static const Duration _cacheTtl = Duration(hours: 1);
  static final Map<String, _CachedForecast> _cache = {};
  final WeatherApiClient _apiClient;

  WeatherService({WeatherApiClient? apiClient})
      : _apiClient = apiClient ?? WeatherApiClient();

  void dispose() {
    _apiClient.dispose();
  }

  Future<WeatherBundle> fetchWeatherBundle({
    required String location,
    int days = 3,
  }) async {
    final cleaned = _normalizeLocation(location);
    if (cleaned.isEmpty) {
      return const WeatherBundle(today: null, forecast: []);
    }

    final cache = await _getForecast(cleaned);
    if (cache == null) {
      return const WeatherBundle(today: null, forecast: []);
    }

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    WeatherSnapshot? snapshot;
    for (final entry in cache.entries.entries) {
      if (!entry.key.isBefore(todayKey)) {
        snapshot = entry.value;
        break;
      }
    }
    snapshot ??= cache.entries.values.isNotEmpty ? cache.entries.values.first : null;

    return WeatherBundle(
      today: snapshot,
      forecast: cache.forecastDays.take(days).toList(),
    );
  }

  Future<WeatherSnapshot?> fetchDailySummary({
    required String location,
  }) async {
    return (await fetchWeatherBundle(location: location)).today;
  }

  Future<Map<DateTime, DaySummary>> fetchForecastSummaries({
    required String location,
    int days = 3,
  }) async {
    final bundle = await fetchWeatherBundle(location: location, days: days);
    return {
      for (final day in bundle.forecast)
        DateTime(day.date.year, day.date.month, day.date.day): DaySummary(
          summary: day.summary,
          emoji: day.emoji,
          grade: 'B',
          isTooHot: day.maxTemp >= 30,
          isTooCold: day.minTemp <= 0,
        ),
    };
  }

  Future<List<WeatherForecastDayView>> fetchThreeDayForecast({
    required String location,
  }) async {
    final bundle = await fetchWeatherBundle(location: location, days: 3);
    return bundle.forecast;
  }

  Future<_CachedForecast?> _getForecast(String cleaned) async {
    final now = DateTime.now();
    final cached = _cache[cleaned];
    if (cached != null && now.difference(cached.fetchedAt) <= _cacheTtl) {
      return cached;
    }

    final downloaded = await _downloadForecast(cleaned);
    if (downloaded == null) {
      return cached;
    }

    final newCache = _CachedForecast(
      entries: downloaded.entries,
      forecastDays: downloaded.forecastDays,
      fetchedAt: DateTime.now(),
    );
    _cache[cleaned] = newCache;
    return newCache;
  }

  Future<_DownloadedForecast?> _downloadForecast(
      String cleaned) async {
    try {
      final dto = await _apiClient.fetchDeniaForecast();
      final cityName = dto.location.isNotEmpty ? dto.location : cleaned;

      final snapshots = <DateTime, WeatherSnapshot>{};
      final forecastDays = <WeatherForecastDayView>[];

      for (final day in dto.forecast) {
        final mapped = _mapSkyDescription(
          skyDescription: day.skyDescription,
          rainProbability: day.rainProbability,
          windSpeed: day.windSpeed,
          tempMax: day.maxTemp,
          tempMin: day.minTemp,
        );

        final normalized = DateTime(day.date.year, day.date.month, day.date.day);
        final summary = DaySummary(
          summary: mapped.summary,
          emoji: mapped.emoji,
          grade: mapped.grade,
          isTooHot: mapped.isTooHot,
          isTooCold: mapped.isTooCold,
        );

        snapshots[normalized] = WeatherSnapshot(
          summary: summary,
          tempMax: day.maxTemp,
          tempMin: day.minTemp,
          cityName: cityName,
        );

        forecastDays.add(
          WeatherForecastDayView(
            date: normalized,
            summary: mapped.summary,
            emoji: mapped.emoji,
            minTemp: day.minTemp,
            maxTemp: day.maxTemp,
            rainProbability: day.rainProbability,
            windSpeed: day.windSpeed,
          ),
        );
      }

      if (snapshots.isEmpty) return null;
      return _DownloadedForecast(entries: snapshots, forecastDays: forecastDays);
    } on WeatherApiException {
      return null;
    } catch (_) {
      return null;
    }
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

class _DownloadedForecast {
  final Map<DateTime, WeatherSnapshot> entries;
  final List<WeatherForecastDayView> forecastDays;

  const _DownloadedForecast({
    required this.entries,
    required this.forecastDays,
  });
}

class _MappedSkySummary {
  final String summary;
  final String emoji;
  final String grade;
  final bool isTooHot;
  final bool isTooCold;

  const _MappedSkySummary({
    required this.summary,
    required this.emoji,
    required this.grade,
    required this.isTooHot,
    required this.isTooCold,
  });
}

_MappedSkySummary _mapSkyDescription({
  required String skyDescription,
  required double rainProbability,
  required double windSpeed,
  required double tempMax,
  required double tempMin,
}) {
  final text = skyDescription.toLowerCase();
  final isHot = tempMax >= 30;
  final isCold = tempMin <= 0;

  if (text.contains('storm') || text.contains('torment')) {
    return _MappedSkySummary(
      summary: 'Stormy',
      emoji: '\u26c8\ufe0f',
      grade: 'D',
      isTooHot: isHot,
      isTooCold: isCold,
    );
  }
  if (text.contains('heavy') || text.contains('fuerte') || rainProbability >= 70) {
    return _MappedSkySummary(
      summary: 'Heavy rain',
      emoji: '\ud83c\udf27\ufe0f',
      grade: 'D',
      isTooHot: isHot,
      isTooCold: isCold,
    );
  }
  if (text.contains('rain') || text.contains('lluvia') || rainProbability >= 35) {
    return _MappedSkySummary(
      summary: 'Light rain',
      emoji: '\ud83c\udf26\ufe0f',
      grade: 'C',
      isTooHot: isHot,
      isTooCold: isCold,
    );
  }
  if (text.contains('sun') || text.contains('solea') || text.contains('clear') || text.contains('despejad')) {
    return _MappedSkySummary(
      summary: 'Sunny',
      emoji: '\ud83c\udf1e',
      grade: 'A',
      isTooHot: isHot,
      isTooCold: isCold,
    );
  }
  if (text.trim().isEmpty && rainProbability <= 10 && windSpeed <= 20) {
    return _MappedSkySummary(
      summary: 'Sunny',
      emoji: '\ud83c\udf1e',
      grade: 'A',
      isTooHot: isHot,
      isTooCold: isCold,
    );
  }
  if (text.contains('partly') || text.contains('parcial')) {
    return _MappedSkySummary(
      summary: 'Partly cloudy',
      emoji: '\u26c5',
      grade: 'B',
      isTooHot: isHot,
      isTooCold: isCold,
    );
  }

  final windy = windSpeed >= 35;
  return _MappedSkySummary(
    summary: windy ? 'Cloudy with rain' : 'Cloudy',
    emoji: windy ? '\ud83c\udf26\ufe0f' : '\u2601\ufe0f',
    grade: windy ? 'C' : 'B',
    isTooHot: isHot,
    isTooCold: isCold,
  );
}

