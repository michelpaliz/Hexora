import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/shared/widgets/hexora_empty_state.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/services/user/domain/user_agenda_domain.dart';
import 'package:provider/provider.dart';

/// Small calendar/agenda preview used by the mobile dashboard.
/// It intentionally uses the existing agenda endpoint and event permissions.
class HomeCalendarPreview extends StatefulWidget {
  const HomeCalendarPreview({
    super.key,
    required this.groupId,
    required this.role,
    required this.currentUserId,
  });

  final String groupId;
  final GroupRole role;
  final String currentUserId;

  @override
  State<HomeCalendarPreview> createState() => _HomeCalendarPreviewState();
}

class _HomeCalendarPreviewState extends State<HomeCalendarPreview> {
  late Future<List<Event>> _future;
  DateTime _selected = _day(DateTime.now());
  bool _expanded = false;

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Event>> _load() async {
    final events = await context.read<UserAgendaDomain>().fetchAgendaUpcoming(
          groupId: widget.groupId,
          days: 90,
          limit: 200,
        );
    final visible = events.where((event) {
      if (event.groupId != widget.groupId) return false;
      if (widget.role != GroupRole.member) return true;
      return event.ownerId == widget.currentUserId ||
          event.recipients.contains(widget.currentUserId);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return visible;
  }

  bool _sameDay(DateTime a, DateTime b) => _day(a) == _day(b);

  DateTime _monday(DateTime value) {
    final date = _day(value);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  List<DateTime> _weekDays() {
    final start = _monday(_selected);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  List<DateTime> _monthDays() {
    final first = DateTime(_selected.year, _selected.month, 1);
    final start =
        first.subtract(Duration(days: first.weekday - DateTime.monday));
    final rowCount = ((first.day -
                1 +
                DateTime(_selected.year, _selected.month + 1, 0).day) /
            7)
        .ceil();
    return List.generate(
        rowCount * 7, (index) => start.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = l.localeName;
    return FutureBuilder<List<Event>>(
      future: _future,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <Event>[];
        final selectedEvents = events
            .where((event) => _sameDay(event.startDate, _selected))
            .take(3)
            .toList();
        final hasEvents = events.map((event) => _day(event.startDate)).toSet();
        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM(locale).format(_selected),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selected = _day(DateTime.now());
                      _expanded = false;
                    }),
                    child:
                        Text(l.localeName.startsWith('es') ? 'Hoy' : 'Today'),
                  ),
                  IconButton(
                    tooltip: _expanded
                        ? (l.localeName.startsWith('es')
                            ? 'Contraer'
                            : 'Collapse')
                        : (l.localeName.startsWith('es')
                            ? 'Ver mes'
                            : 'View month'),
                    visualDensity: VisualDensity.compact,
                    icon:
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: _CalendarGrid(
                  days: _expanded ? _monthDays() : _weekDays(),
                  selected: _selected,
                  today: _day(DateTime.now()),
                  eventDays: hasEvents,
                  monthView: _expanded,
                  onSelect: (date) => setState(() => _selected = date),
                  locale: locale,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.MMMMd(locale).format(_selected),
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.groupCalendar,
                        arguments: widget.groupId),
                    child: Text(l.localeName.startsWith('es')
                        ? 'Ver calendario'
                        : 'View calendar'),
                  ),
                ],
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else if (selectedEvents.isEmpty)
                HexoraEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: l.emptyCalendarTitle,
                  description: l.emptyCalendarDescription,
                  variant: HexoraEmptyStateVariant.compact,
                  maxDescriptionWidth: 320,
                )
              else
                ...selectedEvents
                    .map((event) => _AgendaRow(event: event, locale: locale)),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid(
      {required this.days,
      required this.selected,
      required this.today,
      required this.eventDays,
      required this.monthView,
      required this.onSelect,
      required this.locale});
  final List<DateTime> days;
  final DateTime selected;
  final DateTime today;
  final Set<DateTime> eventDays;
  final bool monthView;
  final ValueChanged<DateTime> onSelect;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final weekdays = List.generate(
      7,
      (index) => DateFormat.E(locale).format(DateTime(2024, 1, index + 1)),
    );
    return Column(
      children: [
        Row(children: [
          for (var index = 0; index < 7; index++)
            Expanded(
                child: Center(
                    child: Text(weekdays[(index + 1) % 7],
                        style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600))))
        ]),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisExtent: 34),
          itemBuilder: (context, index) {
            final date = days[index];
            final isSelected = date == selected;
            final isToday = date == today;
            final hasEvent = eventDays.contains(date);
            final sameMonth = date.month == selected.month;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(date),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: isSelected ? cs.primary : null,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: cs.primary, width: 1.5)
                            : null),
                    child: Text('${date.day}',
                        style: tt.bodySmall?.copyWith(
                            color: isSelected
                                ? cs.onPrimary
                                : (sameMonth
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant
                                        .withValues(alpha: .45)),
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.w500)),
                  ),
                  if (hasEvent)
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: cs.secondary, shape: BoxShape.circle)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.event, required this.locale});
  final Event event;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          SizedBox(
              width: 45,
              child: Text(DateFormat.Hm(locale).format(event.startDate),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700))),
          Expanded(
              child: Text(event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
