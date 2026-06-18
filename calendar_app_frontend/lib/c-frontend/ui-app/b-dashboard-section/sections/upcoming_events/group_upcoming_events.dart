import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/user/domain/user_agenda_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupUpcomingEventsCard extends StatefulWidget {
  final String groupId;
  final int daysRange;
  final int limit;
  final Color? cardColor;
  final GroupRole role;
  final String? currentUserId;

  const GroupUpcomingEventsCard({
    super.key,
    required this.groupId,
    required this.role,
    required this.currentUserId,
    this.daysRange = 14,
    this.limit = 5,
    this.cardColor,
  });

  @override
  State<GroupUpcomingEventsCard> createState() =>
      _GroupUpcomingEventsCardState();
}

class _GroupUpcomingEventsCardState extends State<GroupUpcomingEventsCard> {
  late Future<List<Event>> _future;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Event>> _load() async {
    final agenda = context.read<UserAgendaDomain>();
    final currentUserId =
        widget.currentUserId ?? context.read<UserDomain>().user?.id;

    final events = await agenda.fetchAgendaUpcoming(
      groupId: widget.groupId,
      days: widget.daysRange,
      limit: 200,
    );

    final now = DateTime.now();
    final filtered = events
        .where(
          (e) =>
              e.groupId == widget.groupId &&
              e.startDate.isAfter(now.subtract(const Duration(minutes: 1))),
        )
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final shouldFilterToMine =
        widget.role == GroupRole.member && currentUserId != null;

    final filteredByUser = shouldFilterToMine
        ? filtered.where((e) => _isMine(e, currentUserId)).toList()
        : filtered;

    return filteredByUser.take(widget.limit).toList();
  }

  bool _isMine(Event e, String uid) =>
      e.ownerId == uid || e.recipients.contains(uid);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;

    final cardColor = widget.cardColor ??
        Color.alphaBlend(
          cs.primaryContainer.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
          ),
          ThemeColors.cardBg(context),
        );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
    );
    final shadow = Colors.black.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.3 : 0.12,
    );

    Widget styledCard(Widget child) => Card(
          color: cardColor,
          surfaceTintColor: Colors.transparent,
          elevation: 6,
          shadowColor: shadow,
          shape: cardShape,
          child: child,
        );

    final onSurfaceVar = cs.onSurfaceVariant;

    return FutureBuilder<List<Event>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return styledCard(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(loc.loadingUpcoming, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return styledCard(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                snapshot.error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
              ),
            ),
          );
        }

        final currentUserId =
            widget.currentUserId ?? context.read<UserDomain>().user?.id;
        final items = snapshot.data ?? const <Event>[];
        final isDesktop = MediaQuery.of(context).size.width >= 1180;
        final selectedEvent = items.cast<Event?>().firstWhere(
              (e) => e?.id == _selectedEventId,
              orElse: () => items.isNotEmpty ? items.first : null,
            );

        if (items.isEmpty) {
          return styledCard(
            ListTile(
              leading: const Icon(Icons.event_busy_rounded),
              title: Text(
                loc.noUpcomingEvents,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                loc.nothingScheduledSoon,
                style: TextStyle(color: onSurfaceVar),
              ),
              trailing: const SizedBox.shrink(),
            ),
          );
        }

        return styledCard(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upcoming_rounded),
                  title: Text(
                    loc.nextUp,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    loc.upcomingEventsSubtitle,
                    style: TextStyle(color: onSurfaceVar),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.groupCalendar,
                        arguments: widget.groupId,
                      );
                    },
                    child: Text(loc.seeAll),
                  ),
                ),
                const Divider(height: 1),
                if (isDesktop)
                  SizedBox(
                    height: 420,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            children: items
                                .map(
                                  (e) => _EventRow(
                                    event: e,
                                    canManage: currentUserId != null &&
                                        _isMine(e, currentUserId),
                                    selected: e.id == selectedEvent?.id,
                                    onTap: () {
                                      setState(() => _selectedEventId = e.id);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.25),
                        ),
                        Expanded(
                          flex: 4,
                          child: selectedEvent == null
                              ? const _UpcomingDetailPlaceholder()
                              : Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: EventDetailScreen(
                                      event: selectedEvent,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  )
                else
                  ...items.map(
                    (e) => _EventRow(
                      event: e,
                      canManage:
                          currentUserId != null && _isMine(e, currentUserId),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventRow extends StatelessWidget {
  final Event event;
  final bool canManage;
  final bool selected;
  final VoidCallback? onTap;

  const _EventRow({
    required this.event,
    required this.canManage,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ml = MaterialLocalizations.of(context);
    final loc = AppLocalizations.of(context)!;

    final dateStr = ml.formatMediumDate(event.startDate);
    final timeStr =
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.startDate))} – '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.endDate))}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: cs.primary.withValues(alpha: 0.35))
            : null,
      ),
      child: ListTile(
        leading: const Icon(Icons.event_note_outlined),
        title: Text(
          event.title.isEmpty ? loc.untitledEvent : event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$dateStr · $timeStr',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        onTap: onTap ??
            () {
              if (canManage) {
                Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: event);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Only the owner or recipients can update this event.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
      ),
    );
  }
}

class _UpcomingDetailPlaceholder extends StatelessWidget {
  const _UpcomingDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEs = Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 40,
              color: cs.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              isEs ? 'Detalles del evento' : 'Event details',
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isEs
                  ? 'Selecciona un evento para ver su información en este panel.'
                  : 'Select an event to view its details in this panel.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
