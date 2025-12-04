// lib/c-frontend/b-dashboard-section/sections/workers/worker/entry_screen/widgets/time_entry_list.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/time_entry_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimeEntriesList extends StatelessWidget {
  final List<TimeEntry> entries;
  final String groupId;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final VoidCallback? onUpdated;
  final Worker worker;
  final bool showMissingDays;

  const TimeEntriesList({
    super.key,
    required this.entries,
    required this.groupId,
    required this.repo,
    required this.getToken,
    required this.worker,
    this.showMissingDays = false,
    this.onUpdated,
  });

  String _fmtHm(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by month/year (local time)
    final Map<String, List<TimeEntry>> grouped = {};
    for (final e in entries) {
      final key = DateFormat.yMMMM(locale).format(e.start.toLocal());
      grouped.putIfAbsent(key, () => []).add(e);
    }

    // Sort months (newest first)
    final months = grouped.keys.toList()
      ..sort((a, b) {
        final pa = DateFormat.yMMMM(locale).parse(a);
        final pb = DateFormat.yMMMM(locale).parse(b);
        return pb.compareTo(pa);
      });

    final controller = ScrollController();

    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: months.length,
        itemBuilder: (ctx, i) {
          final month = months[i];
          final list = grouped[month]!..sort((a, b) => a.start.compareTo(b.start));
          final monthDate = DateFormat.yMMMM(locale).parse(month);
          final daysInMonth =
              DateUtils.getDaysInMonth(monthDate.year, monthDate.month);

          final Map<int, List<TimeEntry>> entriesByDay = {};
          for (final e in list) {
            final d = e.start.toLocal().day;
            entriesByDay.putIfAbsent(d, () => []).add(e);
          }

          final dayWidgets = <Widget>[];
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(monthDate.year, monthDate.month, day);
            final dayEntries = entriesByDay[day];

            if (dayEntries != null) {
              dayEntries.sort((a, b) => a.start.compareTo(b.start));
              dayWidgets.addAll(
                dayEntries.map(
                  (e) => TimeEntryCard(
                    entry: e,
                    groupId: groupId,
                    repo: repo,
                    getToken: getToken,
                    onUpdated: onUpdated,
                  ),
                ),
              );
            } else if (showMissingDays) {
              dayWidgets.add(
                _MissingDayTile(
                  date: date,
                  workerName: worker.displayName ?? 'Worker',
                ),
              );
            }
          }

          // Total minutes for this month
          final totalMinutes = list.fold<int>(
            0,
            (sum, e) =>
                sum +
                (e.end != null ? e.end!.difference(e.start).inMinutes : 0),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact month header with total hours
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        month,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _fmtHm(totalMinutes),
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Entries or missing days
                ...dayWidgets,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MissingDayTile extends StatelessWidget {
  const _MissingDayTile({
    required this.date,
    required this.workerName,
  });

  final DateTime date;
  final String workerName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isSunday = date.weekday == DateTime.sunday;
    final label = isSunday
        ? l.didNotWorkSunday(workerName)
        : l.didNotWorkDay(workerName);
    final fg = isSunday
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.error;
    final bg = isSunday
        ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.28)
        : Theme.of(context).colorScheme.errorContainer.withOpacity(0.25);
    final border = fg.withOpacity(0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_busy_outlined,
            color: fg,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE d MMM y', locale).format(date),
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
