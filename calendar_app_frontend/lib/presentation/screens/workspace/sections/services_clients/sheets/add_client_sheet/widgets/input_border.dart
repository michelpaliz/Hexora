import 'package:flutter/material.dart';

OutlineInputBorder buildInputBorder(
  BuildContext context, {
  Color? color,
  double width = 1,
}) {
  final cs = Theme.of(context).colorScheme;
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
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

  return InputDecoration(
    isDense: false,
    contentPadding: const EdgeInsets.all(16),
    labelText: isRequired ? '$label *' : label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: 3,
    errorMaxLines: 3,
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    suffixIcon: showCheck
        ? Icon(Icons.check_circle_rounded, size: 18, color: cs.secondary)
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    filled: true,
    fillColor: cs.surfaceContainerLow,
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
