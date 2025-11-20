// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/group_dashboard_body_member.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/role_info_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/role_info/profile_role_card.dart';
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
    final cs = Theme.of(context).colorScheme;
    final sectionTitle = t.bodyLarge.copyWith(fontWeight: FontWeight.w800);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Group header (tappable to edit if allowed by your view)
              GroupHeaderView(group: group),
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
              SectionHeader(title: l.sectionUpcoming, textStyle: sectionTitle),
              GroupUpcomingEventsCard(groupId: group.id),
            ],
          ),
        ),
        // SafeArea(
        //   minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        //   child: SizedBox(
        //     height: 56,
        //     child: FilledButton.icon(
        //       icon: const Icon(Icons.calendar_month_rounded),
        //       label: Text(l.goToCalendar),
        //       onPressed: () => Navigator.pushNamed(
        //         context,
        //         AppRoutes.groupCalendar,
        //         arguments: group,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
