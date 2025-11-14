// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/pill.dart
import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.textStyle,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Gradient background;
  final TextStyle textStyle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
      ).copyWith(
        gradient: background,
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor ?? Colors.white),
            const SizedBox(width: 6),
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}

extension on ShapeDecoration {
  ShapeDecoration copyWith({
    ShapeBorder? shape,
    Gradient? gradient,
    List<BoxShadow>? shadows,
  }) {
    return ShapeDecoration(
      shape: shape ?? this.shape,
      gradient: gradient ?? this.gradient,
      shadows: shadows ?? this.shadows,
      color: color, // preserve color if any
      image: image,
    );
  }
}
