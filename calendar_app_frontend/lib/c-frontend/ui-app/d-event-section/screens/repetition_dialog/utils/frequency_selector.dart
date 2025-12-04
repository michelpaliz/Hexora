import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RepeatFrequencySelector extends StatelessWidget {
  final String selectedFrequency;
  final Function(String) onSelectFrequency;

  const RepeatFrequencySelector({
    Key? key,
    required this.selectedFrequency,
    required this.onSelectFrequency,
  }) : super(key: key);

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
    final frequencies = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final onText = ThemeColors.textPrimary(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: frequencies.map((frequency) {
        final isSelected = frequency == selectedFrequency;

        return ChoiceChip(
          label: Text(
            _getTranslatedFrequency(context, frequency),
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? cs.onPrimaryContainer : onText,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onSelectFrequency(frequency),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          selectedColor: cs.primaryContainer,
          backgroundColor: cs.surfaceVariant.withOpacity(0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  isSelected ? cs.primary : cs.outlineVariant.withOpacity(0.55),
            ),
          ),
        );
      }).toList(),
    );
  }
}
