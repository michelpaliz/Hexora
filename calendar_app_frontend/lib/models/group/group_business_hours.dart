import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Represents the time window where a group allows events to be scheduled.
class GroupBusinessHours {
  const GroupBusinessHours({
    this.start,
    this.end,
    this.timezone = 'Europe/Madrid',
  });

  final String? start; // HH:mm (24h)
  final String? end; // HH:mm (24h)
  final String timezone;

  static const _timePattern = r'^([01]\d|2[0-3]):([0-5]\d)$';
  static final RegExp _timeRegExp = RegExp(_timePattern);
  static bool _tzInitialized = false;

  bool get isConfigured =>
      start != null && start!.isNotEmpty && end != null && end!.isNotEmpty;

  factory GroupBusinessHours.fromJson(Map<String, dynamic> json) {
    return GroupBusinessHours(
      start: json['start']?.toString(),
      end: json['end']?.toString(),
      timezone: (json['timezone'] ?? 'Europe/Madrid').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'timezone': timezone,
    };
  }

  GroupBusinessHours copyWith({
    String? start,
    String? end,
    String? timezone,
  }) {
    return GroupBusinessHours(
      start: start ?? this.start,
      end: end ?? this.end,
      timezone: timezone ?? this.timezone,
    );
  }

  static void _ensureTimezoneData() {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    _tzInitialized = true;
  }

  List<int>? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = _timeRegExp.firstMatch(value);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    return [hour, minute];
  }

  /// Returns true when the provided range lives within the configured window.
  /// If the start or end is not configured, the check always passes.
  bool allows(DateTime startDate, DateTime endDate) {
    final parsedStart = _parseTime(start);
    final parsedEnd = _parseTime(end);
    if (parsedStart == null || parsedEnd == null) return true;

    _ensureTimezoneData();

    tz.Location location;
    try {
      location = tz.getLocation(timezone);
    } catch (_) {
      location = tz.local;
    }

    final localStart = tz.TZDateTime.from(startDate, location);
    final localEnd = tz.TZDateTime.from(endDate, location);

    final windowStart = tz.TZDateTime(
      location,
      localStart.year,
      localStart.month,
      localStart.day,
      parsedStart[0],
      parsedStart[1],
    );

    var windowEnd = tz.TZDateTime(
      location,
      windowStart.year,
      windowStart.month,
      windowStart.day,
      parsedEnd[0],
      parsedEnd[1],
    );

    if (windowEnd.isBefore(windowStart)) {
      windowEnd = windowEnd.add(const Duration(days: 1));
    }

    final startInWindow =
        !localStart.isBefore(windowStart) && !localStart.isAfter(windowEnd);
    final endInWindow =
        !localEnd.isBefore(windowStart) && !localEnd.isAfter(windowEnd);

    return startInWindow && endInWindow;
  }
}
