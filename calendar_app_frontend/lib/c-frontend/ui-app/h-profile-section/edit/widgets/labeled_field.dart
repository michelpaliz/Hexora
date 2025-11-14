import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final fill = ThemeColors.inputFillLighter(context);
    final onFill = ThemeColors.contrastOn(fill);
    final textColor = ThemeColors.textPrimary(context);

    final borderRadius = BorderRadius.circular(12);
    final baseBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide:
          BorderSide(color: cs.outlineVariant.withOpacity(0.4), width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: cs.primary, width: 1.6),
    );
    final disabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide:
          BorderSide(color: cs.outlineVariant.withOpacity(0.25), width: 1),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      cursorColor: cs.primary,
      style: t.bodyLarge.copyWith(
        color: enabled ? textColor : textColor.withOpacity(0.6),
        height: maxLines != null && maxLines! > 1 ? 1.35 : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: t.bodyMedium.copyWith(
          color: onFill.withOpacity(0.85),
          letterSpacing: 0.2,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: t.bodyMedium.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.25,
        ),
        filled: true,
        fillColor: fill,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

        // Borders
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: focusedBorder,
        disabledBorder: disabledBorder,

        // Helpers
        counterText: maxLength != null ? null : '', // hide counter unless used
      ),
    );
  }
}
