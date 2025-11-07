// lib/c-frontend/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/socket_notification_listener.dart';
import 'package:hexora/c-frontend/a-home-section/widgets/see_all_groups_button.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_screen/group_list_section.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/motivational_phrase/motivation_banner.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/e-drawer-style-menu/main_scaffold.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// ⬇️ Section widgets (local, smaller files)
import 'widgets/app_bar_user_title.dart';
import 'widgets/greeting_card.dart';
import 'widgets/section_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _lastUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthService>().currentUser;

    if (user != null && user != _lastUser) {
      _lastUser = user;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userDomain = context.read<UserDomain>();
        final groupDomain = context.read<GroupDomain>();

        // seed domains with the new user
        userDomain.setCurrentUser(user);
        groupDomain.setCurrentUser(user);

        // sockets for notifications
        initializeNotificationSocket(user.id);

        // refresh groups stream
        await groupDomain.refreshGroupsForCurrentUser(userDomain);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = context.watch<AuthService>().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainScaffold(
      title: '',
      titleWidget: AppBarUserTitle(user: user),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: loc.settings,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: GreetingCard(user: user)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: SectionHeader(title: loc.motivationSectionTitle),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: MotivationBanner(dailyRotate: true),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Groups header (no info widget) ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: loc.groupSectionTitle),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // ── "See all" right-aligned below header ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Spacer(),
                  SeeAllGroupsButton(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Groups preview (only 5) ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: GroupListSection(
                maxItems: 5, // preview only
                fullPage: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
