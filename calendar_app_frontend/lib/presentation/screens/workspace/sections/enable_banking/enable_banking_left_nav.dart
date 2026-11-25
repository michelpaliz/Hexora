import 'package:hexora/presentation/shared/widgets/navigation_group.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
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
  Widget build(BuildContext context) => Theme(
        data: navigationTheme(Theme.of(context)),
        child: Builder(builder: _buildNavigation),
      );

  Widget _buildNavigation(BuildContext context) {
    const expandedWidth = NavigationTokens.sidebarWidth;
    const collapsedWidth = NavigationTokens.railWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: collapsed ? collapsedWidth : expandedWidth,
      child: SidebarEdgeShell(
        collapsed: collapsed,
        onToggle: onToggleCollapse,
        child: collapsed
            ? _CollapsedRail(
                selected: selected,
                onSelect: onSelect,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
      ),
    );
  }
}

// ── Collapsed icon rail ────────────────────────────────────────────────────────

class _CollapsedRail extends StatelessWidget {
  const _CollapsedRail({
    required this.selected,
    required this.onSelect,
  });

  final EnableBankingMenu selected;
  final void Function(EnableBankingMenu) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = StatementsAnalyticsCopy.isSpanish(context);
    final overviewLabel =
        StatementsAnalyticsCopy.billableOverviewLabel(context);
    final splitLabel = StatementsAnalyticsCopy.splitTitle(context);
    final volumeLabel = StatementsAnalyticsCopy.volumeTitle(context);
    final ticketLabel = StatementsAnalyticsCopy.ticketTitle(context);
    final trendsLabel = isSpanish ? 'Tendencias' : l.statementsAnalyticsTrends;
    final linkedLabel = StatementsAnalyticsCopy.linkedTitle(context);
    final activityLabel = StatementsAnalyticsCopy.activityTitle(context);
    final topMerchantsLabel = StatementsAnalyticsCopy.topMerchantsMenu(context);
    final comparisonLabel = StatementsAnalyticsCopy.comparisonMenu(context);
    final statusLabel = StatementsAnalyticsCopy.statusTitle(context);

    Widget item(IconData icon, String tooltip, EnableBankingMenu menu) {
      return SidebarItem(
          icon: icon,
          label: tooltip,
          isSelected: selected == menu,
          collapsed: true,
          onTap: () => onSelect(menu));
    }

