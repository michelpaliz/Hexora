import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum EnableBankingMenu {
  imports,
  history,
  banking,
  allData,
  analytics,
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
    const width = 186.0;
    return SizedBox(
      width: width,
      child: _GroupedNavContent(
        selected: selected,
        onSelect: onSelect,
        collapsed: false,
        onToggleCollapse: onToggleCollapse,
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final allDataMenuLabel =
        isSpanish ? 'Movimientos' : l.statementsAllDataTitle;
    final analyticsMenuLabel =
        isSpanish ? 'Analíticas' : l.statementsAnalyticsTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
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
                        const SizedBox(height: 4),
                        _NavSubItem(
                          icon: Icons.analytics_outlined,
                          label: analyticsMenuLabel,
                          selected:
                              widget.selected == EnableBankingMenu.analytics,
                          onTap: () =>
                              widget.onSelect(EnableBankingMenu.analytics),
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
  });

  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: t.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: cs.onSurfaceVariant,
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
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected ? cs.primaryContainer : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (selected)
                      Container(
                        width: 3,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}
