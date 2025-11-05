// lib/c-frontend/b-calendar-section/screens/profile/widgets/profile_header_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
class ProfileHeaderSection extends StatelessWidget {
  final Color headerColor;
  final User user;

  // optional (not shown if null)
  final VoidCallback? onEdit;

  final VoidCallback onCopyEmail;
  final int groupsCount, calendarsCount, notificationsCount;
  final VoidCallback onTapQuickGroups,
      onTapQuickCalendars,
      onTapQuickNotifications;

  // sizing knobs
  final EdgeInsetsGeometry padding; // container padding
  final double bottomRadius;
  final double avatarRadius;
  final double topGap; // extra headroom inside the SafeArea

  const ProfileHeaderSection({
    super.key,
    required this.headerColor,
    required this.user,
    required this.onCopyEmail,
    required this.groupsCount,
    required this.calendarsCount,
    required this.notificationsCount,
    required this.onTapQuickGroups,
    required this.onTapQuickCalendars,
    required this.onTapQuickNotifications,
    this.onEdit,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.bottomRadius = 20,
    this.avatarRadius = 36,
    this.topGap = 25,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);

    // Text/icon color that contrasts with the header background
    final onHeader = ThemeColors.contrastOn(headerColor);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        minimum: EdgeInsets.only(top: topGap),
        child: Column(
          children: [
            if (onEdit != null) ...[
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_rounded, color: onHeader),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // avatar
            UserAvatar(
              user: user,
              fetchReadSas: (_) async => null,
              radius: avatarRadius,
            ),
            const SizedBox(height: 10),

            // name & username
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: t.displayMedium.copyWith(
                color: onHeader,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.userName}',
              style: t.bodyMedium.copyWith(
                color: onHeader.withOpacity(.9),
              ),
            ),
            const SizedBox(height: 10),

            // quick actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleAction(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  color: onHeader,
                  onTap: onCopyEmail,
                ),
                const SizedBox(width: 16),
                _CircleAction(
                  icon: Icons.groups_rounded,
                  label: '$groupsCount',
                  color: onHeader,
                  onTap: onTapQuickGroups,
                ),
                const SizedBox(width: 16),
                _CircleAction(
                  icon: Icons.event_rounded,
                  label: '$calendarsCount',
                  color: onHeader,
                  onTap: onTapQuickCalendars,
                ),
                const SizedBox(width: 16),
                _CircleAction(
                  icon: Icons.notifications_rounded,
                  label: '$notificationsCount',
                  color: onHeader,
                  onTap: onTapQuickNotifications,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);

    return Column(
      children: [
        Material(
          color: color.withOpacity(.16), // subtle, auto-contrasts the header
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: t.caption.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
