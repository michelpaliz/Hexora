import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum EnableBankingMenu {
  imports,
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
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final width = collapsed ? 76.0 : 240.0;
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: collapsed
                        ? l.statementsNavExpand
                        : l.statementsNavCollapse,
                    onPressed: onToggleCollapse,
                    icon: Icon(
                        collapsed ? Icons.chevron_right : Icons.chevron_left),
                  ),
                  if (!collapsed)
                    Text(
                      l.statementsNavTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _NavItem(
                icon: Icons.file_upload_outlined,
                label: l.statementsTabTitle,
                selected: selected == EnableBankingMenu.imports,
                onTap: () => onSelect(EnableBankingMenu.imports),
                colorScheme: cs,
                collapsed: collapsed,
              ),
              const SizedBox(height: 6),
              _NavItem(
                icon: Icons.table_chart_outlined,
                label: l.statementsAllDataTitle,
                selected: selected == EnableBankingMenu.allData,
                onTap: () => onSelect(EnableBankingMenu.allData),
                colorScheme: cs,
                collapsed: collapsed,
              ),
              const SizedBox(height: 6),
              _NavItem(
                icon: Icons.analytics_outlined,
                label: l.statementsAnalyticsTitle,
                selected: selected == EnableBankingMenu.analytics,
                onTap: () => onSelect(EnableBankingMenu.analytics),
                colorScheme: cs,
                collapsed: collapsed,
              ),
              const SizedBox(height: 6),
              _NavItem(
                icon: Icons.account_balance_outlined,
                label: l.bankProvidersTabTitle,
                selected: selected == EnableBankingMenu.banking,
                onTap: () => onSelect(EnableBankingMenu.banking),
                colorScheme: cs,
                collapsed: collapsed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
    required this.collapsed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;

    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: fg),
            if (!collapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: fg, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (collapsed) {
      return Tooltip(message: label, child: child);
    }
    return child;
  }
}
