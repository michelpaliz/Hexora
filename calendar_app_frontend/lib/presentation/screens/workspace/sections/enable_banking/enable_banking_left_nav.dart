import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'statements/analytics/statements_analytics_copy.dart';

enum EnableBankingMenu {
  imports,
  history,
  banking,
  allData,
  analyticsOverview,
  analyticsSplit,
  analyticsVolume,
  analyticsTicket,
  analyticsLinked,
  analyticsActivity,
  analyticsStatus,
  analyticsTrends,
  analyticsTopMerchants,
  analyticsComparison,
}

class EnableBankingLeftNav extends StatelessWidget {
  const EnableBankingLeftNav({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final EnableBankingMenu selected;
  final void Function(EnableBankingMenu menu) onSelect;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    const expandedWidth = 218.0;
    const collapsedWidth = 50.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: collapsed ? collapsedWidth : expandedWidth,
      child: collapsed
          ? _CollapsedRail(
              selected: selected,
              onSelect: onSelect,
              onExpand: onToggleCollapse,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavPanelHeader(onCollapse: onToggleCollapse),
                Expanded(
                  child: _GroupedNavContent(
                    selected: selected,
                    onSelect: onSelect,
                    collapsed: false,
                    onToggleCollapse: onToggleCollapse,
                  ),
                ),
              ],
            ),
    );
  }
}

class _NavPanelHeader extends StatelessWidget {
  const _NavPanelHeader({required this.onCollapse});

  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banco',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Menu de datos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Contraer menu',
              child: IconButton.filledTonal(
                onPressed: onCollapse,
                icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 34),
                  fixedSize: const Size(40, 34),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Collapsed icon rail ────────────────────────────────────────────────────────

class _CollapsedRail extends StatelessWidget {
  const _CollapsedRail({
    required this.selected,
    required this.onSelect,
    required this.onExpand,
  });

