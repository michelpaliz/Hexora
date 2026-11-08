import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

import 'workspace_tab.dart';
import 'workspace_tab_manager.dart';

class WorkspaceTabBar extends StatefulWidget {
  const WorkspaceTabBar({
    super.key,
    required this.manager,
    required this.onClose,
  });

  final WorkspaceTabManager manager;
  final Future<void> Function(WorkspaceTab tab) onClose;

  @override
  State<WorkspaceTabBar> createState() => _WorkspaceTabBarState();
}

class _WorkspaceTabBarState extends State<WorkspaceTabBar> {
  final ScrollController _scrollController = ScrollController();
  final MenuController _allTabsMenu = MenuController();
  final Map<WorkspaceTabIdentity, GlobalKey> _tabKeys = {};
  WorkspaceTabIdentity? _lastActive;
  bool _hasOverflow = false;
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollState);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncScrollState() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final hasOverflow = position.maxScrollExtent > 0.5;
    final canScrollBack = position.pixels > 0.5;
    final canScrollForward = position.pixels < position.maxScrollExtent - 0.5;
    if (_hasOverflow == hasOverflow &&
        _canScrollBack == canScrollBack &&
        _canScrollForward == canScrollForward) {
      return;
    }
    setState(() {
      _hasOverflow = hasOverflow;
      _canScrollBack = canScrollBack;
      _canScrollForward = canScrollForward;
    });
  }

  void _scheduleScrollStateSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncScrollState();
    });
  }

  void _scrollBy(BuildContext context, double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 0.5) return;
    _scrollController.animateTo(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    if (!_hasOverflow || !_scrollController.hasClients) return;
    // Native horizontal trackpad input is already handled by the horizontal
    // Scrollable. Translate only vertical wheel input so it never scrolls
    // twice on devices that report a horizontal delta.
    if (event.scrollDelta.dx.abs() > 0.1) return;
    final wheelDelta = event.scrollDelta.dy;
    if (wheelDelta.abs() < 0.1) return;
    final position = _scrollController.position;
    final target = (position.pixels + wheelDelta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 0.1) return;
    _scrollController.jumpTo(target);
  }

  void _keepActiveVisible(WorkspaceTabIdentity? active) {
    if (active == null || active == _lastActive) return;
    _lastActive = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _tabKeys[active]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: HexoraMotion.duration(context, HexoraMotion.tabNavigation),
          curve: HexoraMotion.enter,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.manager;
    final tabs = manager.tabs;
    final active = manager.activeIdentity;
    _keepActiveVisible(active);
    _scheduleScrollStateSync();
    _tabKeys.removeWhere(
        (identity, _) => !tabs.any((tab) => tab.identity == identity));

    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    return Material(
      color: cs.surfaceContainerLowest,
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            if (_hasOverflow)
              _TabScrollButton(
                key: const ValueKey('workspace-tab-scroll-left'),
                icon: Icons.chevron_left_rounded,
                tooltip: Localizations.localeOf(context).languageCode == 'es'
                    ? 'Desplazar pestañas a la izquierda'
                    : 'Scroll tabs left',
                enabled: _canScrollBack,
                onPressed: () => _scrollBy(context, -220),
              ),
            Expanded(
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) _handlePointerScroll(event);
                },
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _scheduleScrollStateSync();
                    return false;
                  },
                  child: ScrollConfiguration(
                    behavior: const _WorkspaceTabScrollBehavior(),
                    child: ListView.separated(
                      key: const PageStorageKey<String>(
                        'workspace-tab-strip-scroll',
                      ),
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      itemCount: tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 2),
                      itemBuilder: (context, index) {
                        final tab = tabs[index];
                        return KeyedSubtree(
                          key:
                              _tabKeys.putIfAbsent(tab.identity, GlobalKey.new),
                          child: _WorkspaceTabButton(
                            tab: tab,
                            active: active == tab.identity,
                            dirty: manager.isDirty(tab.identity),
                            onActivate: () => manager.activateTab(tab.identity),
                            onClose: () => widget.onClose(tab),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (_hasOverflow)
              _TabScrollButton(
                key: const ValueKey('workspace-tab-scroll-right'),
                icon: Icons.chevron_right_rounded,
                tooltip: Localizations.localeOf(context).languageCode == 'es'
                    ? 'Desplazar pestañas a la derecha'
                    : 'Scroll tabs right',
                enabled: _canScrollForward,
                onPressed: () => _scrollBy(context, 220),
              ),
            if (tabs.isNotEmpty)
              _AllTabsButton(
                controller: _allTabsMenu,
                tabs: tabs,
                active: active,
                isDirty: manager.isDirty,
                locale: locale,
                onSelected: (identity) {
                  _allTabsMenu.close();
                  manager.activateTab(identity);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceTabScrollBehavior extends MaterialScrollBehavior {
  const _WorkspaceTabScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class _TabScrollButton extends StatelessWidget {
  const _TabScrollButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        color: cs.onSurfaceVariant,
        disabledColor: cs.onSurfaceVariant.withValues(alpha: 0.35),
        splashRadius: 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 34),
      ),
    );
  }
}

class _WorkspaceTabButton extends StatefulWidget {
  const _WorkspaceTabButton({
    required this.tab,
    required this.active,
    required this.dirty,
    required this.onActivate,
    required this.onClose,
  });

  final WorkspaceTab tab;
  final bool active;
  final bool dirty;
  final VoidCallback onActivate;
  final VoidCallback onClose;

  @override
  State<_WorkspaceTabButton> createState() => _WorkspaceTabButtonState();
}

class _WorkspaceTabButtonState extends State<_WorkspaceTabButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final navigationColors = NavigationColors(cs);
    final showClose = widget.active || _hovered || _focused;
    final activeBackground = cs.brightness == Brightness.dark
        ? Color.alphaBlend(
            cs.primary.withValues(alpha: 0.16),
            cs.surfaceContainerHigh,
          )
        : navigationColors.selectedBackground;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Tooltip(
          message: widget.tab.title,
          child: Semantics(
            selected: widget.active,
            button: true,
            label: widget.tab.title,
            child: Material(
              color: widget.active
                  ? activeBackground
                  : _hovered || _focused
                      ? navigationColors.hover
                      : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7)),
              child: InkWell(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7)),
                onTap: widget.onActivate,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 108, maxWidth: 210),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(9, 0, 4, 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.tab.icon,
                              size: 16,
                              color: widget.active
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.tab.title,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: NavigationTokens.label(
                                  context,
                                  selected: widget.active,
                                ).copyWith(
                                  color: widget.active
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (widget.dirty && !showClose)
                              Icon(Icons.circle, size: 7, color: cs.primary)
                            else
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: showClose
                                    ? IconButton(
                                        padding: EdgeInsets.zero,
                                        splashRadius: 12,
                                        tooltip:
                                            MaterialLocalizations.of(context)
                                                .closeButtonTooltip,
                                        icon: const Icon(Icons.close_rounded,
                                            size: 15),
                                        onPressed: widget.onClose,
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ),
                      if (widget.active)
                        Container(height: 2, color: cs.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllTabsButton extends StatelessWidget {
  const _AllTabsButton({
    required this.controller,
    required this.tabs,
    required this.active,
    required this.isDirty,
    required this.locale,
    required this.onSelected,
  });

  final MenuController controller;
  final List<WorkspaceTab> tabs;
  final WorkspaceTabIdentity? active;
  final bool Function(WorkspaceTabIdentity identity) isDirty;
  final String locale;
  final ValueChanged<WorkspaceTabIdentity> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewport = MediaQuery.sizeOf(context);
    final width = (viewport.width - 16).clamp(1.0, 340.0).toDouble();
    final maxHeight = (viewport.height * 0.68).clamp(180.0, 560.0).toDouble();
    final tooltip = locale == 'es' ? 'Todas las pestañas' : 'All tabs';

    return MenuAnchor(
      controller: controller,
      alignmentOffset: const Offset(0, 2),
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomEnd,
        backgroundColor: WidgetStatePropertyAll(cs.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(cs.shadow.withValues(alpha: 0.18)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        fixedSize: WidgetStatePropertyAll(Size.fromWidth(width)),
        maximumSize: WidgetStatePropertyAll(Size(width, maxHeight)),
        side: WidgetStatePropertyAll(
          BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: width,
          child: _AllTabsMenu(
            tabs: tabs,
            active: active,
            isDirty: isDirty,
            locale: locale,
            maxHeight: maxHeight,
            onSelected: onSelected,
          ),
        ),
      ],
      builder: (context, menuController, _) => Tooltip(
        message: tooltip,
        child: IconButton(
          key: const ValueKey('workspace-all-tabs-button'),
          onPressed: () => menuController.isOpen
              ? menuController.close()
              : menuController.open(),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 19,
            color: menuController.isOpen ? cs.primary : cs.onSurfaceVariant,
          ),
          padding: EdgeInsets.zero,
          splashRadius: 16,
          constraints: const BoxConstraints.tightFor(width: 30, height: 36),
        ),
      ),
    );
  }
}

class _AllTabsMenu extends StatefulWidget {
  const _AllTabsMenu({
    required this.tabs,
    required this.active,
    required this.isDirty,
    required this.locale,
    required this.maxHeight,
    required this.onSelected,
  });

  final List<WorkspaceTab> tabs;
  final WorkspaceTabIdentity? active;
  final bool Function(WorkspaceTabIdentity identity) isDirty;
  final String locale;
  final double maxHeight;
  final ValueChanged<WorkspaceTabIdentity> onSelected;

  @override
  State<_AllTabsMenu> createState() => _AllTabsMenuState();
}

class _AllTabsMenuState extends State<_AllTabsMenu> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WorkspaceTab> get _filteredTabs {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.tabs;
    return widget.tabs
        .where((tab) => tab.title.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _activateFirstResult() {
    final filtered = _filteredTabs;
    if (filtered.isNotEmpty) widget.onSelected(filtered.first.identity);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final es = widget.locale == 'es';
    final filtered = _filteredTabs;
    final searchHeight = widget.tabs.length > 8 ? 46.0 : 0.0;
    final availableListHeight =
        (widget.maxHeight - 44 - searchHeight).clamp(40.0, 420.0).toDouble();
    final listHeight = (filtered.isEmpty ? 42.0 : filtered.length * 38.0)
        .clamp(38.0, availableListHeight)
        .toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    es ? 'Pestañas abiertas' : 'Open tabs',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.tabs.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.tabs.length > 8)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: (_) => _activateFirstResult(),
                textInputAction: TextInputAction.go,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: es ? 'Buscar pestaña...' : 'Search tabs...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 17),
                  prefixIconConstraints:
                      const BoxConstraints.tightFor(width: 34),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: es ? 'Limpiar búsqueda' : 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 15),
                        ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                ),
              ),
            ),
          ),
        SizedBox(
          height: listHeight,
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    es ? 'No hay resultados' : 'No matching tabs',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  primary: false,
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tab = filtered[index];
                    final selected = tab.identity == widget.active;
                    return Tooltip(
                      message: tab.title,
                      waitDuration: const Duration(milliseconds: 500),
                      child: MenuItemButton(
                        key: ValueKey(
                          'workspace-all-tabs-${tab.identity.value}',
                        ),
                        onPressed: () => widget.onSelected(tab.identity),
                        style: ButtonStyle(
                          minimumSize: const WidgetStatePropertyAll(
                            Size.fromHeight(38),
                          ),
                          maximumSize: const WidgetStatePropertyAll(
                            Size(double.infinity, 38),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 9),
                          ),
                          shape: const WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(7)),
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.hovered) ||
                                  states.contains(WidgetState.focused)) {
                                return NavigationColors(cs).hover;
                              }
                              return selected
                                  ? NavigationColors(cs).selectedBackground
                                  : Colors.transparent;
                            },
                          ),
                        ),
                        leadingIcon: Icon(
                          tab.icon,
                          size: 16,
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                        ),
                        trailingIcon: selected
                            ? Icon(Icons.check_rounded,
                                size: 17, color: cs.primary)
                            : widget.isDirty(tab.identity)
                                ? Icon(Icons.circle, size: 7, color: cs.primary)
                                : const SizedBox(width: 17),
                        child: Text(
                          tab.title,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: NavigationTokens.label(
                            context,
                            selected: selected,
                          ).copyWith(
                            color: selected ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
