// agenda_model.dart
import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/events/event.dart';

/// A lightweight view-model for the Agenda UI.
class AgendaItem {
  final Event event;
  final Color color;       // derived from event.eventColorIndex
  final String? groupName; // optional (if you enrich from backend)

  AgendaItem({
    required this.event,
    required this.color,
    this.groupName,
  });

  DateTime get startLocal => event.startDate.toLocal();
  DateTime get endLocal   => event.endDate.toLocal();
  String get title        => event.title;
  String? get groupId     => event.groupId;
}

/// Map eventColorIndex → a display color.
/// Swap this palette with your theme’s color system if you prefer.
Color agendaColorFromIndex(ThemeData theme, int idx) {
  const palette = <Color>[
    Colors.indigo,
    Colors.teal,
    Colors.deepPurple,
    Colors.orange,
    Colors.pink,
    Colors.blueGrey,
    Colors.cyan,
    Colors.green,
  ];
  if (idx >= 0 && idx < palette.length) return palette[idx];
  return theme.colorScheme.primary;
}

/// Convert raw Events → AgendaItems (colors via eventColorIndex).
List<AgendaItem> buildAgendaItems(List<Event> events, ThemeData theme) {
  return events.map((ev) {
    final color = agendaColorFromIndex(theme, ev.eventColorIndex);
    return AgendaItem(
      event: ev,
      color: color,
      groupName: null, // set this if backend includes it
    );
  }).toList();
}
