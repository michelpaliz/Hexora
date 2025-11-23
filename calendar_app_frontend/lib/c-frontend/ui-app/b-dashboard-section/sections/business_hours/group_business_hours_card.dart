import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupBusinessHoursCard extends StatelessWidget {
  const GroupBusinessHoursCard({
    super.key,
    required this.group,
    required this.description,
    this.onTap,
  });

  final Group group;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hours = group.businessHours;
    final hasWindow = hours?.isConfigured ?? false;

    final rangeLabel = hasWindow
        ? l.businessHoursRange(
            hours!.start ?? '--:--',
            hours.end ?? '--:--',
            hours.timezone,
          )
        : l.businessHoursUnset;

    final timezoneLabel = hours?.timezone ?? 'Europe/Madrid';

    final titleStyle = t.bodyLarge.copyWith(fontWeight: FontWeight.w700);
    final rangeStyle = t.bodyMedium;
    final descriptionStyle = t.bodySmall;
    final tzStyle =
        t.bodySmall.copyWith(color: cs.onSurfaceVariant.withOpacity(0.8));

    return Card(
      clipBehavior: Clip.antiAlias,
      color: ThemeColors.listTileBg(context),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.sectionBusinessHours, style: titleStyle),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: descriptionStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                rangeLabel,
                style: rangeStyle,
              ),
              const SizedBox(height: 4),
              Text(timezoneLabel, style: tzStyle),
            ],
          ),
        ),
      ),
    );
  }
}
