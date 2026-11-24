import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/models/create_group_data.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/group_screen/widgets/group_list_placeholders.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

/// Business ("negocio") selector shown on the home screen, below the greeting
/// hero. Presents a titled header, a search + filter toolbar, and a responsive
/// grid of rich business cards, mirroring the product design mockup.
///
/// Data is sourced exactly like [GroupListSection]
/// (`UserDomain` + `GroupDomain.watchGroupsForUser`). Favorites are saved as
/// account preferences and follow the user across devices.
class BusinessSelectorSection extends StatefulWidget {
  const BusinessSelectorSection({super.key});

  @override
  State<BusinessSelectorSection> createState() =>
      _BusinessSelectorSectionState();
}

enum _BusinessFilter { todos, activos, favoritos }

class _BusinessSelectorSectionState extends State<BusinessSelectorSection> {
  final _searchCtrl = TextEditingController();
  _BusinessFilter _filter = _BusinessFilter.todos;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Set<String> get _favorites =>
      context.read<UserPreferencesProvider>().favoriteBusinessIds;

  Future<void> _toggleFavorite(String groupId) =>
      context.read<UserPreferencesProvider>().toggleFavoriteBusiness(groupId);

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  Future<void> _openCreateGroup() async {
    if (kIsWeb) {
      await showHexoraDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 900),
            child: const CreateGroupData(),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.pushNamed(context, AppRoutes.createGroupData);
  }

