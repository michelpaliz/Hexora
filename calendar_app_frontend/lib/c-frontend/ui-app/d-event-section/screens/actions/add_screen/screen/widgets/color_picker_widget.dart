import 'package:flutter/material.dart';

class ColorPickerWidget extends StatelessWidget {
  final Color? selectedEventColor;
  final List<Color> colorList;
  final ValueChanged<Color?> onColorChanged;

  const ColorPickerWidget({
    Key? key,
    required this.selectedEventColor,
    required this.onColorChanged,
    required this.colorList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: colorList.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selectedEventColor == color
                    ? Colors.black
                    : Colors.transparent,
                width: 2.0,
              ),
            ),
            width: 30,
            height: 30,
          ),
        );
      }).toList(),
    );
  }
}
