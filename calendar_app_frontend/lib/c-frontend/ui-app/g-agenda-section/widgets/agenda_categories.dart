// lib/c-frontend/b-calendar-section/screens/agenda/widgets/agenda_categories.dart
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AgendaCategories extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const AgendaCategories({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cats = <String, String>{
      'all':       loc?.all ?? 'All',
      'meetings':  loc?.meetings ?? 'Meetings',
      'tasks':     loc?.tasks ?? 'Tasks',
      'deadlines': loc?.deadlines ?? 'Deadlines',
      'personal':  loc?.personal ?? 'Personal',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: cats.entries.map((e) {
          final isSel = selected == e.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSel,
              onSelected: (_) => onSelected(e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
