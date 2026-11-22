import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

import '../state/group_dashboard_state.dart';
import 'dashboard_sections.dart';

/// Compact business-dashboard navigation for mobile screens.
///
/// Destinations open the existing dashboard sections. The dashboard itself is
/// always the selected destination because pushed sections provide their own
/// navigation state when visible.
class DashboardMobileNav extends StatelessWidget {
  const DashboardMobileNav({
    super.key,
    required this.state,
  });

  final GroupDashboardState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final es = l.localeName.startsWith('es');
    final cs = Theme.of(context).colorScheme;
    final activeSection = state.activeSection;
    final primarySections = <String>{
      Sections.emails,
      Sections.workers,
      Sections.chat,
      Sections.businessChat,
      Sections.profile,
    };

    void select(String section) => state.selectSection(section);

    return Material(
      color: cs.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .08),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: .45),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _DashboardNavItem(
                  icon: LucideIcons.house,
                  label: l.home,
                  selected: !primarySections.contains(activeSection),
                  onTap: () => select(Sections.home),
                ),
              ),
              Expanded(
                child: _DashboardNavItem(
                  icon: LucideIcons.mail,
                  label: es ? 'Correo' : 'Email',
                  selected: activeSection == Sections.emails,
                  onTap: () => select(Sections.emails),
                ),
              ),
              Expanded(
                child: _DashboardNavItem(
                  icon: LucideIcons.users,
                  label: es ? 'Trabajadores' : 'Workers',
                  selected: activeSection == Sections.workers,
                  onTap: () => select(Sections.workers),
                ),
              ),
              if (state.canSeeAdmin)
                Expanded(
                  child: _DashboardNavItem(
                    icon: LucideIcons.sparkles,
                    label: es ? 'IA' : 'AI',
                    tooltip: l.insightsChatFabTooltip,
                    selected: activeSection == Sections.chat,
                    onTap: () => select(Sections.chat),
                  ),
                ),
              Expanded(
                child: _DashboardNavItem(
                  icon: LucideIcons.messageCircle,
                  label: es ? 'Chat' : 'Chat',
                  selected: activeSection == Sections.businessChat,
                  onTap: () => select(Sections.businessChat),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardNavItem extends StatelessWidget {
  const _DashboardNavItem({
    required this.label,
    required this.icon,
    this.tooltip,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? tooltip;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: tooltip ?? label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: NavigationTokens.iconSize, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
