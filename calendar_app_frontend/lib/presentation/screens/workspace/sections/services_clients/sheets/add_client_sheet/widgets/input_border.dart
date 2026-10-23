import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/app_colors.dart';

OutlineInputBorder buildInputBorder(
  BuildContext context, {
  Color? color,
  double width = 1,
}) {
  final cs = Theme.of(context).colorScheme;
  final isLight = Theme.of(context).brightness == Brightness.light;
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
        color: color ??
            (isLight
                ? AppColors.inputBorder
                : cs.outlineVariant.withValues(alpha: 0.5)),
        width: width),
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

  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    labelText: isRequired ? '$label *' : label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: 3,
    errorMaxLines: 3,
    prefixIcon: prefixIcon == null
        ? null
        : IconTheme(
            data: IconThemeData(size: 17, color: cs.onSurfaceVariant),
            child: prefixIcon),
    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    suffixIcon: showCheck
        ? const Icon(Icons.check_circle_rounded,
            size: 18, color: Color(0xFF079B55))
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    filled: true,
    fillColor: isLight ? AppColors.inputBackground : cs.surface,
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
