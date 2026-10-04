class AffectedWeatherVisit {
  const AffectedWeatherVisit({
    required this.eventId,
    required this.title,
    required this.clientName,
    required this.startDate,
    required this.reasons,
    required this.temperature,
    required this.rainProbability,
    required this.windSpeed,
  });

  final String eventId;
  final String title;
  final String clientName;
  final DateTime startDate;
  final List<String> reasons;
  final double temperature;
  final double rainProbability;
  final double windSpeed;

  factory AffectedWeatherVisit.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as Map?)?.cast<String, dynamic>() ?? {};
    double number(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return AffectedWeatherVisit(
      eventId: json['eventId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      reasons: (json['reasons'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      temperature: number(weather['temperature']),
      rainProbability: number(weather['rainProbability']),
      windSpeed: number(weather['windSpeed']),
    );
  }
}

class WorkConditionResult {
  const WorkConditionResult({
    required this.rating,
    required this.affectedVisitCount,
    required this.outdoorVisitCount,
    required this.unavailableLocationCount,
    required this.reasons,
    required this.affectedVisits,
  });

  final String rating;
  final int affectedVisitCount;
  final int outdoorVisitCount;
  final int unavailableLocationCount;
  final List<String> reasons;
  final List<AffectedWeatherVisit> affectedVisits;

  factory WorkConditionResult.fromJson(Map<String, dynamic> json) {
    int integer(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return WorkConditionResult(
      rating: json['rating']?.toString() ?? 'good',
      affectedVisitCount: integer(json['affectedVisitCount']),
      outdoorVisitCount: integer(json['outdoorVisitCount']),
      unavailableLocationCount: integer(json['unavailableLocationCount']),
      reasons: (json['reasons'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      affectedVisits: (json['affectedVisits'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => AffectedWeatherVisit.fromJson(
                value.cast<String, dynamic>(),
              ))
          .toList(),
    );
  }
}
