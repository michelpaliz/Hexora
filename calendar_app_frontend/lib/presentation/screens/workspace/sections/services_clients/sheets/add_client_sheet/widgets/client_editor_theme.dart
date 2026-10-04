import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single font family for the client form, without changing other screens.
ThemeData clientEditorThemeOf(BuildContext context) {
  final base = Theme.of(context);
  final cs = base.colorScheme;
  final text = GoogleFonts.manropeTextTheme(base.textTheme);
  final label = text.bodyLarge!.copyWith(fontWeight: FontWeight.w500);
  final floatingLabel = WidgetStateTextStyle.resolveWith((states) {
    final color = states.contains(WidgetState.error)
        ? cs.error
        : states.contains(WidgetState.focused)
            ? cs.primary
            : cs.onSurfaceVariant;
    // InputDecorator scales floating labels to 75%: 18 becomes 13.5 logical px.
    return label.copyWith(fontSize: 18, color: color);
  });

  return base.copyWith(
    textTheme: text,
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: GoogleFonts.manrope(
        textStyle: base.appBarTheme.titleTextStyle ?? text.titleLarge,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      labelStyle: label.copyWith(color: cs.onSurfaceVariant),
      floatingLabelStyle: floatingLabel,
      hintStyle: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
      helperStyle: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      errorStyle: text.bodySmall?.copyWith(color: cs.error),
    ),
  );
}
