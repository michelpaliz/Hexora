// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/group_dashboard_body_member.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/role_info_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/business_hours/group_business_hours_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/role_info/profile_role_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/upcoming_events/group_upcoming_events.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupDashboardBodyMember extends StatelessWidget {
  const GroupDashboardBodyMember({
    super.key,
    required this.group,
    required this.user,
    required this.role,
    required this.fetchReadSas,
  });

  final Group group;
  final User user;
  final GroupRole role;
  final Future<String?> Function(String blobName) fetchReadSas;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final sectionTitle = t.bodyLarge.copyWith(fontWeight: FontWeight.w800);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Group header (read-only for members)
              GroupHeaderView(
                group: group,
                allowEditing: false,
              ),
              const SizedBox(height: 16),
              // Role card (greeting + capabilities)
              ProfileRoleCard(
                user: user,
                role: role,
                fetchReadSas: fetchReadSas,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RoleInfoScreen(
                      group: group,
                      user: user,
                      role: role,
                      fetchReadSas: fetchReadSas,
                    ),
                  ));
                },
              ),
              const SizedBox(height: 20),
              SectionHeader(
                  title: l.sectionBusinessHours, textStyle: sectionTitle),
              GroupBusinessHoursCard(
                group: group,
                description: l.businessHoursMemberSubtitle,
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: l.groupNotificationsSectionTitle,
                textStyle: sectionTitle,
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(
                    l.groupNotificationsSectionTitle,
                    style: t.accentText.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      Text(l.groupNotificationsSubtitle, style: t.bodySmall),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.groupNotifications,
                    arguments: group,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SectionHeader(title: l.sectionUpcoming, textStyle: sectionTitle),
              GroupUpcomingEventsCard(groupId: group.id),
              const SizedBox(height: 20),
              SectionHeader(
                title: l.pendingEventsSectionTitle,
                textStyle: sectionTitle,
              ),
              GroupUndoneEventsSection(
                group: group,
                user: user,
                role: role,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
