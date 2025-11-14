// lib/a-models/group_model/event/event_group_resolver.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/recurrenceRule/recurrence_rule_api_client.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/utils/show_recurrence.dart';

/// This class is responsible for resolving and expanding recurring events for a group.
/// It provides methods to hydrate events with recurrence rules, fetch and cache hydrated events for a group,
/// and expand recurring events into concrete occurrences within a specified range.
/// It also provides methods to manage the event cache.
class GroupEventResolver {
  final RecurrenceRuleApiClient _ruleService;

  GroupEventResolver({
    required RecurrenceRuleApiClient ruleService,
  }) : _ruleService = ruleService;

  // Optional lightweight cache for hydrated base events per group
  final Map<String, List<Event>> _cache = {};

  RecurrenceRuleApiClient get ruleService => _ruleService;

  /// Hydrate events that only have rawRuleId by fetching the rule objects.
  Future<List<Event>> hydrateRulesForEvents(List<Event> rawEvents) async {
    // Collect unique rule IDs that need hydration
    final ids = <String>{
      for (final e in rawEvents)
        if (e.recurrenceRule == null &&
            e.rawRuleId != null &&
            e.rawRuleId!.isNotEmpty)
          e.rawRuleId!,
    }.toList();

    if (ids.isEmpty) return rawEvents;

    final rules = await _ruleService.getRulesByIds(ids);
    final ruleMap = {for (final r in rules) r.id: r};

    return rawEvents.map((e) {
      if (e.recurrenceRule == null && e.rawRuleId != null) {
        final r = ruleMap[e.rawRuleId];
        if (r != null) {
          return e.copyWith(recurrenceRule: r);
        } else {
          debugPrint(
              '⚠️ Could NOT hydrate recurrence rule for "${e.title}", rawRuleId=${e.rawRuleId}');
        }
      }
      return e;
    }).toList();
  }

  /// Convenience: get hydrated events for a group using a fetcher (usually repo.getEventsByGroupId).
  Future<List<Event>> getHydratedEventsForGroup({
    required Group group,
    required Future<List<Event>> Function(String groupId) fetchBaseEvents,
    bool useCache = true,
  }) async {
    final gid = group.id;
    if (useCache && _cache.containsKey(gid)) return _cache[gid]!;

    final raw = await fetchBaseEvents(gid);
    final hydrated = await hydrateRulesForEvents(raw);

    _cache[gid] = hydrated;
    return hydrated;
  }

  /// Expand recurring events into concrete occurrences inside [range],
  /// using your existing `expandRecurringEventForRange` helper.
  List<Event> expandForRange({
    required List<Event> baseEvents,
    required DateTimeRange range,
    int maxOccurrences = 1000,
  }) {
    final out = <Event>[];
    for (final e in baseEvents) {
      final hasStringRule = (e.rule != null && e.rule!.trim().isNotEmpty);
      final hasObjRule = e.recurrenceRule != null;

      if (!hasStringRule && !hasObjRule) {
        // Non-recurring: include only if overlaps the window
        final overlaps =
            e.startDate.isBefore(range.end) && e.endDate.isAfter(range.start);
        if (overlaps) out.add(e);
      } else {
        // ✅ use your existing top-level expander (string RRULE-based)
        out.addAll(expandRecurringEventForRange(e, range,
            maxOccurrences: maxOccurrences));
        // If you later support object-rule expansion directly, dispatch here instead.
      }
    }
    // de-dup by id
    final map = {for (final e in out) e.id: e};
    return map.values.toList();
  }

  // Cache helpers
  void clearGroup(String id) => _cache.remove(id);
  void clearAll() => _cache.clear();
  void updateCache(String id, List<Event> list) => _cache[id] = list;
}
