import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class TimeTrackingHeaderCard extends StatelessWidget {
  final String groupName;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final bool busy;

  const TimeTrackingHeaderCard({
    super.key,
    required this.groupName,
    required this.onEnable,
    required this.onDisable,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      color: ThemeColors.getListTileBackgroundColor(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.trackHoursFor(groupName),
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              l.timeTrackingHeaderHint,
              style: t.bodySmall.copyWith(color: cs.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onEnable,
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(l.enableTrackingCta, style: t.buttonText),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onDisable,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(l.disableTrackingCta, style: t.buttonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
