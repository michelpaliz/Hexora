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

    final bgColor = theme.colorScheme.primaryContainer.withOpacity(.5);
    final onBgColor = theme.colorScheme.onPrimaryContainer;

    return Row(
      children: [
        IconButton.filledTonal(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(bgColor),
          ),
          tooltip: l.previous,
          icon: Icon(Icons.chevron_left, color: onBgColor),
          onPressed: () => onYearChanged(year - 1),
        ),
        Expanded(
          child: Center(
            child: Text(
              '$year',
              style: t.accentHeading.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(bgColor),
          ),
          tooltip: l.next,
          icon: Icon(Icons.chevron_right, color: onBgColor),
          onPressed: () => onYearChanged(year + 1),
        ),
      ],
    );
  }
}