  Future<void> _openGroup(GroupDomain groupDomain, Group group) async {
    groupDomain.currentGroup = group;
    await Navigator.pushNamed(
      context,
      AppRoutes.groupDashboard,
      arguments: group,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<UserPreferencesProvider>();
    final userDomain = context.watch<UserDomain>();
    final groupDomain = context.watch<GroupDomain>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<User?>(
        valueListenable: userDomain.currentUserNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return StreamBuilder<List<Group>>(
            key: ValueKey('business-selector-${user.id}'),
            stream: groupDomain.watchGroupsForUser(user.id),
            builder: (context, snapshot) {
              final all = snapshot.data ?? const <Group>[];
              final hasCached = all.isNotEmpty;

              Widget content;
              if (groupDomain.groupsLoadError != null && !hasCached) {
                content = _errorState(userDomain, groupDomain);
              } else if (!hasCached &&
                  (groupDomain.groupsLoading ||
                      snapshot.connectionState == ConnectionState.waiting)) {
                content = const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                content = ErrorText('Error: ${snapshot.error}');
              } else {
                content = _loaded(all, user, groupDomain);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  content,
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _errorState(UserDomain userDomain, GroupDomain groupDomain) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ErrorText(_isSpanish
            ? 'No se pudieron cargar los negocios.'
            : 'Businesses could not be loaded.'),
        TextButton.icon(
          onPressed: () => groupDomain.refreshGroupsForCurrentUser(userDomain),
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: Text(_isSpanish ? 'Reintentar' : 'Retry'),
        ),
      ],
    );
  }

  Widget _loaded(List<Group> all, User user, GroupDomain groupDomain) {
    final cs = Theme.of(context).colorScheme;

    final activosCount = all.where((g) => g.hasCalendar).length;
    final favCount = all.where((g) => _favorites.contains(g.id)).length;

    Iterable<Group> filtered = all;
    if (_query.isNotEmpty) {
      filtered = filtered.where((g) => g.name.toLowerCase().contains(_query));
    }
    switch (_filter) {
      case _BusinessFilter.activos:
        filtered = filtered.where((g) => g.hasCalendar);
        break;
      case _BusinessFilter.favoritos:
        filtered = filtered.where((g) => _favorites.contains(g.id));
        break;
      case _BusinessFilter.todos:
        break;
    }
    final groups = filtered.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toolbar(all.length, activosCount, favCount),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: NoGroupsText(
              _query.isNotEmpty || _filter != _BusinessFilter.todos
                  ? (_isSpanish
                      ? 'No hay negocios que coincidan.'
                      : 'No matching businesses.')
                  : (_isSpanish
                      ? 'Aún no tienes negocios.'
                      : 'You have no businesses yet.'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final columns = w >= 1000 ? 3 : (w >= 640 ? 2 : 1);
              const spacing = 14.0;
              final cardWidth = (w - (columns - 1) * spacing) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final group in groups)
                    SizedBox(
                      width: cardWidth,
                      child: _BusinessCard(
                        group: group,
                        isSelected: groupDomain.currentGroup?.id == group.id,
                        isFavorite: _favorites.contains(group.id),
                        isPrincipal: group.ownerId == user.id,
                        isSpanish: _isSpanish,
                        onToggleFavorite: () => _toggleFavorite(group.id),
                        onOpen: () => _openGroup(groupDomain, group),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 18),
        _helpBanner(cs),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _header() {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.layers_rounded, size: 22, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isSpanish ? 'Selecciona un negocio' : 'Select a business',
                style: t.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.4,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _isSpanish
                    ? 'Elige el negocio con el que quieres trabajar.'
                    : 'Choose the business you want to work with.',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Toolbar (search · filters · create) ────────────────────────────────────
  Widget _toolbar(int totalCount, int activosCount, int favCount) {
    final cs = Theme.of(context).colorScheme;

    final search = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: _isSpanish
              ? 'Buscar negocio por nombre…'
              : 'Search business by name…',
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                  tooltip: _isSpanish ? 'Limpiar' : 'Clear',
                ),
        ),
      ),
    );

    final filters = Wrap(
      spacing: 8,
      children: [
        _filterChip(
          label: _isSpanish ? 'Todos' : 'All',
          count: totalCount,
          value: _BusinessFilter.todos,
          icon: Icons.layers_outlined,
        ),
        _filterChip(
          label: _isSpanish ? 'Activos' : 'Active',
          count: activosCount,
          value: _BusinessFilter.activos,
          icon: Icons.bolt_outlined,
        ),
        _filterChip(
          label: _isSpanish ? 'Favoritos' : 'Favorites',
          count: favCount,
          value: _BusinessFilter.favoritos,
          icon: Icons.star_border_rounded,
        ),
      ],
    );

    final createBtn = FilledButton.icon(
      onPressed: _openCreateGroup,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(_isSpanish ? 'Crear negocio' : 'Create business'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        search,
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [filters, createBtn],
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required int count,
    required _BusinessFilter value,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selected = _filter == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
      ),
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
      ),
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      side: BorderSide(
        color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  // ── Help banner ────────────────────────────────────────────────────────────
  Widget _helpBanner(ColorScheme cs) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.info_outline_rounded, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSpanish ? '¿Necesitas ayuda?' : 'Need help?',
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSpanish
                      ? 'Puedes crear un nuevo negocio, gestionar los existentes o consultar la documentación.'
                      : 'You can create a new business, manage existing ones, or check the documentation.',
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _openCreateGroup,
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: Text(_isSpanish ? 'Ver guía rápida' : 'Quick guide'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Business card ────────────────────────────────────────────────────────────

class _BusinessCard extends StatefulWidget {
  const _BusinessCard({
    required this.group,
    required this.isSelected,
    required this.isFavorite,
    required this.isPrincipal,
    required this.isSpanish,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  final Group group;
  final bool isSelected;
  final bool isFavorite;
  final bool isPrincipal;
  final bool isSpanish;
  final VoidCallback onToggleFavorite;
  final Future<void> Function() onOpen;

  @override
  State<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<_BusinessCard> {
  bool _hovering = false;
  bool _opening = false;

  /// Stable, per-group placeholder document count. There is no backend field
  /// for this yet, so it is derived deterministically from the group id so it
  /// does not flicker on rebuilds.
  int get _docCountPlaceholder => (widget.group.id.hashCode.abs() % 18) + 2;

  Future<void> _handleOpen() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpen();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final group = widget.group;
    final es = widget.isSpanish;
    final selected = widget.isSelected;

    final services = group.description.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? cs.primary
                : _hovering
                    ? cs.primary.withValues(alpha: 0.32)
                    : cs.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.6 : 1,
          ),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surface,
                    cs.primaryContainer.withValues(alpha: 0.18),
                  ],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: _hovering ? 0.10 : 0.04),
              blurRadius: _hovering ? 14 : 10,
              offset: Offset(0, _hovering ? 5 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _opening ? null : _handleOpen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnail + favourite star
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: AvatarUtils.groupAvatar(
                              context,
                              group.displayPhotoUrl,
                              radius: 28,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: widget.isFavorite
                            ? (es ? 'Quitar de favoritos' : 'Remove favourite')
                            : (es ? 'Marcar favorito' : 'Mark favourite'),
                        onPressed: widget.onToggleFavorite,
                        icon: Icon(
                          widget.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 22,
                          color: widget.isFavorite
                              ? const Color(0xFFF5B301)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Name + selected check
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.2,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded,
                              size: 16, color: cs.onPrimary),
                        ),
                      ],
                    ],
                  ),
                  if (services.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      services,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  if (widget.isPrincipal) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        es ? 'Principal' : 'Primary',
                        style: t.caption.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  // Meta rows
                  _metaRow(
                    cs,
                    t,
                    Icons.people_outline_rounded,
                    '${group.userIds.length} ${es ? 'miembros' : 'members'}',
                  ),
                  const SizedBox(height: 8),
                  _metaRow(
                    cs,
                    t,
                    Icons.event_outlined,
                    group.hasCalendar
                        ? (es ? 'Calendario activo' : 'Calendar active')
                        : (es
                            ? 'Sin tareas programadas'
                            : 'No scheduled tasks'),
                  ),
                  const SizedBox(height: 8),
                  _metaRow(
                    cs,
                    t,
                    Icons.folder_outlined,
                    '${es ? 'Documentos' : 'Documents'} ($_docCountPlaceholder)',
                  ),
                  const SizedBox(height: 8),
                  _metaRow(
                    cs,
                    t,
                    Icons.verified_outlined,
                    es ? 'Contrato vigente' : 'Active contract',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow(ColorScheme cs, AppTypography t, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
