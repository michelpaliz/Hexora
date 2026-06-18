import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/agenda/agenda_model.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_agenda_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/sections/agenda_filters_section.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/sections/agenda_header_section.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/sections/agenda_list_section.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/widgets/agenda_sliver.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AgendaScreen extends StatefulWidget {
  final String? groupId;
  final bool showBottomNav;

  const AgendaScreen({super.key, this.groupId, this.showBottomNav = true});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _loading = true;
  String? _error;
  List<AgendaItem> _items = [];
  int _daysRange = 14;

  String _category = 'all';
  String _type = 'all';

  bool get _showCategories => _type == 'simple';

  bool _isWorkToken(String v) {
    final t = v.toLowerCase();
    return t == 'work_service' || t == 'work_visit';
  }

  bool _isWorkEvent(AgendaItem it) => _isWorkToken(it.event.type);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAgenda());
  }

  String? _resolveGroupId() {
    final explicit = widget.groupId;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    try {
      final gm = context.read<GroupDomain>();
      final fallback = gm.currentGroup?.id;
      if (fallback != null && fallback.isNotEmpty) return fallback;
    } catch (_) {}
    return null;
  }

  Future<void> _loadAgenda() async {
    final gid = _resolveGroupId();
    if (!mounted) return;

    if (gid == null || gid.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _items = const [];
      });
      return;
    }

    try {
      setState(() => _loading = true);
      final agenda = context.read<UserAgendaDomain>();
      final List<Event> events = await agenda.fetchAgendaUpcoming(
        groupId: gid,
        days: _daysRange,
        limit: 300,
      );
      if (!mounted) return;
      setState(() {
        _items = buildAgendaItems(events, Theme.of(context));
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<AgendaItem> _applyAllFilters(List<AgendaItem> all) {
    Iterable<AgendaItem> out = all;
    final gid = _resolveGroupId();

    if (gid != null && gid.isNotEmpty) {
      out = out.where((it) => it.event.groupId == gid);
    }

    if (_type == 'simple') {
      final token = _category.toLowerCase();
      if (token != 'all') {
        if (token.startsWith('cat:')) {
          final id = token.substring(4);
          out = out
              .where((it) => (it.event.categoryId ?? '').toLowerCase() == id);
        } else if (token.startsWith('sub:')) {
          final id = token.substring(4);
          out = out.where(
              (it) => (it.event.subcategoryId ?? '').toLowerCase() == id);
        } else {
          out = const <AgendaItem>[];
        }
      }
    }

    if (_type == 'simple') {
      out = out.where((it) => it.event.type.toLowerCase() == 'simple');
    } else if (_isWorkToken(_type)) {
      out = out.where(_isWorkEvent);
    }

    return out.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyAllFilters(_items);
    final gid = _resolveGroupId();
    final loc = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (isDesktop) {
      // ── Desktop: 3-panel layout ─────────────────────────────────────────
      body = _AgendaDesktopLayout(
        items: filtered,
        allItems: _items,
        daysRange: _daysRange,
        onToggleDays: () {
          setState(() {
            _daysRange = _daysRange >= 30 ? 14 : 30;
            _loading = true;
          });
          _loadAgenda();
        },
        onRefresh: () {
          setState(() => _loading = true);
          _loadAgenda();
        },
      );
    } else {
      // ── Mobile: existing scrolling layout ───────────────────────────────
      body = RefreshIndicator(
        onRefresh: _loadAgenda,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AgendaHeaderSection(
              items: filtered,
              daysRange: _daysRange,
              onToggleDays: () {
                setState(() {
                  _daysRange = _daysRange >= 30 ? 14 : 30;
                  _loading = true;
                });
                _loadAgenda();
              },
              onRefresh: () {
                setState(() => _loading = true);
                _loadAgenda();
              },
            ),
            if (gid == null)
              SliverToBoxAdapter(
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: Text(loc.agendaSelectGroupPrompt),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.showGroups)
                            .then((_) => _loadAgenda());
                      },
                      child: Text(loc.agendaChooseGroupButton),
                    ),
                  ),
                ),
              ),
            AgendaFiltersSection(
              category: _category,
              type: _type,
              showCategories: _showCategories,
              onCategoryChanged: (c) => setState(() => _category = c),
              onTypeChanged: (t) => setState(() {
                _type = t;
                if (_type != 'simple') _category = 'all';
              }),
            ),
            AgendaListSection(filteredItems: filtered),
          ],
        ),
      );
    }

    return MainScaffold(
      showAppBar: false,
      showBottomNavAndFab: widget.showBottomNav,
      body: body,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Desktop 3-panel layout
// ═══════════════════════════════════════════════════════════════════════════════

class _AgendaDesktopLayout extends StatefulWidget {
  final List<AgendaItem> items;
  final List<AgendaItem> allItems;
  final int daysRange;
  final VoidCallback onToggleDays;
  final VoidCallback onRefresh;

  const _AgendaDesktopLayout({
    required this.items,
    required this.allItems,
    required this.daysRange,
    required this.onToggleDays,
    required this.onRefresh,
  });

  @override
  State<_AgendaDesktopLayout> createState() => _AgendaDesktopLayoutState();
}

class _AgendaDesktopLayoutState extends State<_AgendaDesktopLayout> {
  late DateTime _selectedDay;
  AgendaItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalize(DateTime.now());
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isDone(AgendaItem it) {
    final e = it.event;
    if (e.isDone == true) return true;
    if (e.completedAt != null) return true;
    final s = (e.status ?? '').toLowerCase();
    return s == 'done' || s == 'completed' || s == 'finished';
  }

  // Build 7-day buckets for current week using ALL items (not filtered)
  List<_DayBucket> _buildBuckets() {
    final now = DateTime.now();
    final today = _normalize(now);
    final firstIndex =
        MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstDow = (firstIndex == 0) ? 7 : firstIndex;
    final back = (today.weekday - firstDow + 7) % 7;
    final start = today.subtract(Duration(days: back));

    final counts = <DateTime, int>{};
    for (final it in widget.allItems) {
      final local = it.event.startDate.toLocal();
      final day = _normalize(local);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return List.generate(7, (i) {
      final date = start.add(Duration(days: i));
      final isToday = date == today;
      return _DayBucket(
        date: date,
        count: counts[date] ?? 0,
        isToday: isToday,
        isPast: date.isBefore(today),
      );
    });
  }

  List<AgendaItem> get _eventsForDay {
    final sel = _selectedDay;
    return widget.items.where((it) {
      final local = it.event.startDate.toLocal();
      return _normalize(local) == sel;
    }).toList()
      ..sort((a, b) => a.event.startDate.compareTo(b.event.startDate));
  }

  int get _totalDone => widget.allItems.where(_isDone).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final buckets = _buildBuckets();
    final dayEvents = _eventsForDay;

    return Column(
      children: [
        // ── Top summary bar ───────────────────────────────────────────────
        _DesktopTopBar(
          items: widget.allItems,
          totalDone: _totalDone,
          daysRange: widget.daysRange,
          onToggleDays: widget.onToggleDays,
          onRefresh: widget.onRefresh,
        ),
        Divider(
            height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),

        // ── Three panels ──────────────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: vertical day strip
              _VerticalDayStrip(
                buckets: buckets,
                selectedDay: _selectedDay,
                onDaySelected: (day) => setState(() {
                  _selectedDay = day;
                  _selectedItem = null;
                }),
              ),

              VerticalDivider(
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.3)),

              // Middle: events for the selected day
              Expanded(
                child: _DayEventsPanel(
                  date: _selectedDay,
                  events: dayEvents,
                  selectedItemId: _selectedItem?.event.id,
                  onEventTap: (item) => setState(() {
                    _selectedItem =
                        _selectedItem?.event.id == item.event.id
                            ? null
                            : item;
                  }),
                ),
              ),

              // Right: event detail panel (slides in)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _selectedItem != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VerticalDivider(
                              width: 1,
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.3)),
                          SizedBox(
                            width: 300,
                            child: _EventDetailPanel(
                              item: _selectedItem!,
                              onClose: () =>
                                  setState(() => _selectedItem = null),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Desktop top bar ────────────────────────────────────────────────────────────

class _DesktopTopBar extends StatelessWidget {
  final List<AgendaItem> items;
  final int totalDone;
  final int daysRange;
  final VoidCallback onToggleDays;
  final VoidCallback onRefresh;

  const _DesktopTopBar({
    required this.items,
    required this.totalDone,
    required this.daysRange,
    required this.onToggleDays,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final total = items.length;
    final done = totalDone;
    final pct = total == 0 ? 0.0 : done / total;
    final is30 = daysRange >= 30;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          // Avatar
          ValueListenableBuilder<User?>(
            valueListenable:
                context.read<UserDomain>().currentUserNotifier,
            builder: (_, user, __) => user == null
                ? CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.surfaceContainerHighest,
                    child:
                        Icon(Icons.person, size: 18, color: cs.onSurfaceVariant),
                  )
                : UserAvatar(
                    user: user,
                    fetchReadSas: (_) async => null,
                    radius: 18,
                  ),
          ),
          const SizedBox(width: 12),

          // Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .completedSummary(done, total, (pct * 100).round()),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${(pct * 100).round()}%',
                        style: t.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: done == total ? cs.secondary : cs.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 3,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        done == total ? cs.secondary : cs.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Day range segmented
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Seg(label: '14d', active: !is30, cs: cs,
                    onTap: is30 ? onToggleDays : null),
                _Seg(label: '30d', active: is30, cs: cs,
                    onTap: !is30 ? onToggleDays : null),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Refresh
          IconButton(
            tooltip: AppLocalizations.of(context)!.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            onPressed: onRefresh,
            visualDensity: VisualDensity.compact,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final ColorScheme cs;
  const _Seg(
      {required this.label,
      required this.active,
      required this.cs,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active
                  ? cs.onPrimary
                  : cs.onSurfaceVariant.withValues(alpha: 0.8),
            )),
      ),
    );
  }
}

// ── Vertical day strip (left panel) ───────────────────────────────────────────

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

class _VerticalDayStrip extends StatelessWidget {
  final List<_DayBucket> buckets;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _VerticalDayStrip({
    required this.buckets,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    return SizedBox(
      width: 88,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: List.generate(buckets.length, (i) {
            final b = buckets[i];
            final isSelected = _sameDate(b.date, selectedDay);
            final dow = DateFormat.E(locale)
                .format(b.date)
                .toUpperCase()
                .substring(0, 3);
            final dayNum =
                DateFormat.d(locale).format(b.date);
            final hasEvents = b.count > 0;

            final bg = isSelected
                ? cs.primary
                : b.isToday
                    ? cs.primaryContainer.withValues(alpha: 0.55)
                    : Colors.transparent;
            final textColor = isSelected
                ? cs.onPrimary
                : b.isPast
                    ? cs.onSurface.withValues(alpha: 0.3)
                    : cs.onSurface.withValues(alpha: 0.85);
            final dowColor = isSelected
                ? cs.onPrimary.withValues(alpha: 0.75)
                : b.isPast
                    ? cs.onSurface.withValues(alpha: 0.25)
                    : cs.onSurfaceVariant.withValues(alpha: 0.7);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onDaySelected(b.date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: b.isToday && !isSelected
                        ? Border.all(
                            color: cs.primary.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dow,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: dowColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayNum,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Event count badge
                      if (hasEvents)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.onPrimary.withValues(alpha: 0.2)
                                : cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${b.count}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? cs.onPrimary
                                  : cs.primary.withValues(
                                      alpha: b.isPast ? 0.5 : 1.0),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant
                                .withValues(alpha: isSelected ? 0.4 : 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Middle: events for selected day ───────────────────────────────────────────

class _DayEventsPanel extends StatelessWidget {
  final DateTime date;
  final List<AgendaItem> events;
  final String? selectedItemId;
  final ValueChanged<AgendaItem> onEventTap;

  const _DayEventsPanel({
    required this.date,
    required this.events,
    required this.selectedItemId,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isTomorrow = date.year == now.add(const Duration(days: 1)).year &&
        date.month == now.add(const Duration(days: 1)).month &&
        date.day == now.add(const Duration(days: 1)).day;

    final dateLabel = isToday
        ? loc.today
        : isTomorrow
            ? loc.tomorrow
            : DateFormat.MMMMEEEEd(locale).format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25)),
            ),
          ),
          child: Row(
            children: [
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    dateLabel,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Text(
                  dateLabel,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              const Spacer(),
              if (events.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${events.length}',
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Events list
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 36,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loc.noUpcomingEvents,
                        style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: events.length,
                  itemBuilder: (_, i) {
                    final item = events[i];
                    final isSelected =
                        item.event.id == selectedItemId;
                    return _SelectableEventTile(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onEventTap(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Wraps AgendaTile with a selection highlight ring
class _SelectableEventTile extends StatelessWidget {
  final AgendaItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableEventTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(
                  color: cs.primary.withValues(alpha: 0.55), width: 1.5)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: AgendaTile(item: item),
      ),
    );
  }
}

// ── Right: event detail panel ──────────────────────────────────────────────────

class _EventDetailPanel extends StatelessWidget {
  final AgendaItem item;
  final VoidCallback onClose;

  const _EventDetailPanel({required this.item, required this.onClose});

  bool get _isDone {
    final e = item.event;
    if (e.isDone == true) return true;
    if (e.completedAt != null) return true;
    final s = (e.status ?? '').toLowerCase();
    return s == 'done' || s == 'completed' || s == 'finished';
  }

  IconData _typeIcon() {
    final type = item.event.type.toLowerCase();
    if (type.contains('work')) return Icons.build_circle_outlined;
    return Icons.event_note_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final e = item.event;
    final locale = Localizations.localeOf(context).toString();
    final isDone = _isDone;
    final color = item.color;

    final start = e.startDate.toLocal();
    final end = e.endDate.toLocal();
    final ml = MaterialLocalizations.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final timeRange = e.allDay
        ? (isEs ? 'Todo el día' : 'All day')
        : '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(start), alwaysUse24HourFormat: true)} – ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(end), alwaysUse24HourFormat: true)}';

    final duration = e.allDay
        ? null
        : _fmtDuration(end.difference(start));

    final dateStr = DateFormat.MMMMEEEEd(locale).format(start);
    final location = (e.localization ?? '').trim();
    final description =
        ((e.description ?? '').trim().isEmpty ? e.note : e.description)
                ?.trim() ??
            '';
    final isWorkType = e.type.toLowerCase().contains('work');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Panel header ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.event ?? 'Event',
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                color: cs.onSurfaceVariant,
                tooltip: 'Close',
              ),
            ],
          ),
        ),

        // ── Detail content ───────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left color stripe + title
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.title,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDone
                                ? cs.onSurface.withValues(alpha: 0.45)
                                : cs.onSurface,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor:
                                cs.onSurface.withValues(alpha: 0.45),
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Status chip
                if (isDone)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 13, color: cs.onSecondaryContainer),
                        const SizedBox(width: 5),
                        Text(
                          'Completado',
                          style: t.bodySmall.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Meta rows
                _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  color: color,
                  label: dateStr,
                ),
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.schedule_outlined,
                  color: color,
                  label: duration != null
                      ? '$timeRange  ·  $duration'
                      : timeRange,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.place_outlined,
                    color: cs.onSurfaceVariant,
                    label: location,
                  ),
                ],
                if (item.groupName != null) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.group_outlined,
                    color: cs.onSurfaceVariant,
                    label: item.groupName!,
                  ),
                ],

                // Type badge
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(), size: 13, color: color),
                      const SizedBox(width: 6),
                      Text(
                        isWorkType ? 'Trabajo' : 'Simple',
                        style: t.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    if (m <= 0) return '0m';
    final h = m ~/ 60;
    final min = m % 60;
    if (h > 0 && min > 0) return '${h}h ${min}m';
    if (h > 0) return '${h}h';
    return '${min}m';
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MetaRow(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurface.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
