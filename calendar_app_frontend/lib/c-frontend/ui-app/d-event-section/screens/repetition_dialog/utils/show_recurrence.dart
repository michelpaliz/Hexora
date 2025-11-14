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

    // 👇 Respect the rule’s UNTIL date if it exists
    final until = rule.until ?? range.end.toUtc();
    final effectiveUntil =
        until.isBefore(range.end.toUtc()) ? until : range.end.toUtc();

    // 👇 Expand only within correct bounds
    final allInstances = rule
        .getInstances(
          start: event.startDate.toUtc(),
          before: effectiveUntil,
        )
        .where((dt) =>
            dt.isAfter(range.start.toUtc()) ||
            dt.isAtSameMomentAs(range.start.toUtc()))
        .take(maxOccurrences);

    return allInstances.map((occStart) {
      final localStart = occStart.toLocal();
      return event.copyWith(
        id: '${event.id}-${occStart.microsecondsSinceEpoch}', // Fake ID for uniqueness
        startDate: localStart,
        endDate: localStart.add(duration),
        recurrenceRule: null, // ✅ Prevent infinite expansion
        rawRuleId: event.id, // ✅ Use real ID for fallback fetching
      );
    }).toList();
  } catch (e) {
    print('⚠️ Failed to parse RRULE for event "${event.title}": $e');
    return [event];
  }
}
