// lib/models/group_model/event_appointment/recurrence_rule/legacy_recurrence_rule.dart

import 'package:hexora/models/group_model/recurrence/utils/custom_day_week.dart';
import 'package:hexora/models/group_model/recurrence/utils/recurrence_rule_utils.dart'
    as utils;
import 'package:uuid/uuid.dart';

enum RecurrenceType { Daily, Weekly, Monthly, Yearly }

/// A simplified model for legacy recurrence rules.
/// Core serialization handled via [utils].
class LegacyRecurrenceRule {
  final String id;
  final String name;
  final List<CustomDayOfWeek>? daysOfWeek;
  final int? dayOfMonth;
  final int? month;
  final int? repeatInterval;
  final RecurrenceType recurrenceType;
  final DateTime? untilDate;

  LegacyRecurrenceRule({
    String? id,
    required this.name,
    this.daysOfWeek,
    this.dayOfMonth,
    this.month,
    this.repeatInterval,
    required this.recurrenceType,
    this.untilDate,
  }) : id = id ?? Uuid().v4();

  /// Internal guard: strip any untilDate before the event’s start.
  static DateTime? _safeUntil(DateTime? until, DateTime start) {
    if (until != null && until.isBefore(start)) return null;
    return until;
  }

  /// Daily recurrence.
  LegacyRecurrenceRule.daily({
    int? repeatInterval,
    DateTime? untilDate,
    required DateTime startDate,
  }) : this(
          name: 'Daily',
          recurrenceType: RecurrenceType.Daily,
          repeatInterval: repeatInterval,
          untilDate: _safeUntil(untilDate, startDate),
        );

  /// Weekly recurrence.
  LegacyRecurrenceRule.weekly(
    List<CustomDayOfWeek> daysOfWeek, {
    int? repeatInterval,
    DateTime? untilDate,
    required DateTime startDate,
  }) : this(
          name: 'Weekly',
          recurrenceType: RecurrenceType.Weekly,
          daysOfWeek: daysOfWeek,
          repeatInterval: repeatInterval,
          untilDate: _safeUntil(untilDate, startDate),
        );

  /// Monthly recurrence.
  LegacyRecurrenceRule.monthly({
    int? dayOfMonth,
    int? repeatInterval,
    DateTime? untilDate,
    required DateTime startDate,
  }) : this(
          name: 'Monthly',
          recurrenceType: RecurrenceType.Monthly,
          dayOfMonth: dayOfMonth,
          repeatInterval: repeatInterval,
          untilDate: _safeUntil(untilDate, startDate),
        );

  /// Yearly recurrence.
  LegacyRecurrenceRule.yearly({
    int? month,
    int? dayOfMonth,
    int? repeatInterval,
    DateTime? untilDate,
    required DateTime startDate,
  }) : this(
          name: 'Yearly',
          recurrenceType: RecurrenceType.Yearly,
          month: month,
          dayOfMonth: dayOfMonth,
          repeatInterval: repeatInterval,
          untilDate: _safeUntil(untilDate, startDate),
        );

  /// JSON serialization via shared utility.
  Map<String, dynamic> toJson() => utils.legacyRuleToMap(this);

  /// JSON deserialization via shared utility.
  factory LegacyRecurrenceRule.fromJson(Map<String, dynamic> json) =>
      utils.legacyRuleFromMap(json);

  /// Produce a well-formed RRULE string via shared utility.
  String toRRuleString(DateTime startDate, {bool includeDtStart = false}) =>
      utils.toRRuleStringUtils(this, startDate, includeDtStart: includeDtStart);

  @override
  String toString() =>
      'LegacyRecurrenceRule(id: $id, name: $name, type: $recurrenceType)';
}
