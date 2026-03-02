import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart' as rrule;

List<Event> expandRecurringEventForRange(
  Event event,
  DateTimeRange range, {
  int maxOccurrences = 100,
}) {
  final ruleString = event.rule;
  if (ruleString == null || ruleString.trim().isEmpty) return [event];

  final duration = event.endDate.difference(event.startDate);

  try {
    final rawRule = ruleString.split('\n').last.trim();
    final rrule.RecurrenceRule rule = rrule.RecurrenceRule.fromString(rawRule);

    final ruleStartUtc = event.startDate.toUtc();
    final rangeStartUtc = range.start.toUtc();
    final rangeEndUtc = range.end.toUtc();
    final until = rule.until ?? rangeEndUtc;

    final effectiveUntil = until.isBefore(rangeEndUtc) ? until : rangeEndUtc;

    if (effectiveUntil.isBefore(ruleStartUtc)) {
      debugPrint(
        "⚠️ Skipping expansion for '${event.title}': "
        "effectiveUntil (${effectiveUntil.toLocal()}) is before event start (${event.startDate})",
      );
      return [event];
    }

    final allInstances = rule
        .getInstances(
          start: ruleStartUtc,
          before: effectiveUntil.add(const Duration(days: 1)), // ⬅️ safe buffer
        )
        .where((dt) =>
            !dt.isBefore(rangeStartUtc)) // ⬅️ same as dt >= rangeStartUtc
        .take(maxOccurrences);

    final expanded = allInstances.map((occStart) {
      final localStart = occStart.toLocal();
      return event.copyWith(
        id: '${event.id}-${occStart.microsecondsSinceEpoch}',
        startDate: localStart,
        endDate: localStart.add(duration),
        recurrenceRule: null,
        rawRuleId: event.id,
      );
    }).toList();

    if (expanded.isEmpty) {
      debugPrint("⚠️ No expanded instances generated for: ${event.title}");
    } else {
      debugPrint(
        "ðŸ“… Expanded '${event.title}' to ${expanded.length} occurrences "
        "from ${expanded.first.startDate} to ${expanded.last.endDate}",
      );
    }

    return expanded;
  } catch (e) {
    debugPrint('⚠️ Failed to parse RRULE for event "${event.title}": $e');
    return [event];
  }
}
