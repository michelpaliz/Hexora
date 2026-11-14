// lib/presentation/screens/workspace/dashboard/overview/group_dashboard_body_member.dart
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_state.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/group_header_view.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/overview/widgets/home_calendar_preview.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_hours/group_business_hours_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/presentation/screens/workspace/sections/role_info/profile_role_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/undone_events/group_undone_events_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/upcoming_events/group_upcoming_events.dart';
import 'package:hexora/presentation/screens/workspace/sections/weather/work_conditions_card.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../navigation/dashboard_sections.dart';

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

  Widget _buildMobile(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final es = l.localeName.startsWith('es');
    final dashboard = context.read<GroupDashboardState>();

    Widget action(IconData icon, String label, String section) => Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => dashboard.openSection(section),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 19, color: cs.primary),
                  ),
                  Row(children: [
                    Expanded(
                      child: Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: cs.onSurfaceVariant),
                  ]),
                ],
              ),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      children: [
        Text(
          es ? 'Tu jornada' : 'Your workday',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          es
              ? 'Todo lo importante en un solo lugar'
              : 'Everything important in one place',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        GroupHeaderView(group: group, allowEditing: false),
        const SizedBox(height: 16),
        HomeCalendarPreview(
          groupId: group.id,
          role: role,
          currentUserId: user.id,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            action(Icons.calendar_month_outlined, l.calendarTitle,
                Sections.calendar),
            action(Icons.view_agenda_outlined, l.agenda, Sections.agenda),
            action(
                Icons.forum_outlined,
                es ? 'Chat de la empresa' : 'Business chat',
                Sections.businessChat),
            action(Icons.person_outline_rounded,
                es ? 'Mi perfil' : 'My profile', Sections.profile),
          ],
        ),
        const SizedBox(height: 12),
        WorkConditionsCard(groupId: group.id),
        const SizedBox(height: 12),
        GroupUndoneEventsSection(group: group, user: user, role: role),
        const SizedBox(height: 12),
        // The selected-day agenda is provided by HomeCalendarPreview above.
        const SizedBox(height: 12),
        GroupBusinessHoursCard(
          group: group,
          description: l.businessHoursMemberSubtitle,
        ),
      ],
    );
  }

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

    if (MediaQuery.sizeOf(context).width < 700) {
      return _buildMobile(context);
    }

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
              WorkConditionsCard(groupId: group.id),
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
              Card(
                color: tileBg,
                child: ListTile(
                  leading: const Icon(Icons.view_agenda_outlined),
                  title: Text(l.agenda, style: tileTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context
                      .read<GroupDashboardState>()
                      .openSection(Sections.agenda),
                ),
              ),
              Card(
                color: tileBg,
                child: ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(
                      l.localeName.startsWith('es')
                          ? 'Chat de la empresa'
                          : 'Business chat',
                      style: tileTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context
                      .read<GroupDashboardState>()
                      .openSection(Sections.businessChat),
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
