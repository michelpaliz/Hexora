import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimePickersSection extends StatelessWidget {
  const TimePickersSection({
    super.key,
    required this.l,
    required this.t,
    required this.start,
    required this.end,
    required this.dateFormat,
    required this.timeFormat,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final AppLocalizations l;
  final AppTypography t;
  final DateTime start;
  final DateTime end;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              l.startTime,
              style: t.bodyMedium.copyWith(
                color: ThemeColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${dateFormat.format(start)} ${timeFormat.format(start)}',
              style: t.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: onPickStart,
          ),
          const Divider(height: 0),
          ListTile(
            title: Text(
              l.endTime,
              style: t.bodyMedium.copyWith(
                color: ThemeColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${dateFormat.format(end)} ${timeFormat.format(end)}',
              style: t.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: onPickEnd,
          ),
        ],
      ),
    );
  }
}
