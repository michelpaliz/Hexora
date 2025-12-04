import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ShowNotificationsHeader extends StatelessWidget {
  const ShowNotificationsHeader({
    super.key,
    required this.onClear,
    required this.clearing,
  });

  final VoidCallback? onClear;
  final bool clearing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    return Text(
      loc.notifications,
      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
