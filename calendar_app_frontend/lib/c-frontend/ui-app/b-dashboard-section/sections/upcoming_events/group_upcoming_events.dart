import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/user/domain/user_agenda_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
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
    this.daysRange = 14, // same default window as agenda
    this.limit = 5, // show top N concise items
    this.cardColor,
  });

  @override
  State<GroupUpcomingEventsCard> createState() =>
      _GroupUpcomingEventsCardState();
}

class _GroupUpcomingEventsCardState extends State<GroupUpcomingEventsCard> {
  late Future<List<Event>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Event>> _load() async {
    // 🔄 use UserAgendaDomain instead of UserDomain
    final agenda = context.read<UserAgendaDomain>();
    final currentUserId =
        widget.currentUserId ?? context.read<UserDomain>().user?.id;

    final events = await agenda.fetchAgendaUpcoming(
      groupId: widget.groupId,
      days: widget.daysRange,
      limit: 200, // fetch a buffer, we'll filter down
    );

    final now = DateTime.now();
    final filtered = events
        .where((e) =>
            (e.groupId == widget.groupId) &&
            e.startDate.isAfter(now.subtract(const Duration(minutes: 1))))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final shouldFilterToMine =
        widget.role == GroupRole.member && currentUserId != null;

    final filteredByUser = shouldFilterToMine
        ? filtered.where((e) => _isMine(e, currentUserId!)).toList()
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
          cs.primaryContainer.withOpacity(
            theme.brightness == Brightness.dark ? 0.14 : 0.08,
          ),
          ThemeColors.cardBg(context),
        );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
    );
    final shadow = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.3 : 0.12,
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
        if (items.isEmpty) {
          return styledCard(
            ListTile(
              leading: const Icon(Icons.event_busy_rounded),
              title: Text(
                loc.noUpcomingEvents,
                // 🔵 blue title
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                widget.role == GroupRole.member
                    ? loc.nothingScheduledSoon
                    : loc.nothingScheduledSoon,
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
                    // 🔵 blue title
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
                      // “See all” → go to group calendar
                      Navigator.pushNamed(
                        context,
                        AppRoutes.groupCalendar,
                        arguments: widget.groupId, // pass the id only
                      );
                    },
                    child: Text(loc.seeAll),
                  ),
                ),
                const Divider(height: 1),
                ...items
                    .map(
                      (e) => _EventRow(
                        event: e,
                        canManage: currentUserId != null &&
                            _isMine(e, currentUserId),
                      ),
                    )
                    .toList(),
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
  const _EventRow({required this.event, required this.canManage});

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

    return ListTile(
      leading: const Icon(Icons.event_note_outlined),
      title: Text(
        event.title.isEmpty ? loc.untitledEvent : event.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // 🔵 blue event title
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
      onTap: () {
        if (canManage) {
          Navigator.pushNamed(context, AppRoutes.eventDetail,
              arguments: event);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Only the owner or recipients can update this event.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
