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
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final total = items.length;
    final done = items.where(_isDone).length;
    final donePct = total == 0 ? 0.0 : done / total;

    final buckets = _buildWeekBuckets(context, items);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: avatar + summary + controls ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              ValueListenableBuilder<User?>(
                valueListenable:
                    context.read<UserDomain>().currentUserNotifier,
                builder: (context, user, _) {
                  if (user == null) {
                    return CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          cs.surfaceContainerHighest,
                      child: Icon(Icons.person,
                          color: cs.onSurfaceVariant, size: 22),
                    );
                  }
                  return UserAvatar(
                      user: user,
                      fetchReadSas: (_) async => null,
                      radius: 22);
                },
              ),
              const SizedBox(width: 12),

              // Summary + progress bar
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    Row(
                      children: [
                        Text(
                          loc.completedSummary(
                              done, total, (donePct * 100).round()),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (total > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${(donePct * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: done == total
                                  ? cs.secondary
                                  : cs.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: donePct,
                          minHeight: 4,
                          backgroundColor:
                              cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            done == total ? cs.secondary : cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Controls: day range segmented + refresh ─────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DayRangeToggle(
                    daysRange: daysRange,
                    onToggle: onExpandRange,
                    loc: loc,
                    cs: cs,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      tooltip: loc.refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      onPressed: onRefresh,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Week strip ─────────────────────────────────────────────────
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

  List<_DayBucket> _buildWeekBuckets(
      BuildContext context, List<AgendaItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstIndex =
        MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstDow = (firstIndex == 0) ? 7 : firstIndex;

    final back = (today.weekday - firstDow + 7) % 7;
    final start = today.subtract(Duration(days: back));
    final end = start.add(const Duration(days: 6));

    final counts = List<int>.filled(7, 0);
    for (final it in items) {
      final local = it.event.startDate.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      final idx = day.difference(start).inDays;
      counts[idx] += 1;
    }

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

// ── Day range segmented toggle ─────────────────────────────────────────────────

class _DayRangeToggle extends StatelessWidget {
  final int daysRange;
  final VoidCallback onToggle;
  final AppLocalizations loc;
  final ColorScheme cs;

  const _DayRangeToggle({
    required this.daysRange,
    required this.onToggle,
    required this.loc,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final is30 = daysRange >= 30;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: '14d',
            selected: !is30,
            onTap: is30 ? onToggle : null,
            cs: cs,
          ),
          _Segment(
            label: '30d',
            selected: is30,
            onTap: !is30 ? onToggle : null,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final ColorScheme cs;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected
                ? cs.onPrimary
                : cs.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

// ── Week strip ─────────────────────────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: List.generate(buckets.length, (i) {
          final b = buckets[i];
          final dow = DateFormat.E(locale)
              .format(b.date)
              .toUpperCase()
              .substring(0, 3);
          final dayNum = DateFormat.d(locale).format(b.date);

          final isToday = b.isToday;
          final isPast = b.isPast;
          final hasEvents = b.count > 0;

          final dayColor = isToday
              ? cs.primary
              : isPast
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.8)
                  : cs.surface;
          final dayTextColor = isToday
              ? cs.onPrimary
              : isPast
                  ? cs.onSurface.withValues(alpha: 0.35)
                  : cs.onSurface.withValues(alpha: 0.85);
          final dowColor = isToday
              ? cs.onPrimary.withValues(alpha: 0.8)
              : cs.onSurface.withValues(
                  alpha: isPast ? 0.3 : 0.55);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 7, horizontal: 4),
                    decoration: BoxDecoration(
                      color: dayColor,
                      borderRadius: BorderRadius.circular(11),
                      border: isToday
                          ? null
                          : Border.all(
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          dow,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: dowColor,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: dayTextColor,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Event count indicator
                  if (hasEvents)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.primary.withValues(
                              alpha: isPast ? 0.2 : 0.35),
                        ),
                      ),
                      child: Text(
                        '${b.count}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.primary
                              .withValues(alpha: isPast ? 0.5 : 1.0),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant
                            .withValues(alpha: 0.4),
                        shape: BoxShape.circle,
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
