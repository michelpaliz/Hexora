import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:flutter/material.dart';

class EventContentBuilder {
  final ColorManager colorManager;
  const EventContentBuilder({required this.colorManager});

  /// Small “pill” used in month‐cell tiles
  Widget buildEventContent(Event event, Color textColor) {
    final accent = colorManager.getColor(event.eventColorIndex);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        event.title,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget buildDefaultEventCard({
    required Widget dateRow,
    required Widget titleRow,
    String? description,
    required Color cardColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 4), // ✅ Internal spacing only
            child: dateRow,
          ),
          const SizedBox(height: 4),
          titleRow,
        ],
      ),
    );
  }
}
