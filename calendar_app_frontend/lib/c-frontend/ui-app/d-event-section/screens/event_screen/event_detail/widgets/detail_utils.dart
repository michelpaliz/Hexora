import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/helpers/recurrence_format.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:intl/intl.dart';

/// yyyy MMMM d • HH:mm–HH:mm   OR   <start d HH:mm> — <end d HH:mm>
String formatDateRange(BuildContext context, DateTime start, DateTime end) {
  final startLocal = start.toLocal();
  final endLocal = end.toLocal();
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final sameDay = startLocal.year == endLocal.year &&
      startLocal.month == endLocal.month &&
      startLocal.day == endLocal.day;
  final d = DateFormat.yMMMMd(localeTag);
  final t = DateFormat.Hm(localeTag);
  return sameDay
      ? '${d.format(startLocal)} • ${t.format(startLocal)}–${t.format(endLocal)}'
      : '${d.format(startLocal)} ${t.format(startLocal)}  —  ${d.format(endLocal)} ${t.format(endLocal)}';
}

/// Map backend status → user-facing label (already localized by caller)
String statusLabelFor(
  String? status, {
  required String pending,
  required String inProgress,
  required String done,
  required String cancelled,
  required String overdue,
}) {
  switch ((status ?? '').toLowerCase()) {
    case 'in_progress':
      return inProgress;
    case 'done':
      return done;
    case 'cancelled':
      return cancelled;
    case 'overdue':
      return overdue;
    case 'pending':
    default:
      return pending;
  }
}

/// Map backend status → color
Color statusColorFor(String? status, ColorScheme cs) {
  switch ((status ?? '').toLowerCase()) {
    case 'in_progress':
      return cs.primary;
    case 'done':
      return Colors.teal;
    case 'cancelled':
      return cs.error;
    case 'overdue':
      return Colors.orange;
    case 'pending':
    default:
      return cs.secondary;
  }
}

/// Safe event color by palette index with theme fallback
Color safeEventColor(int index, ColorScheme cs) {
  final palette = ColorManager.eventColors;
  if (palette.isNotEmpty && index >= 0 && index < palette.length) {
    return palette[index];
  }
  return cs.primary;
}

/// Wrapper that uses your existing recurrence_format.dart
String buildRecurrenceText(
  LegacyRecurrenceRule? rule,
  DateTime start,
  Locale locale,
) {
  if (rule == null) return '';
  return formatRecurrenceRule(
      rule, start, locale); // <-- requires the import above
}
