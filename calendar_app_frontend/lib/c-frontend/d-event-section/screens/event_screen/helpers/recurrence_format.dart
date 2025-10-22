// lib/c-frontend/d-event-section/screens/event_detail/helpers/recurrence_format.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_week.dart';

String formatRecurrenceRule(
  LegacyRecurrenceRule? rule,
  DateTime start,
  Locale locale,
) {
  if (rule == null) return '';
  final lang = locale.languageCode.toLowerCase();

  // Map a CustomDayOfWeek -> short label via its shortName (fallback-safe).
  String dayShort(CustomDayOfWeek d) {
    // Normalize the incoming shortName to a 3-letter lowercase key.
    final raw = (d.shortName).trim();
    final key = raw.isEmpty
        ? ''
        : raw.substring(0, raw.length >= 3 ? 3 : raw.length).toLowerCase();

    // Keys we expect (based on English short names).
    const enMap = <String, String>{
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };
    const esMap = <String, String>{
      'mon': 'Lun',
      'tue': 'Mar',
      'wed': 'Mié',
      'thu': 'Jue',
      'fri': 'Vie',
      'sat': 'Sáb',
      'sun': 'Dom',
    };

    final map = (lang == 'es') ? esMap : enMap;

    // If the key matches our known ones, use it; else fall back to d.shortName.
    return map[key] ?? (raw.isEmpty ? (lang == 'es' ? '—' : '—') : raw);
  }

  String untilText(DateTime? until) {
    if (until == null) return '';
    final y = until.year.toString().padLeft(4, '0');
    final mo = until.month.toString().padLeft(2, '0');
    final da = until.day.toString().padLeft(2, '0');
    return (lang == 'es') ? ' hasta $da/$mo/$y' : ' until $y-$mo-$da';
  }

  final interval = rule.repeatInterval ?? 1;

  switch (rule.recurrenceType) {
    case RecurrenceType.Daily:
      return (lang == 'es')
          ? (interval == 1
                  ? 'Se repite a diario'
                  : 'Se repite cada $interval días') +
              untilText(rule.untilDate)
          : (interval == 1 ? 'Repeats daily' : 'Repeats every $interval days') +
              untilText(rule.untilDate);

    case RecurrenceType.Weekly:
      final days =
          (rule.daysOfWeek ?? <CustomDayOfWeek>[]).map(dayShort).join(', ');
      return (lang == 'es')
          ? ('Se repite semanalmente' +
              (days.isNotEmpty ? ' los $days' : '') +
              untilText(rule.untilDate))
          : ('Repeats weekly' +
              (days.isNotEmpty ? ' on $days' : '') +
              untilText(rule.untilDate));

    case RecurrenceType.Monthly:
      if (rule.dayOfMonth != null) {
        return (lang == 'es')
            ? 'Se repite mensualmente el día ${rule.dayOfMonth}${untilText(rule.untilDate)}'
            : 'Repeats monthly on day ${rule.dayOfMonth}${untilText(rule.untilDate)}';
      }
      return (lang == 'es')
          ? 'Se repite mensualmente${untilText(rule.untilDate)}'
          : 'Repeats monthly${untilText(rule.untilDate)}';

    case RecurrenceType.Yearly:
      final mo = rule.month?.toString().padLeft(2, '0');
      final da = rule.dayOfMonth?.toString().padLeft(2, '0');
      if (mo != null && da != null) {
        return (lang == 'es')
            ? 'Se repite anualmente el $da/$mo${untilText(rule.untilDate)}'
            : 'Repeats yearly on $mo/$da${untilText(rule.untilDate)}';
      }
      return (lang == 'es')
          ? 'Se repite anualmente${untilText(rule.untilDate)}'
          : 'Repeats yearly${untilText(rule.untilDate)}';
  }
}
