import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/domain/socket_notification_listener.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/a-home-section/home_page/widgets/home_sliver_content.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../widgets/app_bar_user_title.dart';
import '../widgets/home_section_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _lastUser;
  final _scrollController = ScrollController();

  final _summaryKey = GlobalKey();
  final _phraseKey = GlobalKey();
  final _groupsKey = GlobalKey();
  String _activeSection = 'summary';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthService>().currentUser;

    if (user != null && user != _lastUser) {
      _lastUser = user;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userDomain = context.read<UserDomain>();
        final groupDomain = context.read<GroupDomain>();
        final notificationDomain = context.read<NotificationDomain>();

        // seed domains with the new user
        userDomain.setCurrentUser(user);
        groupDomain.setCurrentUser(user);

        // sockets for notifications
        initializeNotificationSocket(
          user.id,
          notificationDomain: notificationDomain,
        );

        // refresh groups stream
        await groupDomain.refreshGroupsForCurrentUser(userDomain);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = context.watch<AuthService>().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bottomSafePadding = MediaQuery.of(context).padding.bottom + 16;
    final isWide = MediaQuery.of(context).size.width >= 900;

    final sectionItems = [
      HomeSectionNavItem(id: 'summary', label: loc.home, key: _summaryKey),
      HomeSectionNavItem(
          id: 'phrase', label: loc.motivationSectionTitle, key: _phraseKey),
      HomeSectionNavItem(
          id: 'groups', label: loc.groupSectionTitle, key: _groupsKey),
    ];

    void handleSectionTap(String id) {
      setState(() => _activeSection = id);
      switch (id) {
        case 'phrase':
          _scrollTo(_phraseKey);
          break;
        case 'groups':
          _scrollTo(_groupsKey);
          break;
        default:
          _scrollTo(_summaryKey);
      }
    }

    return MainScaffold(
      title: '',
      titleWidget: isWide ? null : AppBarUserTitle(user: user),
      actions: isWide
          ? null
          : [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: loc.settings,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.settings),
              ),
            ],
      showAppBar: !isWide,
      showBottomNavAndFab: !isWide,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: HomeSliverContent(
            user: user,
            isWide: isWide,
            bottomSafePadding: bottomSafePadding,
            summaryKey: _summaryKey,
            phraseKey: _phraseKey,
            groupsKey: _groupsKey,
            controller: _scrollController,
            showSectionNavBar: false,
            sectionItems: sectionItems,
            activeSection: _activeSection,
            onSectionSelected: handleSectionTap,
          ),
        ),
      ),
    );
  }
}
