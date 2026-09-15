import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CalendarInlineFooterActions extends StatelessWidget {
  const CalendarInlineFooterActions({
    super.key,
    required this.isLoading,
    required this.canAddEvents,
    required this.onRefresh,
    required this.onAddEvent,
  });

  final bool isLoading;
  final bool canAddEvents;
  final VoidCallback onRefresh;
  final Future<void> Function() onAddEvent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.refresh),
            onPressed: isLoading ? null : onRefresh,
          ),
        ),
        const SizedBox(width: 8),
        if (canAddEvents)
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l.addEvent),
              onPressed: isLoading ? null : () => onAddEvent(),
            ),
          ),
      ],
    );
  }
}
