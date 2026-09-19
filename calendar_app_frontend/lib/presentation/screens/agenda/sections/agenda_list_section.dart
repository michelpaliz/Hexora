import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/agenda_model.dart';
import 'package:hexora/presentation/screens/agenda/widgets/agenda_sliver.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AgendaListSection extends StatelessWidget {
  final List<AgendaItem> filteredItems;
  final bool selectedDayOnly;
  const AgendaListSection(
      {super.key, required this.filteredItems, this.selectedDayOnly = false});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (filteredItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(Icons.event_busy_rounded,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(loc?.noItems ?? 'Nothing upcoming in this view',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                selectedDayOnly
                    ? loc!.agendaEmptyDay
                    : Localizations.localeOf(context).languageCode == 'es'
                        ? 'No hay trabajo programado en este período. Prueba a ampliar el rango.'
                        : 'No work scheduled for this period. Try extending the range.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return AgendaListSliver(items: filteredItems);
  }
}
