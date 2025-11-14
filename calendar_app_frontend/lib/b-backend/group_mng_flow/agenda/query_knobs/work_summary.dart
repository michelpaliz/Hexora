/// Shapes for aggregated responses
class WorkSummary {
  final int totalEvents;
  final double totalMinutes;
  double get totalHours => totalMinutes / 60.0;

  WorkSummary({required this.totalEvents, required this.totalMinutes});

  factory WorkSummary.fromJson(Map<String, dynamic> j) => WorkSummary(
        totalEvents: (j['totalEvents'] ?? 0) as int,
        totalMinutes: ((j['totalMinutes'] ?? 0) as num).toDouble(),
      );

  @override
  String toString() =>
      'WorkSummary(events: $totalEvents, minutes: $totalMinutes, hours: $totalHours)';
}
