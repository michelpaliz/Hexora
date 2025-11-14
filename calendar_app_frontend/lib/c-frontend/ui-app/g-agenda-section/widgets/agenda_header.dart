// lib/c-frontend/b-calendar-section/screens/agenda/widgets/agenda_header.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/agenda/agenda_model.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AgendaHeader extends StatelessWidget {
  final List<AgendaItem> items;
  final int daysRange;
  final VoidCallback onExpandRange;
  final VoidCallback onRefresh;
  final bool showGreeting;

  const AgendaHeader({
    super.key,
    required this.items,
    required this.daysRange,
    required this.onExpandRange,
    required this.onRefresh,
    this.showGreeting = false,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface.withOpacity(.7);
    final loc = AppLocalizations.of(context)!;

    // Summary line (optional)
    final total = items.length;
    final done = items.where(_isDone).length;
    final donePct = total == 0 ? 0.0 : done / total;

    // Build current-week buckets (Mon–Sun or locale first day)
    final buckets = _buildWeekBuckets(context, items);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ValueListenableBuilder<User?>(
                valueListenable: context.read<UserDomain>().currentUserNotifier,
                builder: (context, user, _) {
                  if (user == null) {
                    return CircleAvatar(
                      radius: 26,
                      child: Icon(Icons.person,
                          color: Theme.of(context).colorScheme.onPrimary),
                    );
                  }
                  return UserAvatar(
                      user: user, fetchReadSas: (_) async => null, radius: 26);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showGreeting)
                      ValueListenableBuilder<User?>(
                        valueListenable:
                            context.read<UserDomain>().currentUserNotifier,
                        builder: (context, user, _) {
                          final greeting = (user == null || user.name.isEmpty)
                              ? loc.hi
                              : '${loc.hi}, ${user.name}';
                          return Text(greeting,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis);
                        },
                      ),
                    if (showGreeting) const SizedBox(height: 4),
                    Text(
                      loc.completedSummary(
                          done, total, (donePct * 100).round()),
                      style: TextStyle(color: onSurface, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: onExpandRange,
                    child: Text(daysRange >= 30
                        ? loc.showFourteenDays
                        : loc.showThirtyDays),
                  ),
                  IconButton(
                    tooltip: loc.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: onRefresh,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WeekStrip(buckets: buckets),
        ],
      ),
    );
  }

  bool _isDone(AgendaItem it) {
    final e = it.event;
    if (e.isDone == true) return true;
    if (e.completedAt != null) return true;
    final s = (e.status ?? '').toLowerCase();
    return s == 'done' || s == 'completed' || s == 'finished';
  }

  // ----- Week data helpers -----

  List<_DayBucket> _buildWeekBuckets(
      BuildContext context, List<AgendaItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Locale first day of week: 0=Sun ... 6=Sat; convert to DateTime.weekday 1..7 (Mon..Sun)
    final firstIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstDow = (firstIndex == 0) ? 7 : firstIndex;

    final back = (today.weekday - firstDow + 7) % 7;
    final start = today
        .subtract(Duration(days: back)); // start of this week (local midnight)
    final end = start.add(const Duration(days: 6));

    // Count events per day (bucket by LOCAL startDate)
    final counts = List<int>.filled(7, 0);
    for (final it in items) {
      final local = it.event.startDate.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      final idx = day.difference(start).inDays; // 0..6
      counts[idx] += 1;
    }

    // Build buckets with metadata
    return List<_DayBucket>.generate(7, (i) {
      final date = start.add(Duration(days: i));
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isPast = date.isBefore(today);
      return _DayBucket(
          date: date, count: counts[i], isToday: isToday, isPast: isPast);
    });
  }
}

class _DayBucket {
  final DateTime date;
  final int count;
  final bool isToday;
  final bool isPast;
  const _DayBucket(
      {required this.date,
      required this.count,
      required this.isToday,
      required this.isPast});
}

class _WeekStrip extends StatelessWidget {
  final List<_DayBucket> buckets;
  const _WeekStrip({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardBg = Theme.of(context).colorScheme.surfaceVariant;
    final border = scheme.outlineVariant.withOpacity(.5);
    final todayFill = scheme.primary;
    final todayOn = scheme.onPrimary;
    final normalBg = scheme.surface;
    final normalOn = scheme.onSurface.withOpacity(.85);
    final dimOn = scheme.onSurface.withOpacity(.55);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(buckets.length, (i) {
          final b = buckets[i];
          final isToday = b.isToday;
          final hasEvents = b.count > 0;

          // Labels
          final dow = DateFormat.E(Localizations.localeOf(context).toString())
              .format(b.date)
              .toUpperCase(); // MON, TUE...
          final dayNum =
              DateFormat.d(Localizations.localeOf(context).toString())
                  .format(b.date);

          final chipColor = isToday ? todayFill : normalBg;
          final chipText = isToday ? todayOn : (b.isPast ? dimOn : normalOn);
          final chipBorder = isToday ? null : Border.all(color: border);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(10),
                      border: chipBorder,
                    ),
                    child: Column(
                      children: [
                        Text(
                          dow,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .5,
                            color: chipText.withOpacity(isToday ? 1 : .9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: chipText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // tiny count indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasEvents
                          ? scheme.primary.withOpacity(.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: hasEvents
                          ? Border.all(color: scheme.primary.withOpacity(.35))
                          : null,
                    ),
                    child: Text(
                      hasEvents ? '${b.count}' : '–',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasEvents ? scheme.primary : dimOn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
