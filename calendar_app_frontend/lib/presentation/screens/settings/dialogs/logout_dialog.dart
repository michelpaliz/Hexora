import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Shared confirmation for standalone and dashboard Settings.
Future<bool?> showLogoutDialog(BuildContext context) => showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final typography = AppTypography.of(context);
        final l = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(l.logoutConfirmTitle,
              style: typography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              )),
          content: Text(l.logoutConfirmMessage,
              style: typography.bodySmall.copyWith(color: cs.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: cs.primary),
              child: Text(l.cancel),
            ),
            FilledButton(
              key: const ValueKey('confirm-logout'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.logout),
            ),
          ],
        );
      },
    );
