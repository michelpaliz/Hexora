import 'package:flutter/material.dart';
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

    return Wrap(
      children: frequencies.map((frequency) {
        final isSelected = frequency == selectedFrequency;

        return GestureDetector(
          onTap: () => onSelectFrequency(frequency),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? Colors.blue
                  : const Color.fromARGB(255, 212, 234, 248),
            ),
            child: Text(
              _getTranslatedFrequency(context, frequency),
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
