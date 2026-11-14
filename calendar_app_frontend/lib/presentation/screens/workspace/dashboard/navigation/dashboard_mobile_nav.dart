import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/navigation/horizontal_nav/components/avatar_icon.dart';
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
                  icon: Icons.home_rounded,
                  label: l.home,
                  selected: true,
                ),
              ),
              Expanded(
                child: _DashboardNavItem(
                  icon: Icons.mail_outline_rounded,
                  label: es ? 'Correo' : 'Email',
                  onTap: () => state.openSection(Sections.emails),
                ),
              ),
              Expanded(
                child: _DashboardNavItem(
                  icon: Icons.access_time_rounded,
                  label: es ? 'Trabajadores' : 'Workers',
                  onTap: () => state.openSection(Sections.workers),
                ),
              ),
              Expanded(
                child: _DashboardNavItem(
                  icon: Icons.forum_rounded,
                  label: es ? 'Chat' : 'Chat',
                  onTap: () => state.openSection(Sections.businessChat),
                ),
              ),
              Expanded(
                child: _DashboardNavItem(
                  label: l.profile,
                  customIcon: AvatarIcon(
                    photoUrl: state.user?.photoUrl,
                    isSelected: false,
                    activeColor: cs.primary,
                    inactiveColor: cs.onSurfaceVariant,
                  ),
                  onTap: () => state.openSection(Sections.profile),
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
    this.icon,
    this.customIcon,
    this.selected = false,
    this.onTap,
  }) : assert(icon != null || customIcon != null);

  final String label;
  final IconData? icon;
  final Widget? customIcon;
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
        message: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                customIcon ??
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
