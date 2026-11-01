import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ActiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ActiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          value ? Icons.check_circle_outline : Icons.pause_circle_outline,
          size: 18,
          color: value ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.active,
                style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                value ? l.clientWillBeActive : l.clientWillBeInactive,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
