import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class YearSwitcher extends StatelessWidget {
  final int year;
  final ValueChanged<int> onYearChanged;

  /// Optional back action rendered as a leading control, so the header can
  /// double as the screen's navigation row instead of a separate toolbar.
  final VoidCallback? onBack;

  const YearSwitcher({
    super.key,
    required this.year,
    required this.onYearChanged,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final bgColor = theme.colorScheme.primary.withValues(alpha: 0.10);
    final onBgColor = theme.colorScheme.primary;
    final buttonStyle = IconButton.styleFrom(
      fixedSize: const Size(42, 42),
      backgroundColor: bgColor,
      foregroundColor: onBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return Row(
      children: [
        if (onBack != null) ...[
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              fixedSize: const Size(42, 42),
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            tooltip: l.back,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
        ],
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
