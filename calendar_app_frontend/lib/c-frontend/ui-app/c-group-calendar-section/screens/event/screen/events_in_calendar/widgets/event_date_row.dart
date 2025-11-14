import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/l10n/AppLocalitationMethod.dart';
import 'package:flutter/material.dart';

class EventDateRow extends StatelessWidget {
  final Event event;
  final Color textColor;

  const EventDateRow({Key? key, required this.event, required this.textColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Text(
            AppLocalizationsMethods.of(context)!.formatDate(event.startDate),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const Text("  –  "),
          Text(
            AppLocalizationsMethods.of(context)!.formatDate(event.endDate),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
