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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.notifications_none_rounded,
            size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          loc.notifications,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
