import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/events/utils/color_manager.dart';

import 'section_card_builder.dart';

class ColorSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final int? selectedColorValue;
  final ValueChanged<Color?> onColorChanged;
  final List<int> colorValues;

  const ColorSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.selectedColorValue,
    required this.onColorChanged,
    required this.colorValues,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;
    return cardBuilder(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.chooseEventColor,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in colorValues)
                _ColorSwatch(
                  color: Color(value),
                  name: ColorManager.getColorName(
                    Color(value),
                    localeCode: localeCode,
                  ),
                  selected: value == selectedColorValue,
                  onTap: () => onColorChanged(Color(value)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: name,
      child: Semantics(
        label: name,
        button: true,
        selected: selected,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('event-color-${color.toARGB32()}'),
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: selected ? cs.onSurface : cs.outlineVariant,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
