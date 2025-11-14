import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';

/// Re-usable round badge icon for every event card / strip.
Widget buildLeadingIcon(Color cardColor, Event event, {double size = 36}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: cardColor.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: Icon(
      event.isDone ? Icons.check_circle : Icons.event_note,
      color: cardColor,
      size: size * 0.55,
    ),
  );
}
