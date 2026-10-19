import 'package:hexora/presentation/shared/widgets/navigation_group.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/navigation_menu_header.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
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
  Widget build(BuildContext context) =>
      NavigationSurface(builder: _buildNavigation);

  Widget _buildNavigation(BuildContext context) {
    const expandedWidth = NavigationTokens.sidebarWidth;
    const collapsedWidth = NavigationTokens.railWidth;

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
    return NavigationMenuHeader(
        title: Localizations.localeOf(context).languageCode == 'es'
            ? 'Banco'
            : 'Banking',
        icon: Icons.account_balance_outlined,
        onToggle: onCollapse);
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
      return SidebarItem(icon: icon, label: tooltip, isSelected: selected == menu,
        collapsed: true, onTap: () => onSelect(menu));
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
                width: NavigationTokens.rowHeight(context),
                height: NavigationTokens.rowHeight(context),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: NavigationTokens.iconSize,
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
  Widget build(BuildContext context) => NavigationGroup(title: title, icon: icon,
    expanded: expanded, onToggle: onToggle, child: child);
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
    return Padding(
        padding: const EdgeInsets.only(left: NavigationTokens.nestedIndent, right: 0, bottom: NavigationTokens.itemGap),
        child: SidebarItem(
            icon: icon,
            label: label,
            isSelected: selected,
            collapsed: false,
            onTap: onTap));
  }
}
