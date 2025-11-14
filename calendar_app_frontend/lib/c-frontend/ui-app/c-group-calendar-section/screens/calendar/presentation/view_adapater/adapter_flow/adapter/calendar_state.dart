// calendar_state.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/adapter_flow/event_data_source/event_data_source.dart';

class CalendarState {
  // UI notifiers
  final ValueNotifier<int> calendarRefreshKey = ValueNotifier(0);
  final ValueNotifier<List<Event>> dailyEvents = ValueNotifier([]);
  final ValueNotifier<List<Event>> allEvents = ValueNotifier([]);
  final ValueNotifier<EventDataSource> dataSource =
      ValueNotifier(EventDataSource(const []));

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
  List<Event> _last = const [];
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
  }

  bool applyEvents(List<Event> events) {
    final s = _signature(events);
    if (_sig == s) return false;

    _sig = s;
    _last = List<Event>.from(events);

    allEvents.value = _last;
    dataSource.value = EventDataSource(_last);

    if (selectedDate != null) {
      dailyEvents.value = eventsForDate(selectedDate!, _last);
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

  int _signature(List<Event> list) {
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
    return Object.hashAllUnordered(parts);
  }

  // -------- Navigation API --------
  /// Jump the logical selection and signal the view to move to [date].
  void jumpTo(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    selectedDate = d;
    dailyEvents.value = eventsForDate(d, _last); // keep side/day list in sync
    anchorDate.value = d; // tell CalendarSurface to scroll/jump
    // Optionally bump a rebuild if your surface needs it:
    // calendarRefreshKey.value = calendarRefreshKey.value + 1;
  }

  /// Convenience: jump to today.
  void jumpToToday() => jumpTo(DateTime.now());

  // // -------- NEW: View Mode API --------
  // /// Set the current view ('day' | 'week' | 'month' | 'agenda') and force a rebuild tick.
  // void setViewMode(String mode) {
  //   if (viewMode.value == mode) return;
  //   viewMode.value = mode;
  //   // Nudge listeners that rely on a simple int key:
  //   calendarRefreshKey.value = calendarRefreshKey.value + 1;
  // }

  // /// Read the current view mode.
  // String get currentViewMode => viewMode.value;
}
