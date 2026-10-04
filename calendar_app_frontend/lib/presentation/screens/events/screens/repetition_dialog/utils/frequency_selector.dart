import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RepeatFrequencySelector extends StatelessWidget {
  final String selectedFrequency;
  final Function(String) onSelectFrequency;

  const RepeatFrequencySelector({
    super.key,
    required this.selectedFrequency,
    required this.onSelectFrequency,
  });

  String _getTranslatedFrequency(BuildContext context, String frequency) {
    switch (frequency) {
      case 'Daily':
        return AppLocalizations.of(context)!.daily;
      case 'Weekly':
        return AppLocalizations.of(context)!.weekly;
      case 'Monthly':
        return AppLocalizations.of(context)!.monthly;
      case 'Yearly':
        return AppLocalizations.of(context)!.yearly;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const frequencies = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: frequencies.map((frequency) {
            final isSelected = frequency == selectedFrequency;
            final label = _getTranslatedFrequency(context, frequency);
            return SizedBox(
              width: width,
              height: 52,
              child: Semantics(
                button: true,
                selected: isSelected,
                label: label,
                child: Material(
                  color: isSelected ? cs.primaryContainer : cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelectFrequency(frequency),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check,
                              size: 18, color: cs.onPrimaryContainer),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? cs.onPrimaryContainer
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
