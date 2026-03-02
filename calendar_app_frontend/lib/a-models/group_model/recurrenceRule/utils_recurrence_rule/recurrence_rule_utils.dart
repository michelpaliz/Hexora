import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_of_week_extensions.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_week.dart';
import 'package:flutter/material.dart';

/// Converts a LegacyRecurrenceRule into a plain map.
Map<String, dynamic> legacyRuleToMap(LegacyRecurrenceRule rule) {
  final map = <String, dynamic>{
    'id': rule.id,
    'name': rule.name,
    'recurrenceType': rule.recurrenceType.name,
  };
  if (rule.daysOfWeek != null) {
    map['daysOfWeek'] = rule.daysOfWeek!.map((d) => d.name).toList();
  }
  if (rule.dayOfMonth != null) {
    map['dayOfMonth'] = rule.dayOfMonth;
  }
  if (rule.month != null) {
    map['month'] = rule.month;
  }
  if (rule.repeatInterval != null) {
    map['repeatInterval'] = rule.repeatInterval;
  }
  if (rule.untilDate != null) {
    map['untilDate'] = rule.untilDate!.toIso8601String();
  }
  return map;
}

/// Reconstructs a LegacyRecurrenceRule from the serialized map.
// LegacyRecurrenceRule legacyRuleFromMap(Map<String, dynamic> map) {
//   try {
//     final RecurrenceType recurrenceType = mapStringToRecurrenceType(
//       map['recurrenceType'] ?? map['name'],
//     );
//     final daysOfWeek = map['daysOfWeek'] != null
//         ? (map['daysOfWeek'] as List)
//             .map((d) => CustomDayOfWeek.fromString(d.toString()))
//             .toList()
//         : null;

//     return LegacyRecurrenceRule(
//       id: map['id'] as String?,
//       name: map['name'] as String? ?? '',
//       recurrenceType: recurrenceType,
//       daysOfWeek: daysOfWeek,
//       dayOfMonth: map['dayOfMonth'] as int?,
//       month: map['month'] as int?,
//       repeatInterval: map['repeatInterval'] as int?,
//       untilDate: map['untilDate'] != null
//           ? DateTime.tryParse(map['untilDate'] as String)
//           : null,
//     );
//   } catch (e) {
//     debugPrint("❌ Failed to parse LegacyRecurrenceRule: $e");
//     rethrow;
//   }
// }

LegacyRecurrenceRule legacyRuleFromMap(Map<String, dynamic> map) {
  try {
    final RecurrenceType recurrenceType = mapStringToRecurrenceType(
      map['recurrenceType'] ?? map['name'],
    );

    final daysOfWeek = (map['daysOfWeek'] as List?)
        ?.map((d) => CustomDayOfWeek.fromString(d.toString()))
        .toList();

    // ðŸ‘‡ handle either "id" or "_id"
    final ruleId = map['id'] ?? map['_id'];

    return LegacyRecurrenceRule(
      id: ruleId as String?, // <–––– here
      name: map['name'] as String? ?? '',
      recurrenceType: recurrenceType,
      daysOfWeek: daysOfWeek,
      dayOfMonth: map['dayOfMonth'] as int?,
      month: map['month'] as int?,
      repeatInterval: map['repeatInterval'] as int?,
      untilDate: map['untilDate'] != null
          ? DateTime.tryParse(map['untilDate'] as String)
          : null,
    );
  } catch (e, st) {
    debugPrint('❌ Failed to parse LegacyRecurrenceRule: $e');
    debugPrintStack(stackTrace: st);
    rethrow;
  }
}

/// Maps a string into the RecurrenceType enum.
RecurrenceType mapStringToRecurrenceType(String? value) {
  if (value == null) {
    throw FormatException('Missing recurrenceType or name in recurrenceRule');
  }
  switch (value.toLowerCase()) {
    case 'daily':
      return RecurrenceType.Daily;
    case 'weekly':
      return RecurrenceType.Weekly;
    case 'monthly':
      return RecurrenceType.Monthly;
    case 'yearly':
      return RecurrenceType.Yearly;
    default:
      throw FormatException('Unknown recurrenceType: $value');
  }
}

/// Builds a proper RRULE string from a LegacyRecurrenceRule and a start date.
///
/// If [includeDtStart] is true, emits a `DTSTART:` line first.
String toRRuleStringUtils(
  LegacyRecurrenceRule rule,
  DateTime startDate, {
  bool includeDtStart = false,
}) {
  final buffer = StringBuffer();

  if (includeDtStart) {
    final dt = startDate
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')
        .first;
    buffer.writeln('DTSTART:${dt}Z');
  }

  buffer.write('RRULE:FREQ=${rule.recurrenceType.name.toUpperCase()}');
  buffer.write(';INTERVAL=${rule.repeatInterval ?? 1}');

  // Only include UNTIL if it’s after the start date
  if (rule.untilDate != null && rule.untilDate!.isAfter(startDate)) {
    final until = rule.untilDate!
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')
        .first;
    buffer.write(';UNTIL=${until}Z');
  }

  if (rule.recurrenceType == RecurrenceType.Weekly) {
    if (rule.daysOfWeek == null || rule.daysOfWeek!.isEmpty) {
      throw FormatException('Weekly recurrence must have daysOfWeek defined.');
    }
    final days = rule.daysOfWeek!.map((d) => d.toRRuleDay()).join(',');
    buffer.write(';BYDAY=$days');
  }

  if ((rule.recurrenceType == RecurrenceType.Monthly ||
          rule.recurrenceType == RecurrenceType.Yearly) &&
      rule.dayOfMonth != null) {
    buffer.write(';BYMONTHDAY=${rule.dayOfMonth}');
  }

  if (rule.recurrenceType == RecurrenceType.Yearly && rule.month != null) {
    buffer.write(';BYMONTH=${rule.month}');
  }

  return buffer.toString();
}
