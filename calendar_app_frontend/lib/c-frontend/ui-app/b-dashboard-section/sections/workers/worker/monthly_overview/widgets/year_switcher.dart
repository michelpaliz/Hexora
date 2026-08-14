import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class YearSwitcher extends StatelessWidget {
  final int year;
  final ValueChanged<int> onYearChanged;

  const YearSwitcher({
    super.key,
    required this.year,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final bgColor = theme.colorScheme.primary.withValues(alpha: 0.10);
    final borderColor = theme.colorScheme.primary.withValues(alpha: 0.16);
    final onBgColor = theme.colorScheme.primary;
    final buttonStyle = IconButton.styleFrom(
      fixedSize: const Size(42, 42),
      backgroundColor: bgColor,
      foregroundColor: onBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
    );

    return Row(
      children: [
        IconButton.filledTonal(
          style: buttonStyle,
          tooltip: l.previous,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onYearChanged(year - 1),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: Text(
                '$year',
                style: t.accentHeading.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          style: buttonStyle,
          tooltip: l.next,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => onYearChanged(year + 1),
        ),
      ],
    );
  }
}
