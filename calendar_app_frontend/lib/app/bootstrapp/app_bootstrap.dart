// lib/app/bootstrapp/app_bootstrap.dart
import 'package:flutter/material.dart';
import 'package:hexora/app/bootstrapp/noo_ui_messenger.dart';
import 'package:provider/provider.dart';

import 'core_providers.dart';
import 'feature_providers.dart';
import 'use_case_providers.dart';

class AppBootstrap extends StatelessWidget {
  final Widget child;
  const AppBootstrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...coreProviders, // auth, tokens, user domain, theme/locale, etc.
        ...featureProviders, // groups, events, invites, etc.
        ...useCaseProviders, // create/invite/upload/search use cases
        ...editorProviders, // 👈 VM + Port for the editor
      ],
      child: child,
    );
  }
}
