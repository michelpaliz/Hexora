import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

OutlineInputBorder buildInputBorder(
  BuildContext context, {
  Color? color,
  double width = 1,
}) {
  final cs = Theme.of(context).colorScheme;
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide:
        BorderSide(color: color ?? cs.outlineVariant.withOpacity(0.5), width: width),
  );
}

InputDecoration buildInputDecoration(
  BuildContext context, {
  required String label,
  String? hintText,
  String? helperText,
  Widget? prefixIcon,
  bool isFilled = false,
  bool showCheck = false,
  bool isRequired = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final typo = AppTypography.of(context);

  return InputDecoration(
    labelText: isRequired ? '$label *' : label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: typo.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    ),
    floatingLabelStyle: typo.bodySmall.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    ),
    hintText: hintText,
    hintStyle: typo.bodySmall.copyWith(
      color: cs.onSurfaceVariant.withOpacity(0.6),
      fontWeight: FontWeight.w500,
    ),
    helperText: helperText,
    helperStyle: typo.bodySmall.copyWith(
      color: cs.onSurfaceVariant.withOpacity(0.85),
      fontWeight: FontWeight.w500,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: showCheck
        ? Icon(Icons.check_circle_rounded, color: cs.secondary)
        : null,
    filled: true,
    fillColor: isFilled ? cs.primary.withOpacity(0.06) : cs.surface,
    enabledBorder: buildInputBorder(context),
    focusedBorder: buildInputBorder(
      context,
      color: cs.primary,
      width: 1.6,
    ),
    errorBorder: buildInputBorder(context, color: cs.error),
    focusedErrorBorder: buildInputBorder(
      context,
      color: cs.error,
      width: 1.6,
    ),
  );
}
