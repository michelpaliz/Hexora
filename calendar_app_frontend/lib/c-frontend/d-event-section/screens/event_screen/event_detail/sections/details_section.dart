import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/widgets/info_row.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/widgets/section_card.dart';
import 'package:hexora/l10n/app_localizations.dart';

class DetailsSection extends StatelessWidget {
  final String dateRange;
  final String? location;
  final String? description;
  final String? note;
  final String? recurrenceText;

  const DetailsSection({
    super.key,
    required this.dateRange,
    this.location,
    this.description,
    this.note,
    this.recurrenceText,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      child: SectionCard(
        title: l.detailsSectionTitle,
        // If your SectionCard supports `children:`:
        children: [
          InfoRow(
            icon: Icons.event_outlined,
            label: l.eventWhenLabel,
            value: dateRange,
          ),
          if ((location?.isNotEmpty ?? false))
            InfoRow(
              icon: Icons.location_on_outlined,
              label: l.eventLocationHint,
              value: location!,
            ),
          if ((description?.isNotEmpty ?? false))
            InfoRow(
              icon: Icons.description_outlined,
              label: l.eventDescriptionHint,
              value: description!,
            ),
          if ((note?.isNotEmpty ?? false))
            InfoRow(
              icon: Icons.sticky_note_2_outlined,
              label: l.eventNoteHint,
              value: note!,
            ),
          if ((recurrenceText?.isNotEmpty ?? false))
            InfoRow(
              icon: Icons.repeat,
              label: l.eventRecurrenceHint,
              value: recurrenceText!,
            ),
        ],
      ),
    );
  }
}
