// lib/c-frontend/ui-app/b-dashboard-section/settings/group_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.groupSettingsTitle, style: t.titleLarge),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupHeaderView(group: group),
          const SizedBox(height: 20),

          // Example settings tiles (add more later)
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.groupInfo),
              subtitle: Text(l.groupInfoSubtitle),
              onTap: () {
                // Push deeper in settings if needed.
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: Text(l.notifications),
              subtitle: Text(l.notificationsSubtitle),
              onTap: () {
                // Open notifications configuration.
              },
            ),
          ),

          const SizedBox(height: 96), // breathing room for bottom buttons
        ],
      ),

      // Primary actions live here
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 22),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: Text(l.goToCalendar),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.groupCalendar,
                      arguments: group,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(l.addEvent),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    side: BorderSide(
                      color: cs.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  onPressed: () {
                    // ✅ Use your existing route for creating/adding an event
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
        ),
      ),
    );
  }
}
