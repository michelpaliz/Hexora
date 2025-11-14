import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label; // tooltip + accessibility
  final double size;

  const BadgeIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final on = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    final child = Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
      ).copyWith(color: color),
      child: Icon(icon, size: size, color: on),
    );

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: false,
        child: child,
      ),
    );
  }
}
