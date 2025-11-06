import 'package:flutter/material.dart';
import 'package:hexora/app/bootstrapp/use_case_providers.dart';
import 'package:provider/provider.dart';

import 'core_providers.dart';
import 'feature_providers.dart';

class AppBootstrap extends StatelessWidget {
  final Widget child;
  const AppBootstrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...coreProviders, // auth, user, groups, notifications, theme/locale, etc.
        ...featureProviders, // events, invites, resolvers, etc.
        ...useCaseProviders, // CreateGroupUseCase, InviteMembersUseCase, ...
      ],
      child: child,
    );
  }
}
