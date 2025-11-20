import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/agenda/agenda_model.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart'; // ⬅️ for currentGroup fallback
import 'package:hexora/b-backend/user/domain/user_agenda_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart'; // ⬅️ for navigation to groups
import 'package:hexora/c-frontend/ui-app/g-agenda-section/sections/agenda_filters_section.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/sections/agenda_header_section.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/sections/agenda_list_section.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:provider/provider.dart';

class AgendaScreen extends StatefulWidget {
  final String? groupId;

  const AgendaScreen({super.key, this.groupId});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _loading = true;
  String? _error;
  List<AgendaItem> _items = [];
  int _daysRange = 14;

  /// Category filter token:
  /// - 'all'
  /// - 'cat:<categoryId>'
  /// - 'sub:<subcategoryId>'
  String _category = 'all';

  /// Type filter token from chips: 'all' | 'simple' | 'work_service'
  /// (Backend stores 'work_visit'; we normalize below.)
  String _type = 'all';

  /// Show category filter UI only if type is "simple"
  bool get _showCategories => _type == 'simple';

  /// Normalize/recognize "work" both as work_service (UI) and work_visit (DB)
  bool _isWorkToken(String v) {
    final t = v.toLowerCase();
    return t == 'work_service' || t == 'work_visit';
  }

  bool _isWorkEvent(AgendaItem it) => _isWorkToken(it.event.type);

  @override
  void initState() {
    super.initState();
    // Defer to next frame so Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAgenda());
  }

  /// Resolve the group id to use:
  /// 1) explicit widget.groupId
  /// 2) fallback to groupDomain.currentGroup?.id
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

  /// Loads events from backend (if a group is available).
  /// If no group is resolved, render UI without data and show a prompt.
  Future<void> _loadAgenda() async {
    final gid = _resolveGroupId();

    if (!mounted) return;

    if (gid == null || gid.isEmpty) {
      setState(() {
        _loading = false;
        _error = null; // not an error — just no group yet
        _items = const [];
      });
      return;
    }

    try {
      setState(() => _loading = true);

      // 🔄 use UserAgendaDomain here instead of UserDomain
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

  /// Applies group, type, and category filters to agenda items
  List<AgendaItem> _applyAllFilters(List<AgendaItem> all) {
    Iterable<AgendaItem> out = all;
    final gid = _resolveGroupId();

    // 1) Group filter (only if we have one resolved)
    if (gid != null && gid.isNotEmpty) {
      out = out.where((it) => it.event.groupId == gid);
    }

    // 2) Category filter — ONLY applied when type == 'simple'
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

    // 3) Type filter — accept both 'work_service' (UI) and 'work_visit' (backend)
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

    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else {
      body = RefreshIndicator(
        onRefresh: _loadAgenda,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            /// HEADER SECTION (use filtered so it matches chips)
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

            /// If no group resolved, show a small prompt card (UI still renders)
            if (gid == null)
              SliverToBoxAdapter(
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: const Text('Select a group to load events'),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.showGroups).then(
                            (_) => _loadAgenda()); // reload after selection
                      },
                      child: const Text('Choose'),
                    ),
                  ),
                ),
              ),

            /// FILTERS SECTION (tabs/chips are always visible)
            AgendaFiltersSection(
              category: _category,
              type: _type,
              showCategories: _showCategories,
              onCategoryChanged: (c) => setState(() => _category = c),
              onTypeChanged: (t) => setState(() {
                _type = t;
                // Reset category when leaving "Simple"
                if (_type != 'simple') _category = 'all';
              }),
            ),

            /// LIST SECTION
            AgendaListSection(filteredItems: filtered),
          ],
        ),
      );
    }

    return MainScaffold(
      showAppBar: false,
      body: body,
    );
  }
}
