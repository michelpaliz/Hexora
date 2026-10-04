import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/l10n/app_localitation_method.dart';
import 'package:flutter/material.dart';

class EventDateTimeRow extends StatelessWidget {
  final Event event;
  final Color textColor;

  const EventDateTimeRow({
    super.key,
    required this.event,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizationsMethods.of(context)!;

    // 🟢 Convert to local **first**
    final startLocal = event.startDate.toLocal();
    final endLocal = event.endDate.toLocal();

    // Then format
    final startDate = loc.formatDate(startLocal);
    final startTime = loc.formatHours(startLocal);
    final endDate = loc.formatDate(endLocal);
    final endTime = loc.formatHours(endLocal);

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        '$startDate ( $startTime ) / $endDate ( $endTime )',
        style: TextStyle(fontSize: 8, color: textColor),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}
