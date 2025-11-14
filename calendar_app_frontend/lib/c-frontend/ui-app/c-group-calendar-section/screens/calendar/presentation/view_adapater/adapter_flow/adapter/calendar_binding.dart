// calendar_binding.dart
import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';

import 'calendar_state.dart';

class CalendarBinding {
  EventDomain _domain;
  final CalendarState state;

  VoidCallback? _listener;

  CalendarBinding(this._domain, this.state) {
    _listener = () => _onEvents(_domain.eventsNotifier.value);
    _domain.eventsNotifier.addListener(_listener!);

    // seed
    final seed = _domain.eventsNotifier.value;
    if (seed.isNotEmpty) _onEvents(seed);
  }

  void rebind(EventDomain next) {
    if (identical(_domain, next)) return;
    _domain.eventsNotifier.removeListener(_listener!);
    _domain = next;
    _domain.eventsNotifier.addListener(_listener!);
    _onEvents(_domain.eventsNotifier.value);
  }

  void _onEvents(List events) {
    final changed = state.applyEvents(events.cast());
    if (changed) {
      state.requestDebouncedRefresh(() => state.calendarRefreshKey.value++);
    }
  }

  void dispose() {
    if (_listener != null) {
      _domain.eventsNotifier.removeListener(_listener!);
    }
  }
}
