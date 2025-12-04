// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/group_dashboard_body_member.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
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
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        );

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
                title: l.sectionEvents,
                subtitle: l.pendingEventsSectionTitle,
                textStyle: sectionTitle,
              ),
              GroupUpcomingEventsCard(
                groupId: group.id,
                // cardColor: sectionCardColor,
              ),
              const SizedBox(height: 12),
              GroupUndoneEventsSection(
                group: group,
                user: user,
                role: role,
                // cardColor: sectionCardColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
