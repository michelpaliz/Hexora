import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/navigation/main_scaffold.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/avatars/user_avatar.dart';
import 'package:hexora/presentation/screens/settings/widgets/nav_tile.dart';
import 'package:hexora/presentation/screens/settings/widgets/section_card.dart';
import 'package:hexora/presentation/screens/home/widgets/section_header.dart';
import 'package:provider/provider.dart';

import 'package:hexora/presentation/routes/app_routes.dart';
import 'widgets/profile_header_section.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final cs = theme.colorScheme;

    final user = context.watch<UserDomain>().user;
    if (user == null) {
      return MainScaffold(
        showAppBar: false,
        body: Center(
          child: Text(loc.noUserLoaded, style: textTheme.bodyMedium),
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final isEs = loc.localeName.startsWith('es');

    final groupsCount = user.groupIds.length;
    final calendarsCount = user.sharedCalendars.length;
    final notificationsCount =
        context.watch<NotificationDomain>().notifications.length;

    void copyToClipboard(String text, String toast) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toast, style: textTheme.bodyMedium)),
      );
    }

    void goToSettings() {
      Navigator.of(context).pushNamed(AppRoutes.settings);
    }

    void goToGroups() => Navigator.of(context).pushNamed(AppRoutes.showGroups);
    void goToCalendars() => Navigator.of(context).pushNamed(AppRoutes.agenda);
    void goToNotifications() => Navigator.of(context)
        .pushNamed(AppRoutes.showNotifications, arguments: user);

    // ── Shared section builders ──────────────────────────────────
    Widget personalInfoSection() => SectionCard(
          child: Column(
            children: [
              NavTile(
                leading: Icon(Icons.alternate_email_rounded,
                    size: 18, color: cs.primary),
                iconBgColor: cs.primary.withValues(alpha: 0.12),
                title: loc.email,
                subtitle: user.email,
                onTap: () =>
                    copyToClipboard(user.email, loc.copiedToClipboard),
              ),
              _divider(cs),
              NavTile(
                leading:
                    Icon(Icons.badge_rounded, size: 18, color: cs.primary),
                iconBgColor: cs.primary.withValues(alpha: 0.12),
                title: loc.username,
                subtitle: '@${user.userName}',
                onTap: goToSettings,
              ),
              _divider(cs),
              NavTile(
                leading: Icon(Icons.fingerprint_rounded,
                    size: 18, color: cs.primary),
                iconBgColor: cs.primary.withValues(alpha: 0.12),
                title: loc.userId,
                subtitle: user.id,
                onTap: () =>
                    copyToClipboard(user.id, loc.copiedToClipboard),
              ),
            ],
          ),
        );

    Widget activitySection() => SectionCard(
          child: Column(
            children: [
              NavTile(
                leading: Icon(Icons.groups_3_rounded,
                    size: 18, color: cs.primary),
                iconBgColor: cs.primary.withValues(alpha: 0.12),
                title: loc.teams,
                subtitle: loc.teamCount(groupsCount),
                onTap: goToGroups,
              ),
              _divider(cs),
              NavTile(
                leading: Icon(Icons.calendar_month_rounded,
                    size: 18, color: cs.primary),
                iconBgColor: cs.primary.withValues(alpha: 0.12),
                title: loc.calendars,
                subtitle: loc.calendarCount(calendarsCount),
                onTap: goToCalendars,
              ),
              _divider(cs),
              NavTile(
                leading: Icon(Icons.notifications_active_rounded,
                    size: 18, color: cs.primary),
                iconBgColor: cs.primary.withValues(alpha: 0.12),
                title: loc.notifications,
                subtitle: '$notificationsCount',
                onTap: goToNotifications,
              ),
            ],
          ),
        );

    final personalInfoTitle =
        isEs ? 'Información personal' : 'Personal information';
    final activityTitle =
        isEs ? 'Actividad y accesos' : 'Activity & access';

    return MainScaffold(
      showAppBar: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // ── Mobile / tablet (<1024) ──────────────────────────────
          if (width < 1024) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeaderSection(
                    headerColor: headerColor,
                    onEdit: goToSettings,
                    user: user,
                    onCopyEmail: () =>
                        copyToClipboard(user.email, loc.copiedToClipboard),
                    groupsCount: groupsCount,
                    calendarsCount: calendarsCount,
                    notificationsCount: notificationsCount,
                    onTapQuickGroups: goToGroups,
                    onTapQuickCalendars: goToCalendars,
                    onTapQuickNotifications: goToNotifications,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: personalInfoTitle,
                      markerHeight: 24,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: personalInfoSection(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: activityTitle,
                      markerHeight: 24,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: activitySection(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
                const SliverToBoxAdapter(
                  child: SafeArea(top: false, child: SizedBox(height: 8)),
                ),
              ],
            );
          }

          // ── Desktop (>=1024) ─────────────────────────────────────
          final t = AppTypography.of(context);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Compact profile summary ───────────────────
                      SectionCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              UserAvatar(
                                user: user,
                                fetchReadSas: (_) async => null,
                                radius: 30,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: t.titleLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${user.userName}',
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                icon: Icons.groups_rounded,
                                label: isEs ? 'Grupos' : 'Groups',
                                count: '$groupsCount',
                                onTap: goToGroups,
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.calendar_month_rounded,
                                label: isEs ? 'Calendarios' : 'Calendars',
                                count: '$calendarsCount',
                                onTap: goToCalendars,
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.notifications_rounded,
                                label: isEs ? 'Avisos' : 'Alerts',
                                count: '$notificationsCount',
                                onTap: goToNotifications,
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: goToSettings,
                                icon: const Icon(Icons.settings_outlined,
                                    size: 16),
                                label: Text(isEs
                                    ? 'Configuración'
                                    : 'Settings'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: cs.primary,
                                  side: BorderSide(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Two-column layout ─────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: personal info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: personalInfoTitle,
                                  markerHeight: 28,
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                ),
                                personalInfoSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right: activity & access + preferences
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: activityTitle,
                                  markerHeight: 28,
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                ),
                                activitySection(),
                                const SizedBox(height: 20),
                                SectionHeader(
                                  title: isEs
                                      ? 'Preferencias'
                                      : 'Preferences',
                                  markerHeight: 28,
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                ),
                                SectionCard(
                                  child: _ThemeCard(isEs: isEs),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _divider(ColorScheme cs) => Divider(
        height: 0,
        indent: 63,
        color: cs.outlineVariant.withValues(alpha: 0.4),
      );
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(height: 4),
            Text(
              count,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.isEs});

  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Consumer<ThemeModeProvider>(
        builder: (context, provider, _) => DropdownButtonFormField<ThemeMode>(
          key: ValueKey(provider.mode),
          initialValue: provider.mode,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.palette_outlined),
            labelText: isEs ? 'Tema de la app' : 'App theme',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(isEs
                  ? 'Usar tema del dispositivo'
                  : 'Use device theme'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(isEs ? 'Claro' : 'Light'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(isEs ? 'Oscuro' : 'Dark'),
            ),
          ],
          onChanged: provider.isLoaded
              ? (mode) {
                  if (mode != null) provider.setMode(mode);
                }
              : null,
        ),
      ),
    );
  }
}
