import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class GroupDashboardLeftNav extends StatelessWidget {
  final Group group;
  final User? user;
  final bool isDark;
  final List<(String, IconData, String)> sections;
  final void Function(String anchor)? onSectionTap;
  final String? selectedAnchor;

  const GroupDashboardLeftNav({
    super.key,
    required this.group,
    required this.user,
    required this.isDark,
    required this.sections,
    this.onSectionTap,
    this.selectedAnchor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GroupCard(group: group, isDark: isDark),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Column(
                        children: [
                          for (final s in sections) ...[
                            _NavRow(
                              label: s.$1,
                              icon: s.$2,
                              isDark: isDark,
                              onTap: onSectionTap == null
                                  ? null
                                  : () => onSectionTap!(s.$3),
                              isSelected: selectedAnchor == s.$3,
                            ),
                            if (s != sections.last)
                              Divider(
                                height: 1,
                                thickness: 0.6,
                                color: (isDark
                                        ? AppDarkColors.textSecondary
                                        : AppColors.textSecondary)
                                    .withOpacity(0.25),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (user != null) _UserCard(user: user!, isDark: isDark),
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

class _NavRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isSelected;

  const _NavRow({
    required this.label,
    required this.icon,
    required this.isDark,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected
        ? (isDark ? AppDarkColors.primary : AppColors.primary)
        : (isDark ? AppDarkColors.textPrimary : AppColors.textPrimary);
    final bg = isSelected ? fg.withOpacity(0.10) : Colors.transparent;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: bg,
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final bool isDark;
  const _GroupCard({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: bg.withOpacity(0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: group.photoUrl != null && group.photoUrl!.isNotEmpty
                    ? Image.network(group.photoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: onSurface.withOpacity(0.08),
                        child: Icon(Icons.group, color: onSurface, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              group.name,
              style: typo.bodyMedium.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              group.description,
              style: typo.bodySmall.copyWith(
                color: onSurface.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: bg.withOpacity(0.92),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: onSurface.withOpacity(0.12),
              backgroundImage:
                  (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                      ? NetworkImage(user.photoUrl!)
                      : null,
              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: typo.bodyMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: typo.bodyMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user.userName}',
                    style: typo.caption.copyWith(
                      color: onSurface.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
