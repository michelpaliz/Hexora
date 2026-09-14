import 'package:hexora/l10n/app_localizations.dart'; // ⬅️ Add this
import 'package:flutter/material.dart';

/// A rounded, icon-topped button for adding a new calendar event.
class AddEventButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onPressed;

  const AddEventButton({
    Key? key,
    required this.isVisible,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!; // ⬅️ Localization context

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 20),
        label: Text(loc.addEvent), // ⬅️ Use localized label
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          alignment: Alignment.center,
          iconColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
