import 'package:hexora/f-themes/shapes/solid/auth_header.dart';
import 'package:hexora/c-frontend/utils/logo/logo_widget.dart';
import 'package:flutter/material.dart';

/// Shared constants
const double kAuthHeaderHeight = 280;

/// Shared card builder
Widget buildAuthCard({
  required BuildContext context,
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(28),
}) {
  return Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Theme.of(context).colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: padding,
      child: child,
    ),
  );
}

/// Auth-only field styling; other application forms keep their own theme.
InputDecoration authInputDecoration(
  BuildContext context, {
  required String labelText,
  required String hintText,
  required IconData icon,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
    filled: true,
    fillColor: cs.surfaceContainerLowest,
    prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: border(cs.outlineVariant),
    enabledBorder: border(cs.outlineVariant),
    focusedBorder: border(cs.primary, 2),
    errorBorder: border(cs.error),
    focusedErrorBorder: border(cs.error, 2),
    errorMaxLines: 3,
  );
}

/// Shared header with background + logo
Widget buildAuthHeader(BuildContext context) {
  final topInset = MediaQuery.of(context).padding.top;

  return Stack(
    children: [
      const BlueAuthHeader(height: kAuthHeaderHeight),
      Positioned(
        top: topInset + kAuthHeaderHeight * 0.10,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.center,
          child: LogoWidget.buildLogoAvatar(size: LogoSize.medium),
        ),
      ),
    ],
  );
}
