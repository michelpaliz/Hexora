// lib/c-frontend/b-calendar-section/screens/profile/profile_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'widgets/profile_details_card.dart';
import 'widgets/profile_header_section.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final user = context.watch<UserDomain>().user;
    if (user == null) {
      return MainScaffold(
        showAppBar: false,
        body: Center(
          child: Text(
            loc.noUserLoaded,
            style: textTheme.bodyMedium,
          ),
        ),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? AppDarkColors.primary : AppColors.primary;

    final groupsCount = user.groupIds.length;
    final calendarsCount = user.sharedCalendars.length;
    final notificationsCount = user.notifications.length;

    void copyToClipboard(String text, String toast) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toast, style: textTheme.bodyMedium)),
      );
    }

    void _goToProfileEdit() =>
        Navigator.of(context).pushNamed(AppRoutes.profile);
    void _goToGroups() => Navigator.of(context).pushNamed(AppRoutes.showGroups);
    void _goToCalendars() => Navigator.of(context).pushNamed(AppRoutes.agenda);
    void _goToNotifications() => Navigator.of(context)
        .pushNamed(AppRoutes.showNotifications, arguments: user);

    return MainScaffold(
      showAppBar: false,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: ProfileHeaderSection(
              headerColor: headerColor,
              user: user,
              onCopyEmail: () =>
                  copyToClipboard(user.email, loc.copiedToClipboard),
              groupsCount: groupsCount,
              calendarsCount: calendarsCount,
              notificationsCount: notificationsCount,
              onTapQuickGroups: _goToGroups,
              onTapQuickCalendars: _goToCalendars,
              onTapQuickNotifications: _goToNotifications,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Details card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProfileDetailsCard(
                email: user.email,
                username: '@${user.userName}',
                userId: user.id,
                groupsCount: groupsCount,
                calendarsCount: calendarsCount,
                notificationsCount: notificationsCount,
                onCopyEmail: () =>
                    copyToClipboard(user.email, loc.copiedToClipboard),
                onCopyId: () => copyToClipboard(user.id, loc.copiedToClipboard),
                onTapUsername: _goToProfileEdit,
                onTapTeams: _goToGroups,
                onTapCalendars: _goToCalendars,
                onTapNotifications: _goToNotifications,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(
            child: SafeArea(top: false, child: SizedBox(height: 8)),
          ),
        ],
      ),
    );
  }
}
