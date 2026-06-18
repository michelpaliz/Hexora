import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

OutlineInputBorder buildInputBorder(
  BuildContext context, {
  Color? color,
  double width = 1,
}) {
  final cs = Theme.of(context).colorScheme;
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
        color: color ?? cs.outlineVariant.withValues(alpha: 0.5), width: width),
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
  final isLight = Theme.of(context).brightness == Brightness.light;
  final typo = AppTypography.of(context);

  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    labelText: isRequired ? '$label *' : label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: typo.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      fontSize: 11,
    ),
    floatingLabelStyle: typo.bodySmall.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
      fontSize: 11,
    ),
    hintText: hintText,
    hintStyle: typo.bodySmall.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
      fontWeight: FontWeight.w500,
      fontSize: 12,
    ),
    helperText: helperText,
    helperStyle: typo.bodySmall.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
      fontWeight: FontWeight.w500,
      fontSize: 10,
    ),
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    suffixIcon: showCheck
        ? Icon(Icons.check_circle_rounded, size: 18, color: cs.secondary)
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    filled: true,
    fillColor: isLight
        ? Colors.white
        : (isFilled ? cs.primary.withValues(alpha: 0.06) : cs.surface),
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
