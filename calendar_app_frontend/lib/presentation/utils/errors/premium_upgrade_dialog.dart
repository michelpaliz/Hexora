import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

Future<void> showPremiumUpgradeDialog(
  BuildContext context, {
  required String message,
}) async {
  final l = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              try {
                Navigator.of(context).pushNamed('/upgrade-premium');
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.upgradeToPremium)),
                );
              }
            },
            child: Text(l.upgradeToPremium),
          ),
        ],
      );
    },
  );
}
