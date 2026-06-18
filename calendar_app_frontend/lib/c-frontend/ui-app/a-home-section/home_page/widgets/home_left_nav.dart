import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/sidebar_item.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/user_profile_popup.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../widgets/home_section_nav.dart';

/// Persistent sidebar used on the home page (web / wide layout).
/// Fixed width and always expanded.
class HomeLeftNav extends StatelessWidget {
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
              SizedBox(
                width: 240,
                child: _HomeSidebarContent(
                  user: user,
                  activeNavRoute: activeNavRoute,
                  onNavSelected: onNavSelected,
                  isDark: isDark,
                  onCreateGroupInline: onCreateGroupInline,
                  loc: loc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showSectionNavBar) ...[
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: HomeSectionNav(
                              items: sectionItems,
                              selectedId: activeSection,
                              onSelect: onSectionSelected,
                              isDark: isDark,
                              axis: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Expanded(child: content),
                      ],
                    ),
                    if (floatingAction != null)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: floatingAction!,
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

class _HomeSidebarContent extends StatelessWidget {
  const _HomeSidebarContent({
    required this.user,
    required this.activeNavRoute,
    required this.onNavSelected,
    required this.isDark,
    required this.onCreateGroupInline,
    required this.loc,
  });

  final User user;
  final String? activeNavRoute;
  final ValueChanged<String>? onNavSelected;
  final bool isDark;
  final VoidCallback? onCreateGroupInline;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (label: loc.home, icon: Icons.home_rounded, route: AppRoutes.homePage),
      if (!kIsWeb)
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

    final dividerColor =
        (isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)
            .withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SidebarProfileHeader(user: user, isDark: isDark),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: dividerColor, indent: 16, endIndent: 16),
        const SizedBox(height: 8),
        for (final item in navItems)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: SidebarItem(
              icon: item.icon,
              label: item.label,
              isSelected: activeNavRoute == item.route,
              collapsed: false,
              onTap: () {
                if (onNavSelected != null) {
                  onNavSelected!(item.route);
                } else {
                  Navigator.pushReplacementNamed(context, item.route);
                }
              },
            ),
          ),
      ],
    );
  }
}

class _SidebarProfileHeader extends StatelessWidget {
  const _SidebarProfileHeader({
    required this.user,
    required this.isDark,
  });

  final User user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;

    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: hasPhoto
                ? () => showDialog<void>(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.72),
                      builder: (_) => UserAvatarViewerDialog(user: user),
                    )
                : () => Navigator.pushNamed(context, AppRoutes.profileDetails),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: activeColor.withValues(alpha: 0.18),
                backgroundImage: hasPhoto ? NetworkImage(user.photoUrl!) : null,
                child: !hasPhoto
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: typo.bodyLarge.copyWith(
                          color: activeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profileDetails),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  style: typo.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.userName}',
                  style: typo.bodySmall.copyWith(
                    color: textColor.withValues(alpha: 0.55),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
