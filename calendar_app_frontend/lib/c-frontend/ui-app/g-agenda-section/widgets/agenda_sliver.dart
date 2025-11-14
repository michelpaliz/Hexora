// lib/c-frontend/b-calendar-section/screens/agenda/widgets/agenda_list_sliver.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hexora/a-models/group_model/agenda/agenda_model.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AgendaListSliver extends StatelessWidget {
  final List<AgendaItem> items;
  const AgendaListSliver({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.separated(
      itemBuilder: (_, i) {
        final curr = items[i];
        final showHeader = (i == 0) ||
            !_sameDay(items[i - 1].event.startDate, curr.event.startDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader) _DateHeader(date: curr.event.startDate),
            _AgendaTile(item: curr),
          ],
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemCount: items.length,
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final AgendaItem item;
  const _AgendaTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final e = item.event;
    final start = e.startDate.toLocal();
    final end = e.endDate.toLocal();

    final timeStr = _formatTimeRange(context, start, e.allDay ? null : end);
    final secondary = [
      if (item.groupName != null) item.groupName!,
      if (e.localization?.isNotEmpty == true) e.localization!,
    ].join(' • ').replaceFirst(RegExp(r'^ • '), '');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.color,
          child: const Icon(Icons.event_rounded, color: Colors.white),
        ),
        title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          secondary.isEmpty ? timeStr : '$timeStr • $secondary',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          // TODO: deep-link to event or its group calendar
        },
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final dLocal = date.toLocal();
    final now = DateTime.now();
    final isToday = _sameDay(dLocal, now);
    final isTomorrow = _sameDay(dLocal, now.add(const Duration(days: 1)));

    final label = isToday
        ? (loc?.today ?? 'Today')
        : isTomorrow
            ? (loc?.tomorrow ?? 'Tomorrow')
            : DateFormat.yMMMMEEEEd().format(dLocal);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

// helpers
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatTimeRange(BuildContext context, DateTime start, DateTime? end) {
  final ml = MaterialLocalizations.of(context);
  final s = ml.formatTimeOfDay(
    TimeOfDay.fromDateTime(start),
    alwaysUse24HourFormat: true,
  );
  if (end == null) return s;
  final e = ml.formatTimeOfDay(
    TimeOfDay.fromDateTime(end),
    alwaysUse24HourFormat: true,
  );
  return '$s – $e';
}
