import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class UntilDatePicker extends StatelessWidget {
  final bool isForever;
  final DateTime? untilDate;
  final Function(bool) onForeverChanged;
  final Function(DateTime) onDateSelected;

  const UntilDatePicker({
    Key? key,
    required this.isForever,
    required this.untilDate,
    required this.onForeverChanged,
    required this.onDateSelected,
  }) : super(key: key);

  Future<void> _pickDate(BuildContext context) async {
    final DateTime initialDate = untilDate ?? DateTime.now();
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime(DateTime.now().year + 10);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final onText = ThemeColors.textPrimary(context);
    final secondary = ThemeColors.textSecondary(context);
    final l = AppLocalizations.of(context)!;

    final helperText = isForever
        ? l.utilDateNotSelected
        : untilDate == null
            ? l.utilDateNotSelected
            : l.untilDateSelected(
                DateFormat('yyyy-MM-dd').format(untilDate!),
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch.adaptive(
              value: !isForever,
              activeColor: cs.primary,
              onChanged: (bool newValue) {
                onForeverChanged(!newValue);
              },
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.untilDate,
                  style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onText,
                  ),
                ),
                Text(
                  l.selectDay,
                  style: t.bodySmall.copyWith(color: secondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!isForever)
          OutlinedButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.event_outlined),
            label: Text(
              untilDate == null
                  ? l.selectDay
                  : DateFormat.yMMMd(l.localeName).format(untilDate!),
              style: t.bodyMedium.copyWith(color: onText),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: onText,
              side: BorderSide(color: cs.outlineVariant),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          helperText,
          style: t.bodySmall.copyWith(color: secondary),
        ),
      ],
    );
  }
}
