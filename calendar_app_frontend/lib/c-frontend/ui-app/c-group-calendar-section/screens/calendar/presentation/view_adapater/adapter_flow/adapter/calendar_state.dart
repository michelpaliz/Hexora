// calendar_state.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/adapter_flow/event_data_source/event_data_source.dart';

class CalendarState {
  // UI notifiers
  final ValueNotifier<int> calendarRefreshKey = ValueNotifier(0);
  final ValueNotifier<List<Event>> dailyEvents = ValueNotifier([]);
  final ValueNotifier<List<Event>> allEvents = ValueNotifier([]);
  final ValueNotifier<EventDataSource> dataSource =
      ValueNotifier(EventDataSource(const []));
  final ValueNotifier<Map<DateTime, DaySummary>> weatherForecast =
      ValueNotifier(const {});
  final ValueNotifier<bool> showWeatherIcons = ValueNotifier(true);
  final ValueNotifier<String?> eventFilterUserId = ValueNotifier<String?>(null);

  // /// NEW: current view mode ('day' | 'week' | 'month' | 'agenda')
  // final ValueNotifier<String> viewMode = ValueNotifier<String>('week');

  final ValueNotifier<String> viewMode = ValueNotifier('week');
  void setViewMode(String mode) {
    if (viewMode.value != mode) {
      viewMode.value = mode;
      calendarRefreshKey.value++;
    }
  }

  String get currentViewMode => viewMode.value;

  /// NEW: view navigation anchor — CalendarSurface listens to this and scrolls/jumps
  final ValueNotifier<DateTime> anchorDate =
      ValueNotifier<DateTime>(DateTime.now());

  // snapshot + signature
  List<Event> _rawEvents = const [];
  List<Event> _filteredEvents = const [];
  int? _sig;
  DateTime? selectedDate;

  // debounce
  Timer? _refreshDebounce;

  void dispose() {
    _refreshDebounce?.cancel();
    dailyEvents.dispose();
    allEvents.dispose();
    dataSource.dispose();
    calendarRefreshKey.dispose();
    anchorDate.dispose();
    viewMode.dispose(); // NEW
    weatherForecast.dispose();
    showWeatherIcons.dispose();
    eventFilterUserId.dispose();
  }

  bool applyEvents(List<Event> events) {
    _rawEvents = List<Event>.from(events);
    final filtered = _applyFilter(_rawEvents);
    final s = _signature(_rawEvents, eventFilterUserId.value);
    if (_sig == s) return false;

    _sig = s;
    _filteredEvents = filtered;

    allEvents.value = _filteredEvents;
    dataSource.value = EventDataSource(_filteredEvents);

    if (selectedDate != null) {
      dailyEvents.value = eventsForDate(selectedDate!, _filteredEvents);
    }
    return true;
  }

  List<Event> eventsForDate(DateTime date, List<Event> source) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return source
        .where((e) => e.startDate.isBefore(end) && e.endDate.isAfter(start))
        .toList();
  }

  void requestDebouncedRefresh(void Function() bumpKey) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 120), bumpKey);
  }

  int _signature(List<Event> list, String? filterUserId) {
    final filterHash = filterUserId?.hashCode ?? 0;
    final parts = list.map((e) => Object.hash(
          e.id,
          e.rawRuleId,
          e.startDate.millisecondsSinceEpoch,
          e.endDate.millisecondsSinceEpoch,
          e.title.hashCode,
          e.recurrenceRule?.hashCode ?? e.rule?.hashCode ?? 0,
          e.eventColorIndex,
          e.allDay ? 1 : 0,
        ));
    return Object.hash(filterHash, Object.hashAllUnordered(parts));
  }

  // -------- Navigation API --------
  /// Jump the logical selection and signal the view to move to [date].
  void jumpTo(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    selectedDate = d;
    dailyEvents.value =
        eventsForDate(d, _filteredEvents); // keep side/day list in sync
    anchorDate.value = d; // tell CalendarSurface to scroll/jump
    // Optionally bump a rebuild if your surface needs it:
    // calendarRefreshKey.value = calendarRefreshKey.value + 1;
  }

  /// Convenience: jump to today.
  void jumpToToday() => jumpTo(DateTime.now());

  void setWeatherForecast(Map<DateTime, DaySummary> forecast) {
    final normalized = {
      for (final entry in forecast.entries)
        DateTime(entry.key.year, entry.key.month, entry.key.day): entry.value,
    };
    weatherForecast.value = normalized;
  }

  void setShowWeatherIcons(bool value) {
    if (showWeatherIcons.value == value) return;
    showWeatherIcons.value = value;
  }

  void setEventFilter(String? userId) {
    final normalized =
        (userId == null || userId.trim().isEmpty) ? null : userId.trim();
    if (eventFilterUserId.value == normalized) return;
    eventFilterUserId.value = normalized;
    applyEvents(_rawEvents);
    calendarRefreshKey.value++;
  }

  String? get currentFilterUserId => eventFilterUserId.value;

  List<Event> _applyFilter(List<Event> events) {
    final uid = eventFilterUserId.value;
    if (uid == null || uid.isEmpty) return events;
    return events
        .where((e) =>
            (e.ownerId == uid) ||
            (e.recipients.any((r) => r.trim() == uid.trim())))
        .toList();
  }
}