    Widget groupGap() => const SizedBox(height: NavigationTokens.groupGap);

    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
      child: Column(
        children: [
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
                  groupGap(),
                  // Historial
                  item(Icons.table_chart_outlined, 'Movimientos',
                      EnableBankingMenu.allData),
                  groupGap(),
                  // Analiticas
                  item(Icons.dashboard_outlined, overviewLabel,
                      EnableBankingMenu.analyticsOverview),
                  const SizedBox(height: 3),
                  item(Icons.pie_chart_outline_rounded, splitLabel,
                      EnableBankingMenu.analyticsSplit),
                  const SizedBox(height: 3),
                  item(Icons.stacked_bar_chart_rounded, volumeLabel,
                      EnableBankingMenu.analyticsVolume),
                  const SizedBox(height: 3),
                  item(Icons.tune_rounded, ticketLabel,
                      EnableBankingMenu.analyticsTicket),
                  const SizedBox(height: 3),
                  item(Icons.show_chart_outlined, trendsLabel,
                      EnableBankingMenu.analyticsTrends),
                  const SizedBox(height: 3),
                  item(Icons.link_outlined, linkedLabel,
                      EnableBankingMenu.analyticsLinked),
                  const SizedBox(height: 3),
                  item(Icons.calendar_view_week_outlined, activityLabel,
                      EnableBankingMenu.analyticsActivity),
                  const SizedBox(height: 3),
                  item(Icons.bar_chart_outlined, topMerchantsLabel,
                      EnableBankingMenu.analyticsTopMerchants),
                  const SizedBox(height: 3),
                  item(Icons.compare_arrows_outlined, comparisonLabel,
                      EnableBankingMenu.analyticsComparison),
                  const SizedBox(height: 3),
                  item(Icons.verified_outlined, statusLabel,
                      EnableBankingMenu.analyticsStatus),
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
        isSpanish ? 'Analíticas' : l.statementsAnalyticsTitle;
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
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NavSection(
                    title: isSpanish ? 'Banco' : 'Banking',
                    icon: Icons.dataset_outlined,
                    expanded: _sourceExpanded,
                    onToggle: () =>
                        setState(() => _sourceExpanded = !_sourceExpanded),
                    child: _NavSubItem(
                      icon: Icons.file_upload_outlined,
                      label: isSpanish ? 'Importar bancos' : 'Bank import',
                      selected: widget.selected == EnableBankingMenu.banking ||
                          widget.selected == EnableBankingMenu.imports ||
                          widget.selected == EnableBankingMenu.history,
                      onTap: () => widget.onSelect(EnableBankingMenu.banking),
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
                        _AnalyticsSectionLabel(
                          label: isSpanish ? 'RENDIMIENTO' : 'PERFORMANCE',
                        ),
                        _NavSubItem(
                          icon: Icons.pie_chart_outline_rounded,
                          label: analyticsSplitLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsSplit,
                          onTap: () =>
                              widget.onSelect(EnableBankingMenu.analyticsSplit),
                        ),
                        _NavSubItem(
                          icon: Icons.stacked_bar_chart_rounded,
                          label: isSpanish ? 'Volumen' : 'Volume',
                          tooltipLabel: analyticsVolumeLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsVolume,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsVolume),
                        ),
                        _NavSubItem(
                          icon: Icons.tune_rounded,
                          label: analyticsTicketLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsTicket,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsTicket),
                        ),
                        _NavSubItem(
                          icon: Icons.show_chart_outlined,
                          label: analyticsTrendsLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsTrends,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsTrends),
                        ),
                        _AnalyticsSectionLabel(
                          label: isSpanish ? 'MOVIMIENTOS' : 'MOVEMENTS',
                        ),
                        _NavSubItem(
                          icon: Icons.link_outlined,
                          label: isSpanish ? 'Vinculación' : 'Linking',
                          tooltipLabel: analyticsLinkedLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsLinked,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsLinked),
                        ),
                        _NavSubItem(
                          icon: Icons.calendar_view_week_outlined,
                          label: analyticsActivityLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsActivity,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsActivity),
                        ),
                        _NavSubItem(
                          icon: Icons.bar_chart_outlined,
                          label: analyticsTopMerchantsLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsTopMerchants,
                          onTap: () => widget.onSelect(
                              EnableBankingMenu.analyticsTopMerchants),
                        ),
                        _AnalyticsSectionLabel(
                          label: isSpanish
                              ? 'ANÁLISIS AVANZADO'
                              : 'ADVANCED ANALYSIS',
                        ),
                        _NavSubItem(
                          icon: Icons.compare_arrows_outlined,
                          label: analyticsComparisonLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsComparison,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsComparison),
                        ),
                        _NavSubItem(
                          icon: Icons.verified_outlined,
                          label: analyticsStatusLabel,
                          selected: widget.selected ==
                              EnableBankingMenu.analyticsStatus,
                          onTap: () => widget
                              .onSelect(EnableBankingMenu.analyticsStatus),
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
  Widget build(BuildContext context) => NavigationGroup(
      title: title,
      icon: icon,
      expanded: expanded,
      onToggle: onToggle,
      child: child);
}

class _NavSubItem extends StatelessWidget {
  const _NavSubItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltipLabel,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltipLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: NavigationTokens.childGap),
        child: SidebarItem(
            icon: icon,
            label: label,
            isSelected: selected,
            collapsed: false,
            rowHeight: 36,
            iconSize: NavigationTokens.iconSize,
            tooltipLabel: tooltipLabel,
            onTap: onTap));
  }
}

class _AnalyticsSectionLabel extends StatelessWidget {
  const _AnalyticsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = NavigationColors(Theme.of(context).colorScheme);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 8, 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: NavigationTokens.section(context).copyWith(
          color: colors.sectionForeground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: .25,
        ),
      ),
    );
  }
}
