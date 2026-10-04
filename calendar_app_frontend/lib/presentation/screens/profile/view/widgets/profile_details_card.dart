import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
    if (MediaQuery.sizeOf(context).width < 700) {
      final cs = Theme.of(context).colorScheme;
      Widget row(IconData icon, String title, VoidCallback onTap,
              {String? detail, String? count, bool copy = false}) =>
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: Icon(icon, color: cs.primary, size: 22),
            title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
            subtitle: detail == null
                ? null
                : Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (count != null) ...[
                Text(count,
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8)
              ],
              Icon(copy ? Icons.copy_outlined : Icons.chevron_right,
                  size: 18, color: cs.onSurfaceVariant),
            ]),
            onTap: onTap,
          );
      return Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          row(Icons.mail_outline, l10n.email, onCopyEmail,
              detail: email, copy: true),
          const Divider(height: 1, indent: 50),
          row(Icons.groups_outlined, l10n.teams, onTapTeams,
              count: '$groupsCount'),
          row(Icons.calendar_month_outlined, l10n.calendars, onTapCalendars,
              count: '$calendarsCount'),
          row(Icons.notifications_outlined, l10n.notifications,
              onTapNotifications,
              count: '$notificationsCount'),
          const Divider(height: 1, indent: 50),
          ExpansionTile(
            leading: Icon(Icons.badge_outlined,
                color: cs.onSurfaceVariant, size: 22),
            title: Text(
                l10n.localeName.startsWith('es')
                    ? 'Datos de la cuenta'
                    : 'Account details',
                style: Theme.of(context).textTheme.bodyMedium),
            children: [
              row(Icons.alternate_email, l10n.username, onTapUsername,
                  detail: username),
              row(Icons.fingerprint, l10n.userId, onCopyId,
                  detail: userId, copy: true),
            ],
          ),
        ]),
      );
    }
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bg = ThemeColors.cardBg(context);
    final onBg = ThemeColors.textPrimary(context);
    final shadow = ThemeColors.cardShadow(context);
    final divider = cs.outlineVariant.withValues(alpha: 0.25);

    Widget tile({
      required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
      Color? accent,
    }) {
      final ic = accent ?? cs.secondary;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: ic.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: ic, size: 20),
        ),
        title: Text(
          title,
          style: t.bodyMedium.copyWith(
            color: onBg.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: t.bodySmall.copyWith(
                  color: onBg.withValues(alpha: 0.75),
                  height: 1.25,
                ),
              ),
        trailing: trailing == null
            ? null
            : IconTheme(
                data: IconThemeData(
                    color: onBg.withValues(alpha: 0.55), size: 18),
                child: trailing,
              ),
        onTap: onTap,
      );
    }

    Widget dividerLine() => Divider(height: 0, color: divider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.2), width: 1),
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
          dividerLine(),
          tile(
            icon: Icons.badge_rounded,
            title: l10n.username,
            subtitle: username,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapUsername,
          ),
          dividerLine(),
          tile(
            icon: Icons.fingerprint_rounded,
            title: l10n.userId,
            subtitle: userId,
            trailing: const Icon(Icons.copy_rounded),
            onTap: onCopyId,
          ),
          dividerLine(),
          tile(
            icon: Icons.groups_3_rounded,
            title: l10n.teams,
            subtitle: l10n.teamCount(groupsCount),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapTeams,
          ),
          dividerLine(),
          tile(
            icon: Icons.calendar_month_rounded,
            title: l10n.calendars,
            subtitle: l10n.calendarCount(calendarsCount),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapCalendars,
          ),
          dividerLine(),
          tile(
            icon: Icons.notifications_active_rounded,
            title: l10n.notifications,
            subtitle: '$notificationsCount',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTapNotifications,
            accent: cs.tertiary, // small visual hint difference
          ),
        ],
      ),
    );
  }
}
