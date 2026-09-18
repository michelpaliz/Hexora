import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/calendar/right_panel_calendar_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/edit_group/right_panel_edit_group_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/invoices/right_panel_invoices_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/widgets/right_panel_cta_card.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/members/right_panel_members_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/right_panel_notifications_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/profile/right_panel_profile_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/insights/right_panel_insights_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/services/right_panel_services_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/right_panel_settings_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/pending_events/right_panel_undone_inline.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/right_panel_workers_inline.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat_fab.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupDashboardRightPanel extends StatelessWidget {
  final String activeAnchor;
  final MembersCount? counts;
  final Group group;
  final User? user;
  final GroupRole? role;
  final Future<String?> Function(String blobName)? fetchReadSas;
  final List<User>? usersInGroup;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSettings;

  const GroupDashboardRightPanel({
    super.key,
    required this.activeAnchor,
    required this.counts,
    required this.group,
    required this.user,
    required this.role,
    required this.fetchReadSas,
    required this.usersInGroup,
    required this.onOpenCalendar,
    required this.onOpenNotifications,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDarkColors.surface : AppColors.surface;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    Widget content;
    switch (activeAnchor) {
      case 'members':
        content = MembersInlinePanel(
          group: group,
          onSurface: onSurface,
        );
        break;
      case 'services':
        content = ServicesClientsInlinePanel(
          group: group,
        );
        break;
      case 'invoices':
        if (role != null && role != GroupRole.member) {
          content = InvoicesInlinePanel(group: group);
        } else {
          content = CtaCard(
            title: loc.invoicesNavLabel,
            subtitle: loc.invoicesNavSubtitle,
            icon: Icons.receipt_long_outlined,
            onSurface: onSurface,
            typo: typo,
            onPressed: () {},
          );
        }
        break;
      case 'insights':
        content = InsightsInlinePanel(group: group);
        break;
      case 'chat':
        content = InsightsChatPanel(groupId: group.id);
        break;
      case 'workers':
        content = WorkersInlinePanel(group: group);
        break;
      case 'undone':
        if (user != null && role != null) {
          content = UndoneEventsInlinePanel(
            group: group,
            user: user!,
            role: role!,
          );
        } else {
          content = CtaCard(
            title: loc.pendingEventsSectionTitle,
            subtitle: group.name,
            icon: Icons.pending_actions_outlined,
            onSurface: onSurface,
            typo: typo,
            onPressed: () {},
          );
        }
        break;
      case 'profile':
        if (user != null && role != null && fetchReadSas != null) {
          content = ProfileInlinePanel(
            group: group,
            user: user!,
            role: role!,
            fetchReadSas: fetchReadSas!,
          );
        } else {
          content = CtaCard(
            title: loc.groupSectionTitle,
            subtitle: group.name,
            icon: Icons.person,
            onSurface: onSurface,
            typo: typo,
            onPressed: () {},
          );
        }
        break;
      case 'editGroup':
        content = EditGroupInlinePanel(
          group: group,
          users: usersInGroup ?? const [],
        );
        break;

      case 'calendar':
        content = CalendarInlinePanel(group: group);
        break;

      case 'notifications':
        content = NotificationsInlinePanel(group: group);
        break;

      case 'settings':
        content = SettingsInlinePanel(group: group);
        break;

      default:
        content = CtaCard(
          title: loc.groupSectionTitle,
          subtitle: group.name,
          icon: Icons.dashboard_rounded,
          onSurface: onSurface,
          typo: typo,
          onPressed: () {},
        );
    }

    if (activeAnchor == 'workers' || activeAnchor == 'services') {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kElevationToShadow[2],
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
