import 'package:flutter/material.dart';

OutlineInputBorder buildInputBorder(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
  );
}
