import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ProfileDetailsCard extends StatelessWidget {
  final String email, username, userId;
  final int groupsCount, calendarsCount, notificationsCount;
  final VoidCallback onCopyEmail,
      onCopyId,
      onTapUsername,
      onTapTeams,
      onTapCalendars,
      onTapNotifications;

  const ProfileDetailsCard({
    super.key,
    required this.email,
    required this.username,
    required this.userId,
    required this.groupsCount,
    required this.calendarsCount,
    required this.notificationsCount,
    required this.onCopyEmail,
    required this.onCopyId,
    required this.onTapUsername,
    required this.onTapTeams,
    required this.onTapCalendars,
    required this.onTapNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final bg = ThemeColors.getCardBackgroundColor(context).withOpacity(0.98);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVar = theme.colorScheme.onSurfaceVariant;

    Widget tile({
      required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: onSurfaceVar.withOpacity(.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: onSurface),
        ),
        title: Text(
          title,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: t.bodySmall?.copyWith(color: onSurfaceVar),
              ),
        trailing: trailing == null
            ? null
            : IconTheme(
                data: IconThemeData(color: onSurfaceVar),
                child: trailing,
              ),
        onTap: onTap,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.getCardShadowColor(context),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          tile(
            icon: Icons.alternate_email_rounded,
            title: l10n.email,
            subtitle: email,
            trailing: const Icon(Icons.copy_rounded),
            onTap: onCopyEmail,
          ),
          const Divider(height: 0),
          tile(
            icon: Icons.badge_rounded,
            title: l10n.username,
            subtitle: username,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapUsername,
          ),
          const Divider(height: 0),
          tile(
            icon: Icons.fingerprint_rounded,
            title: l10n.userId,
            subtitle: userId,
            trailing: const Icon(Icons.copy_rounded),
            onTap: onCopyId,
          ),
          const Divider(height: 0),
          tile(
            icon: Icons.groups_3_rounded,
            title: l10n.teams,
            subtitle: l10n.teamCount(groupsCount),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapTeams,
          ),
          const Divider(height: 0),
          tile(
            icon: Icons.calendar_month_rounded,
            title: l10n.calendars,
            subtitle: l10n.calendarCount(calendarsCount),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapCalendars,
          ),
          const Divider(height: 0),
          tile(
            icon: Icons.notifications_active_rounded,
            title: l10n.notifications,
            subtitle: '$notificationsCount',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapNotifications,
          ),
        ],
      ),
    );
  }
}
