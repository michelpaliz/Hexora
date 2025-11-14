import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EventColorDropdown extends StatelessWidget {
  final Color selectedColor;
  final List<Color> colorList;
  final Function(Color) onColorSelected;

  const EventColorDropdown({
    Key? key,
    required this.selectedColor,
    required this.colorList,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.chooseEventColor,
          style: TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 121, 122, 124),
          ),
        ),
        DropdownButtonFormField<Color>(
          value: selectedColor,
          onChanged: (color) => onColorSelected(color!),
          items: colorList.map((color) {
            String colorName = ColorManager.getColorName(color);
            return DropdownMenuItem<Color>(
              value: color,
              child: Row(
                children: [
                  Container(width: 20, height: 20, color: color),
                  const SizedBox(width: 10),
                  Text(colorName),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
