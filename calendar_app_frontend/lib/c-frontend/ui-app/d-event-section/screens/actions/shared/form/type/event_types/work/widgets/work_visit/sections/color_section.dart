import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/utils/form/color_picker_widget.dart';

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
    return cardBuilder(
      title: title,
      child: ColorPickerWidget(
        selectedEventColor:
            selectedColorValue == null ? null : Color(selectedColorValue!),
        onColorChanged: onColorChanged,
        colorList: colorValues.map((c) => Color(c)).toList(),
      ),
    );
  }
}
