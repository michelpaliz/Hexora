// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/group_dashboard_body_member.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dashboard_state.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/business_hours/group_business_hours_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/role_info/profile_role_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/upcoming_events/group_upcoming_events.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../dashboard/controller/group_dashboard_sections.dart';

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
    final tileTitle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        );
    final tileSub = t.bodySmall;
    final tileBg = ThemeColors.listTileBg(context);

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
                onTap: () =>
                    context.read<GroupDashboardState>().openSection('profile'),
              ),
              const SizedBox(height: 20),
              SectionHeader(
                  title: l.sectionBusinessHours, textStyle: sectionTitle),
              GroupBusinessHoursCard(
                group: group,
                description: l.businessHoursMemberSubtitle,
              ),
              const SizedBox(height: 20),
              SectionHeader(title: l.calendarTitle, textStyle: sectionTitle),
              Card(
                color: tileBg,
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: Text(l.calendarTitle, style: tileTitle),
                  subtitle: Text(
                    group.hasCalendar ? l.goToCalendar : l.noCalendarWarning,
                    style: tileSub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => context
                      .read<GroupDashboardState>()
                      .openSection(Sections.calendar),
                ),
              ),
              if (!group.hasCalendar) ...[
                const SizedBox(height: 8),
                Card(
                  color: cs.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l.noCalendarWarning,
                      style: t.bodyMedium.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SectionHeader(
                title: l.sectionEvents,
                subtitle: l.pendingEventsSectionTitle,
                textStyle: sectionTitle,
              ),
              GroupUpcomingEventsCard(
                groupId: group.id,
                role: role,
                currentUserId: user.id,
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
