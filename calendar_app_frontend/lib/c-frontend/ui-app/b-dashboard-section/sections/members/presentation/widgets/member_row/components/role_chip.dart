import 'package:flutter/material.dart';

class RoleChip extends StatelessWidget {
  final String label;
  final Color color;
  const RoleChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final on = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: on,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
