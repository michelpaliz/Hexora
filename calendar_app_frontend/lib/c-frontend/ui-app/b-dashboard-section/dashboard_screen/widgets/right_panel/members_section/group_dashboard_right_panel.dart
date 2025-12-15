import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/right_panel_cta_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/right_panel_members_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/calendar_section/right_panel_calendar_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/services_section/right_panel_services_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/services_section/right_panel_insights_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/workers_section/right_panel_workers_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/undone_section/right_panel_undone_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/invoices_section/right_panel_invoices_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/profile_section/right_panel_profile_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/notifications_section/right_panel_notifications_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/edit_group_section/right_panel_edit_group_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/settings_section/right_panel_settings_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: bg.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kElevationToShadow[2],
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
