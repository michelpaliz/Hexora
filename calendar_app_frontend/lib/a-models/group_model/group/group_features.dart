import 'package:meta/meta.dart';

/// Must match backend TIME_ROUNDING_ENUM
enum TimeRoundingPreset { nearest5_tie05_down }

TimeRoundingPreset _presetFromJson(String? v) {
  switch (v) {
    case 'nearest5_tie05_down':
    default:
      return TimeRoundingPreset.nearest5_tie05_down;
  }
}

String presetToJson(TimeRoundingPreset p) {
  switch (p) {
    case TimeRoundingPreset.nearest5_tie05_down:
      return 'nearest5_tie05_down';
  }
}

@immutable
class TimeTrackingSettings {
  final bool enabled;
  final DateTime? enabledAt;
  final DateTime? disabledAt;
  final TimeRoundingPreset roundingPreset;
  final String currency; // e.g. "EUR"
  final double? defaultHourlyRate;

  const TimeTrackingSettings({
    required this.enabled,
    required this.roundingPreset,
    required this.currency,
    this.enabledAt,
    this.disabledAt,
    this.defaultHourlyRate,
  });

  factory TimeTrackingSettings.fromJson(Map<String, dynamic> json) {
    return TimeTrackingSettings(
      enabled: (json['enabled'] as bool?) ?? false,
      enabledAt:
          json['enabledAt'] != null ? DateTime.parse(json['enabledAt']) : null,
      disabledAt: json['disabledAt'] != null
          ? DateTime.parse(json['disabledAt'])
          : null,
      roundingPreset: _presetFromJson(json['roundingPreset'] as String?),
      currency: (json['currency'] as String?) ?? 'EUR',
      defaultHourlyRate: (json['defaultHourlyRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (enabledAt != null) 'enabledAt': enabledAt!.toIso8601String(),
        if (disabledAt != null) 'disabledAt': disabledAt!.toIso8601String(),
        'roundingPreset': presetToJson(roundingPreset),
        'currency': currency,
        if (defaultHourlyRate != null) 'defaultHourlyRate': defaultHourlyRate,
      };

  TimeTrackingSettings copyWith({
    bool? enabled,
    DateTime? enabledAt,
    DateTime? disabledAt,
    TimeRoundingPreset? roundingPreset,
    String? currency,
    double? defaultHourlyRate,
  }) {
    return TimeTrackingSettings(
      enabled: enabled ?? this.enabled,
      enabledAt: enabledAt ?? this.enabledAt,
      disabledAt: disabledAt ?? this.disabledAt,
      roundingPreset: roundingPreset ?? this.roundingPreset,
      currency: currency ?? this.currency,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
    );
  }

  @override
  String toString() =>
      'TimeTrackingSettings(enabled: $enabled, currency: $currency, '
      'roundingPreset: ${presetToJson(roundingPreset)}, defaultHourlyRate: $defaultHourlyRate)';
}

@immutable
class GroupFeatures {
  final TimeTrackingSettings timeTracking;

  const GroupFeatures({required this.timeTracking});

  factory GroupFeatures.fromJson(Map<String, dynamic> json) {
    final tt = json['timeTracking'] as Map<String, dynamic>?;
    return GroupFeatures(
      timeTracking: tt != null
          ? TimeTrackingSettings.fromJson(tt)
          : const TimeTrackingSettings(
              enabled: false,
              roundingPreset: TimeRoundingPreset.nearest5_tie05_down,
              currency: 'EUR',
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'timeTracking': timeTracking.toJson(),
      };

  GroupFeatures copyWith({TimeTrackingSettings? timeTracking}) =>
      GroupFeatures(timeTracking: timeTracking ?? this.timeTracking);

  @override
  String toString() => 'GroupFeatures($timeTracking)';
}
