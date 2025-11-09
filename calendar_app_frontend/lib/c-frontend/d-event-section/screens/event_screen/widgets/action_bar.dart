// lib/c-frontend/d-event-section/screens/event_detail/widgets/action_bar.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const ActionBar(
      {super.key, required this.onPrimary, required this.onSecondary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onPrimary,
            icon: const Icon(Icons.edit_outlined),
            label: Text(loc.editAction, style: typo.buttonText),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSecondary,
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(
              loc.duplicateAction,
              style: typo.bodyMedium.copyWith(
                  color: scheme.onSurface, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
