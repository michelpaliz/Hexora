import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../widgets/home_section_nav.dart';

class HomeLeftNav extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final navButtons = [
      (label: loc.home, icon: Icons.home_rounded, route: AppRoutes.homePage),
      (
        label: loc.agenda,
        icon: Icons.event_note_rounded,
        route: AppRoutes.agenda
      ),
      (
        label: loc.notifications,
        icon: Icons.notifications_none_rounded,
        route: AppRoutes.showNotifications
      ),
      (
        label: loc.settings,
        icon: Icons.settings_outlined,
        route: AppRoutes.settings
      ),
    ];

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _UserCard(user: user, isDark: isDark),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          for (final btn in navButtons) ...[
                            _NavButton(
                              label: btn.label,
                              icon: btn.icon,
                              route: btn.route,
                              isDark: isDark,
                              isSelected: activeNavRoute == btn.route,
                              onPressed: onNavSelected == null
                                  ? null
                                  : () => onNavSelected!(btn.route),
                            ),
                            if (btn != navButtons.last)
                              Divider(
                                height: 1,
                                thickness: 0.6,
                                color: (isDark
                                        ? AppDarkColors.textSecondary
                                        : AppColors.textSecondary)
                                    .withOpacity(0.25),
                              ),
                          ],
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    isDark
                                        ? AppDarkColors.primary
                                        : AppColors.primary,
                                    (isDark
                                            ? AppDarkColors.primary
                                            : AppColors.primary)
                                        .withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? AppDarkColors.primary
                                            : AppColors.primary)
                                        .withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.group_add_rounded,
                                    size: 18),
                                label: Text(
                                  loc.groupSectionTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(46),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: onCreateGroupInline ??
                                    () => Navigator.pushNamed(
                                        context, AppRoutes.createGroupData),
                                clipBehavior: Clip.antiAlias,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                borderRadius: BorderRadius.circular(16)),
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

class _UserCard extends StatelessWidget {
  final User user;
  final bool isDark;
  const _UserCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: bg.withOpacity(0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: onSurface.withOpacity(0.12),
              backgroundImage:
                  (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                      ? NetworkImage(user.photoUrl!)
                      : null,
              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: typo.titleLarge.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: typo.bodyMedium.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.userName}',
              style: typo.bodyMedium.copyWith(
                color: onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  final bool isDark;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.route,
    required this.isDark,
    this.isSelected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final inactiveColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final selected = isSelected ||
        (onPressed == null && ModalRoute.of(context)?.settings.name == route);

    return InkWell(
      onTap: onPressed ??
          () {
            if (selected) return;
            Navigator.pushReplacementNamed(context, route);
          },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: selected ? activeColor.withOpacity(0.08) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: selected ? activeColor : inactiveColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? activeColor : inactiveColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
