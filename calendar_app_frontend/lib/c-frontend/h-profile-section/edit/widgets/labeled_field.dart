import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: t.labelLarge,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: ThemeColors.getLighterInputFillColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: t.bodyMedium,
    );
  }
}
