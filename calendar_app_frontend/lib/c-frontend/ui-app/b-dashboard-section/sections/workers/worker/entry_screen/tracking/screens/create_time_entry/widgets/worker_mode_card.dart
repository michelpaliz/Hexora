import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerModeCard extends StatelessWidget {
  const WorkerModeCard({
    super.key,
    required this.l,
    required this.t,
    required this.value,
    required this.onChanged,
  });

  final AppLocalizations l;
  final AppTypography t;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(
          l.linkExistingUserLabel,
          style: t.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: ThemeColors.textPrimary(context),
          ),
        ),
        subtitle: Text(
          l.linkExistingUserHint,
          style: t.bodySmall.copyWith(
            color: ThemeColors.textSecondary(context),
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
