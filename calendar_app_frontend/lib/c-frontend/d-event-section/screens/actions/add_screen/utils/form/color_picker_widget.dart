import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/d-event-section/utils/color_manager.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ColorPickerWidget extends StatelessWidget {
  final Color? selectedEventColor;
  final ValueChanged<Color?> onColorChanged;
  final List<Color> colorList;

  const ColorPickerWidget({
    super.key,
    required this.selectedEventColor,
    required this.onColorChanged,
    required this.colorList,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 6),
        //   child: Text(
        //     l.chooseEventColor,
        //     style: typo.bodySmall.copyWith(
        //       color: cs.onSurfaceVariant,
        //       fontWeight: FontWeight.w700,
        //       letterSpacing: .2,
        //     ),
        //   ),
        // ),

        // Dropdown
        DropdownButtonFormField<Color>(
          value: selectedEventColor,
          onChanged: onColorChanged,
          decoration: InputDecoration(
            labelText: l.chooseEventColor,
            labelStyle: typo.bodySmall,
            helperText: l.color, // optional helper; swap/remove if not desired
            helperStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            // filled: true,
            // fillColor: cs.surfaceVariant.withOpacity(.25),
          ),
          iconEnabledColor: cs.onSurfaceVariant,
          items: colorList.map((color) {
            final colorName = ColorManager.getColorName(color);
            return DropdownMenuItem<Color>(
              value: color,
              child: Row(
                children: [
                  // color swatch
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    colorName,
                    style: typo.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
