import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';

/// Helper: returns the substring after the *last* known separator.
/// If no separator is present, it strips a leading "mantenimiento" (any case)
/// and leading punctuation/spaces, then returns the result.
String extractClientName(String? title) {
  if (title == null) return '';
  final t = title.trim();
  if (t.isEmpty) return '';

  // Prefer the most explicit, spaced separators first.
  const seps = [' — ', ' – ', ' - ', ' —', ' –', ' -', '—', '–', '-', ':', '|'];

  int bestIdx = -1;
  String bestSep = '';
  for (final sep in seps) {
    final idx = t.lastIndexOf(sep);
    if (idx > bestIdx) {
      bestIdx = idx;
      bestSep = sep;
    }
  }

  if (bestIdx >= 0) {
    return t.substring(bestIdx + bestSep.length).trim();
  }

  // Fallback: no separator found — try to remove a leading "mantenimiento"
  // and any immediate punctuation/whitespace after it.
  final lower = t.toLowerCase();
  if (lower.startsWith('mantenimiento')) {
    final withoutPrefix = t.substring('mantenimiento'.length);
    return withoutPrefix.replaceFirst(RegExp(r'^[\s\-\—\–:|]+'), '').trim();
  }

  // Nothing to clean up, return as-is.
  return t;
}

class EventTitleRow extends StatelessWidget {
  final Event event;
  final Color textColor;
  final ColorManager colorManager;

  const EventTitleRow({
    Key? key,
    required this.event,
    required this.textColor,
    required this.colorManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accent = colorManager.getColor(event.eventColorIndex);
    final clientName = extractClientName(event.title);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          // If you later want an accent icon, uncomment:
          // Icon(Icons.event, size: 18, color: accent),
          // const SizedBox(width: 8),
          Expanded(
            child: Text(
              clientName, // ← only the client's name shown
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Optional actions:
          // IconButton(
          //   icon: Icon(Icons.more_vert, color: accent),
          //   onPressed: () { /* navigate to details */ },
          // ),
        ],
      ),
    );
  }
}
