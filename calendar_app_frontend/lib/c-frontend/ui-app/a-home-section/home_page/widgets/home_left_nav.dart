import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/sidebar_item.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../widgets/home_section_nav.dart';

/// Persistent collapsible sidebar used on the home page (web / wide layout).
///
/// Expanded width: 240 px. Collapsed width (icon rail): 72 px.
class HomeLeftNav extends StatefulWidget {
  const HomeLeftNav({
    super.key,
    required this.user,
    required this.activeSection,
    required this.sectionItems,
    required this.onSectionSelected,
    this.activeNavRoute,
    this.onNavSelected,
    required this.isDark,
    required this.content,
    this.floatingAction,
    this.showSectionNavBar = true,
    this.onCreateGroupInline,
  });

  final User user;
  final String activeSection;
  final List<HomeSectionNavItem> sectionItems;
  final ValueChanged<String> onSectionSelected;
  final String? activeNavRoute;
  final ValueChanged<String>? onNavSelected;
  final bool isDark;
  final Widget content;
  final Widget? floatingAction;
  final bool showSectionNavBar;
  final VoidCallback? onCreateGroupInline;

  @override
  State<HomeLeftNav> createState() => _HomeLeftNavState();
}

class _HomeLeftNavState extends State<HomeLeftNav> {
  bool _collapsed = false;

  void _toggle() => setState(() => _collapsed = !_collapsed);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sidebar ──────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                width: _collapsed ? 72.0 : 240.0,
                child: _HomeSidebarContent(
                  user: widget.user,
                  activeNavRoute: widget.activeNavRoute,
                  onNavSelected: widget.onNavSelected,
                  isDark: widget.isDark,
                  collapsed: _collapsed,
                  onToggle: _toggle,
                  onCreateGroupInline: widget.onCreateGroupInline,
                  loc: loc,
                ),
              ),
              const SizedBox(width: 12),
              // ── Content area ─────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.showSectionNavBar) ...[
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: HomeSectionNav(
                              items: widget.sectionItems,
                              selectedId: widget.activeSection,
                              onSelect: widget.onSectionSelected,
                              isDark: widget.isDark,
                              axis: Axis.horizontal,
                              padding:
                                  const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Expanded(child: widget.content),
                      ],
                    ),
                    if (widget.floatingAction != null)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: widget.floatingAction!,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar card content
// ─────────────────────────────────────────────────────────────────────────────

class _HomeSidebarContent extends StatelessWidget {
  const _HomeSidebarContent({
    required this.user,
    required this.activeNavRoute,
    required this.onNavSelected,
    required this.isDark,
    required this.collapsed,
    required this.onToggle,
    required this.onCreateGroupInline,
    required this.loc,
  });

  final User user;
  final String? activeNavRoute;
  final ValueChanged<String>? onNavSelected;
  final bool isDark;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback? onCreateGroupInline;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (label: loc.home, icon: Icons.home_rounded, route: AppRoutes.homePage),
      (
        label: loc.agenda,
        icon: Icons.event_note_rounded,
        route: AppRoutes.agenda,
      ),
      (
        label: loc.notifications,
        icon: Icons.notifications_none_rounded,
        route: AppRoutes.showNotifications,
      ),
      (
        label: loc.settings,
        icon: Icons.settings_outlined,
        route: AppRoutes.settings,
      ),
    ];

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile header
          _SidebarProfileHeader(
            user: user,
            isDark: isDark,
            collapsed: collapsed,
            onToggle: onToggle,
          ),
          const SizedBox(height: 4),
          // Nav items
          for (final item in navItems)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              child: SidebarItem(
                icon: item.icon,
                label: item.label,
                isSelected: activeNavRoute == item.route,
                collapsed: collapsed,
                onTap: () {
                  if (onNavSelected != null) {
                    onNavSelected!(item.route);
                  } else {
                    Navigator.pushReplacementNamed(context, item.route);
                  }
                },
              ),
            ),
          // Separator + Grupos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Divider(
              height: 1,
              thickness: 0.6,
              color: (isDark
                      ? AppDarkColors.textSecondary
                      : AppColors.textSecondary)
                  .withValues(alpha: 0.25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: SidebarItem(
              icon: Icons.group_add_rounded,
              label: loc.groupSectionTitle,
              isSelected: activeNavRoute == AppRoutes.createGroupData,
              collapsed: collapsed,
              onTap: () {
                if (onNavSelected != null) {
                  onNavSelected!(AppRoutes.createGroupData);
                }
                onCreateGroupInline?.call();
                if (onNavSelected == null && onCreateGroupInline == null) {
                  Navigator.pushNamed(context, AppRoutes.createGroupData);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile header inside the sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarProfileHeader extends StatelessWidget {
  const _SidebarProfileHeader({
    required this.user,
    required this.isDark,
    required this.collapsed,
    required this.onToggle,
  });

  final User user;
  final bool isDark;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;

    final avatar = GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.profileDetails),
      child: CircleAvatar(
        radius: collapsed ? 18 : 20,
        backgroundColor: textColor.withValues(alpha: 0.12),
        backgroundImage:
            (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
        child: (user.photoUrl == null || user.photoUrl!.isEmpty)
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: typo.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );

    final toggleBtn = IconButton(
      icon: Icon(
        collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
        size: 20,
        color: textColor.withValues(alpha: 0.6),
      ),
      tooltip: collapsed ? 'Expand' : 'Collapse',
      onPressed: onToggle,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );

    return Container(
      color: bg.withValues(alpha: 0.6),
      padding: EdgeInsets.fromLTRB(
        collapsed ? 0 : 14,
        14,
        collapsed ? 0 : 8,
        10,
      ),
      child: collapsed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(height: 4),
                toggleBtn,
              ],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        style: typo.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${user.userName}',
                        style: typo.bodySmall.copyWith(
                          color: textColor.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                toggleBtn,
              ],
            ),
    );
  }
}
