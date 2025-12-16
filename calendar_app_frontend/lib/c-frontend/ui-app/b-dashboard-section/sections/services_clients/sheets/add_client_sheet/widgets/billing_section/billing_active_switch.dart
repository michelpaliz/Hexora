import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    final typo = AppTypography.of(context);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(
        l.active,
        style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value ? l.clientWillBeActive : l.clientWillBeInactive,
        style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
