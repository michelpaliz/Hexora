import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/worker/entry_screen/functions/widgets/time_entry_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimeEntriesList extends StatelessWidget {
  final List<TimeEntry> entries;
  final String groupId;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final VoidCallback? onUpdated;

  const TimeEntriesList({
    super.key,
    required this.entries,
    required this.groupId,
    required this.repo,
    required this.getToken,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l.noTimeEntries,
            style: t.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    // Group entries by month/year (local time) and sort months desc
    final grouped = <String, List<TimeEntry>>{};
    for (final e in entries) {
      final key = DateFormat.yMMMM(locale).format(e.start.toLocal());
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final months = grouped.keys.toList()
      ..sort((a, b) {
        final pa = DateFormat.yMMMM(locale).parse(a);
        final pb = DateFormat.yMMMM(locale).parse(b);
        return pb.compareTo(pa); // newest first
      });

    final controller = ScrollController();

    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: months.length,
        itemBuilder: (ctx, i) {
          final month = months[i];
          final monthEntries = grouped[month]!
            ..sort((a, b) => a.start.compareTo(b.start));

          // Calculate total duration for that month
          final totalMinutes = monthEntries.fold<int>(
            0,
            (sum, e) =>
                sum +
                (e.end != null ? e.end!.difference(e.start).inMinutes : 0),
          );
          final totalHours = totalMinutes ~/ 60;
          final remainingMinutes = totalMinutes % 60;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month (top)
                Text(
                  month,
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                // Total (below)
                Text(
                  l.totalHoursFormat(totalHours, remainingMinutes),
                  style: t.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),

                // Entries
                ...monthEntries.map(
                  (e) => TimeEntryCard(
                    entry: e,
                    groupId: groupId,
                    repo: repo,
                    getToken: getToken,
                    onUpdated: onUpdated,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
