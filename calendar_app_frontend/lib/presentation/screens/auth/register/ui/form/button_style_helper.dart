import 'package:flutter/material.dart';

class ButtonStyleHelper {
  static ButtonStyle resolved(BuildContext context, {bool enabled = true}) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor:
          enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.10),
      foregroundColor:
          enabled ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.45),
      disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.10),
      disabledForegroundColor: cs.onSurface.withValues(alpha: 0.45),
      elevation: 0,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