  final EnableBankingMenu selected;
  final void Function(EnableBankingMenu) onSelect;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item(IconData icon, String tooltip, EnableBankingMenu menu) {
      final isSel = selected == menu;
      return Tooltip(
        message: tooltip,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: () => onSelect(menu),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 34,
            decoration: BoxDecoration(
              color: isSel
                  ? cs.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel
                    ? cs.primary.withValues(alpha: 0.22)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSel ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    Widget divider() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
      child: Column(
        children: [
          // Expand toggle
          Tooltip(
            message: 'Expandir menú',
            preferBelow: false,
            child: InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Source Datos
                  item(Icons.account_balance_outlined, 'Bancos',
                      EnableBankingMenu.banking),
                  const SizedBox(height: 3),
                  item(Icons.file_upload_outlined, 'Importar Excel',
                      EnableBankingMenu.imports),
                  const SizedBox(height: 3),
                  item(Icons.history_outlined, 'Historial',
                      EnableBankingMenu.history),
                  divider(),
                  // Historial
                  item(Icons.table_chart_outlined, 'Movimientos',
                      EnableBankingMenu.allData),
                  divider(),
                  // Analiticas
                  item(Icons.dashboard_outlined, 'Resumen',
                      EnableBankingMenu.analyticsOverview),
                  const SizedBox(height: 3),
                  item(Icons.pie_chart_outline_rounded, 'Ingresos vs Gastos',
                      EnableBankingMenu.analyticsSplit),
                  const SizedBox(height: 3),
                  item(Icons.stacked_bar_chart_rounded, 'Volumen',
                      EnableBankingMenu.analyticsVolume),
                  const SizedBox(height: 3),
                  item(Icons.tune_rounded, 'Ticket medio',
                      EnableBankingMenu.analyticsTicket),
                  const SizedBox(height: 3),
                  item(Icons.link_outlined, 'Vinculados',
                      EnableBankingMenu.analyticsLinked),
                  const SizedBox(height: 3),
                  item(Icons.calendar_view_week_outlined, 'Actividad',
                      EnableBankingMenu.analyticsActivity),
                  const SizedBox(height: 3),
                  item(Icons.verified_outlined, 'Estado',
                      EnableBankingMenu.analyticsStatus),
                  const SizedBox(height: 3),
                  item(Icons.show_chart_outlined, 'Tendencias',
                      EnableBankingMenu.analyticsTrends),
                  const SizedBox(height: 3),
                  item(Icons.bar_chart_outlined, 'Top comercios',
                      EnableBankingMenu.analyticsTopMerchants),
                  const SizedBox(height: 3),
                  item(Icons.compare_arrows_outlined, 'Comparativa',
                      EnableBankingMenu.analyticsComparison),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedNavContent extends StatefulWidget {
  const _GroupedNavContent({
    required this.selected,
    required this.onSelect,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  final EnableBankingMenu selected;
  final void Function(EnableBankingMenu menu) onSelect;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  @override
  State<_GroupedNavContent> createState() => _GroupedNavContentState();
}

class _GroupedNavContentState extends State<_GroupedNavContent> {
  bool _sourceExpanded = true;
  bool _historyExpanded = true;
  bool _analyticsExpanded = true;

  bool get _analyticsSelected =>
      widget.selected == EnableBankingMenu.analyticsOverview ||
      widget.selected == EnableBankingMenu.analyticsSplit ||
      widget.selected == EnableBankingMenu.analyticsVolume ||
      widget.selected == EnableBankingMenu.analyticsTicket ||
      widget.selected == EnableBankingMenu.analyticsLinked ||
      widget.selected == EnableBankingMenu.analyticsActivity ||
      widget.selected == EnableBankingMenu.analyticsStatus ||
      widget.selected == EnableBankingMenu.analyticsTrends ||
      widget.selected == EnableBankingMenu.analyticsTopMerchants ||
      widget.selected == EnableBankingMenu.analyticsComparison;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = StatementsAnalyticsCopy.isSpanish(context);
    final allDataMenuLabel =
        isSpanish ? 'Movimientos' : l.statementsAllDataTitle;
    final analyticsMenuLabel =
        isSpanish ? 'Analiticas' : l.statementsAnalyticsTitle;
    final analyticsSummaryLabel =
        StatementsAnalyticsCopy.billableOverviewLabel(context);
    final analyticsSplitLabel = StatementsAnalyticsCopy.splitTitle(context);
    final analyticsVolumeLabel = StatementsAnalyticsCopy.volumeTitle(context);
    final analyticsTicketLabel = StatementsAnalyticsCopy.ticketTitle(context);
    final analyticsLinkedLabel = StatementsAnalyticsCopy.linkedTitle(context);
    final analyticsActivityLabel =
        StatementsAnalyticsCopy.activityTitle(context);
    final analyticsStatusLabel = StatementsAnalyticsCopy.statusTitle(context);
    final analyticsTrendsLabel =
        isSpanish ? 'Tendencias' : l.statementsAnalyticsTrends;
    final analyticsTopMerchantsLabel =
        StatementsAnalyticsCopy.topMerchantsMenu(context);
    final analyticsComparisonLabel =
        StatementsAnalyticsCopy.comparisonMenu(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NavSection(
                    title: 'Source Datos',
                    icon: Icons.dataset_outlined,
                    expanded: _sourceExpanded,
                    onToggle: () =>
                        setState(() => _sourceExpanded = !_sourceExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavSubItem(
                          icon: Icons.account_balance_outlined,
                          label: 'Bancos',
                          selected:
                              widget.selected == EnableBankingMenu.banking,
                          onTap: () =>
                              widget.onSelect(EnableBankingMenu.banking),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.file_upload_outlined,
                          label: 'Importar Excel',
                          selected:
                              widget.selected == EnableBankingMenu.imports,
                          onTap: () =>
                              widget.onSelect(EnableBankingMenu.imports),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.history_outlined,
                          label: l.statementsHistoryTabTitle,
                          selected:
                              widget.selected == EnableBankingMenu.history,
                          onTap: () =>
                              widget.onSelect(EnableBankingMenu.history),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NavSection(
                    title: l.statementsHistoryTabTitle,
                    icon: Icons.table_chart_outlined,
                    expanded: _historyExpanded,
                    onToggle: () =>
                        setState(() => _historyExpanded = !_historyExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavSubItem(
                          icon: Icons.table_chart_outlined,
                          label: allDataMenuLabel,
                          selected:
                              widget.selected == EnableBankingMenu.allData,
                          onTap: () =>
                              widget.onSelect(EnableBankingMenu.allData),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NavSection(
                    title: analyticsMenuLabel,
                    icon: Icons.analytics_outlined,
                    expanded: _analyticsExpanded,
                    selected: _analyticsSelected,
                    onToggle: () => setState(
                        () => _analyticsExpanded = !_analyticsExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavSubItem(
                          icon: Icons.dashboard_outlined,
                          label: analyticsSummaryLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsOverview,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsOverview),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.pie_chart_outline_rounded,
                          label: analyticsSplitLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsSplit,
                          onTap: () =>
                              widget.onSelect(EnableBankingMenu.analyticsSplit),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.stacked_bar_chart_rounded,
                          label: analyticsVolumeLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsVolume,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsVolume),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.tune_rounded,
                          label: analyticsTicketLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsTicket,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsTicket),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.link_outlined,
                          label: analyticsLinkedLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsLinked,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsLinked),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.calendar_view_week_outlined,
                          label: analyticsActivityLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsActivity,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsActivity),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.verified_outlined,
                          label: analyticsStatusLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsStatus,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsStatus),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.show_chart_outlined,
                          label: analyticsTrendsLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsTrends,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsTrends),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.bar_chart_outlined,
                          label: analyticsTopMerchantsLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsTopMerchants,
                          onTap: () => widget.onSelect(
                              EnableBankingMenu.analyticsTopMerchants),
                        ),
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.compare_arrows_outlined,
                          label: analyticsComparisonLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsComparison,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsComparison),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.selected = false,
  });

  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final active = selected || expanded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color:
            active ? cs.surfaceContainerHighest.withValues(alpha: 0.28) : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? cs.outlineVariant.withValues(alpha: 0.36)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.18)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: t.labelMedium?.copyWith(
                        color: selected ? cs.primary : cs.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 4),
            child,
          ],
        ],
      ),
    );
  }
}

class _NavSubItem extends StatelessWidget {
  const _NavSubItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.primary : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 2, bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: selected
                ? cs.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.20)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: selected ? 20 : 0,
                margin: const EdgeInsets.only(right: 9),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
