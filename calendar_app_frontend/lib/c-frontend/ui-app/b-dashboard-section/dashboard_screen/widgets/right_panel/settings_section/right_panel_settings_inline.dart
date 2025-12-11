import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SettingsInlinePanel extends StatelessWidget {
  final Group group;
  const SettingsInlinePanel({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final onSurface = Theme.of(context).brightness == Brightness.dark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.groupSettingsTitle,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: GroupHeaderView(group: group, onEditGroup: () {}),
          ),
          const SizedBox(height: 12),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.groupInfo,
                      style:
                          t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text(l.groupInfoSubtitle,
                      style: t.bodySmall
                          .copyWith(color: onSurface.withOpacity(0.7))),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: Text(l.notifications,
                      style:
                          t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text(l.notificationsSubtitle,
                      style: t.bodySmall
                          .copyWith(color: onSurface.withOpacity(0.7))),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.groupNotifications,
                      arguments: group,
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(l.goToCalendar),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.groupCalendar,
                      arguments: group,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.addEvent),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addEvent,
                      arguments: group,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
