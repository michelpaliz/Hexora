// lib/c-frontend/b-dashboard-section/sections/workers/worker/entry_screen/widgets/time_entry_list.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/time_entry_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimeEntriesList extends StatefulWidget {
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

  final List<TimeEntry> entries;
  final String groupId;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final VoidCallback? onUpdated;
  final Worker worker;
  final bool showMissingDays;

  @override
  State<TimeEntriesList> createState() => _TimeEntriesListState();
}

class _TimeEntriesListState extends State<TimeEntriesList> {
  late final ScrollController _scrollController;
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_syncScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollState());
  }

  @override
  void didUpdateWidget(TimeEntriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.length != widget.entries.length ||
        oldWidget.showMissingDays != widget.showMissingDays) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollState());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncScrollState)
      ..dispose();
    super.dispose();
  }

  void _syncScrollState() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScrollUp = position.pixels > position.minScrollExtent + 2;
    final canScrollDown = position.pixels < position.maxScrollExtent - 2;
    if (canScrollUp == _canScrollUp && canScrollDown == _canScrollDown) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _canScrollUp = canScrollUp;
      _canScrollDown = canScrollDown;
    });
  }

  Future<void> _pageScroll(double direction) async {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final viewport = position.viewportDimension;
    final nextOffset = (position.pixels + (viewport * 0.78 * direction)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');

    if (widget.entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by month/year (local time)
    final Map<String, List<TimeEntry>> grouped = {};
    for (final e in widget.entries) {
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

    return Stack(
      children: [
        Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 28, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: months.length,
            itemBuilder: (ctx, i) {
              final month = months[i];
              final list = grouped[month]!
                ..sort((a, b) => a.start.compareTo(b.start));
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
                        groupId: widget.groupId,
                        repo: widget.repo,
                        getToken: widget.getToken,
                        onUpdated: widget.onUpdated,
                      ),
                    ),
                  );
                } else if (widget.showMissingDays) {
                  dayWidgets.add(
                    _MissingDayTile(
                      date: date,
                      workerName: widget.worker.displayName ?? 'Worker',
                    ),
                  );
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dayWidgets,
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 14,
          bottom: 18,
          child: _ScrollControls(
            canScrollUp: _canScrollUp,
            canScrollDown: _canScrollDown,
            onScrollUp: () => _pageScroll(-1),
            onScrollDown: () => _pageScroll(1),
            upTooltip: isEs ? 'Subir' : 'Scroll up',
            downTooltip: isEs ? 'Bajar' : 'Scroll down',
          ),
        ),
      ],
    );
  }
}

class _ScrollControls extends StatelessWidget {
  const _ScrollControls({
    required this.canScrollUp,
    required this.canScrollDown,
    required this.onScrollUp,
    required this.onScrollDown,
    required this.upTooltip,
    required this.downTooltip,
  });

  final bool canScrollUp;
  final bool canScrollDown;
  final VoidCallback onScrollUp;
  final VoidCallback onScrollDown;
  final String upTooltip;
  final String downTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget button({
      required IconData icon,
      required String tooltip,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      return Tooltip(
        message: tooltip,
        child: IconButton.filledTonal(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon),
          iconSize: 18,
          style: IconButton.styleFrom(
            minimumSize: const Size(34, 34),
            fixedSize: const Size(34, 34),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.84),
            disabledBackgroundColor:
                cs.surfaceContainerHighest.withValues(alpha: 0.34),
            foregroundColor: cs.onSurfaceVariant,
            disabledForegroundColor:
                cs.onSurfaceVariant.withValues(alpha: 0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Material(
      color: cs.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              icon: Icons.keyboard_arrow_up_rounded,
              tooltip: upTooltip,
              enabled: canScrollUp,
              onTap: onScrollUp,
            ),
            const SizedBox(height: 3),
            button(
              icon: Icons.keyboard_arrow_down_rounded,
              tooltip: downTooltip,
              enabled: canScrollDown,
              onTap: onScrollDown,
            ),
          ],
        ),
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
    final label =
        isSunday ? l.didNotWorkSunday(workerName) : l.didNotWorkDay(workerName);
    final fg = isSunday
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.error;
    final bg = isSunday
        ? Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.28)
        : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.25);
    final border = fg.withValues(alpha: 0.35);

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
                        .withValues(alpha: 0.78),
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
