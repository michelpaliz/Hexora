import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

class EventDataSource extends sf.CalendarDataSource {
  EventDataSource(List<Event> events) {
    appointments = events;
  }

  // Convenience to strongly-type the list
  List<Event> get _items => (appointments ?? const []) as List<Event>;

  @override
  DateTime getStartTime(int index) => _items[index].startDate;

  @override
  DateTime getEndTime(int index) => _items[index].endDate;

  @override
  String getSubject(int index) => _items[index].title;

  @override
  String? getLocation(int index) => _items[index].localization;

  @override
  Object? getId(int index) => _items[index].id;

  // Only return an RRULE string (without the "RRULE:" prefix)
  @override
  String? getRecurrenceRule(int index) {
    final ruleStr = _items[index].recurrenceRule?.toString();
    if (ruleStr == null) return null;
    final m = RegExp(r'RRULE:(.*)').firstMatch(ruleStr);
    return m?.group(1);
  }

  @override
  Color getColor(int index) {
    final colorIndex = _items[index].eventColorIndex;
    final predefined = ColorManager.eventColors;
    return (colorIndex >= 0 && colorIndex < predefined.length)
        ? predefined[colorIndex]
        : Colors.grey;
  }

  @override
  bool isAllDay(int index) => _items[index].allDay;
}
