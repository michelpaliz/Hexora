// lib/c-frontend/b-dashboard-section/sections/workers/worker/entry_screen/widgets/time_entry_list.dart
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
    final l = AppLocalizations.of(context)!;
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
          final list = grouped[month]!
            ..sort((a, b) => a.start.compareTo(b.start));

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

                // Entries
                ...list.map(
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
