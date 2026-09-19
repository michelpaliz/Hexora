// lib/models/calendar/events/event_utils.dart

import 'package:hexora/models/calendar/recurrence/legacy_recurrence_rule.dart';
import 'package:hexora/models/calendar/recurrence/utils/recurrence_rule_utils.dart';

/// Returns a JSON‐serializable map, or null if [rule] is null.
Map<String, dynamic>? mapRule(LegacyRecurrenceRule? rule) =>
    rule == null ? null : legacyRuleToMap(rule);

/// Parses a [LegacyRecurrenceRule] from a dynamic (Map or null).
LegacyRecurrenceRule? parseRule(dynamic data) {
  if (data == null) return null;
  // ensure it's a Map<String, dynamic>
  final map = Map<String, dynamic>.from(data as Map);
  return legacyRuleFromMap(map);
}

/// Returns a well-formed RRULE string, or null if [rule] is null.
String? ruleString(LegacyRecurrenceRule? rule, DateTime startDate) =>
    rule == null ? null : toRRuleStringUtils(rule, startDate);
