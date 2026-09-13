import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/define_themes/mobile_theme.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/button/button_styles.dart';

/// Button variants you actually use.
enum ButtonVariant { primary, secondary, danger, info }

/// Central place to produce button styles using your saucyButtonStyle.
class ThemedButtons {
  ThemedButtons._();

  static ButtonStyle button(
    BuildContext context, {
    ButtonVariant variant = ButtonVariant.primary,
  }) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    if (MobileTheme.isActive(context)) {
      final danger = variant == ButtonVariant.danger;
      final primary = variant == ButtonVariant.primary;
      return ElevatedButton.styleFrom(
        backgroundColor: danger
            ? cs.error
            : primary
                ? cs.primary
                : cs.primaryContainer,
        foregroundColor: danger
            ? cs.onError
            : primary
                ? cs.onPrimary
                : cs.onPrimaryContainer,
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    late final Color bg;
    late final Color bgPressed;
    late final Color text;
    late final Color border;

    switch (variant) {
      case ButtonVariant.danger:
        final e = cs.error;
        bg = e;
        bgPressed = e.withValues(alpha: 0.8);
        text = cs.onError;
        border = e;
        break;

      case ButtonVariant.secondary:
        final c = cs.secondary;
        bg = c;
        bgPressed = c.withValues(alpha: 0.85);
        text = cs.onSecondary;
        border = c;
        break;

      case ButtonVariant.info:
        final c = cs.secondary;
        bg = c;
        bgPressed = c.withValues(alpha: 0.85);
        text = cs.onSecondary;
        border = c;
        break;

      case ButtonVariant.primary:
        final c = cs.primary;
        bg = c;
        bgPressed = c.withValues(alpha: 0.85);
        text = cs.onPrimary;
        border = c;
    }

    final style = ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: bg,
      pressedBackgroundColor: bgPressed,
      textColor: text,
      borderColor: border,
    );
    return style.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? cs.onSurface.withValues(alpha: 0.38)
              : text),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? cs.onSurface.withValues(alpha: 0.12)
              : style.backgroundColor!.resolve(states)),
      elevation: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? 0
              : style.elevation!.resolve(states)),
    );
  }
}
