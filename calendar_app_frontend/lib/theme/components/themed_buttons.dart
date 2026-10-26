import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/theme/themes/mobile_theme.dart';
import 'package:hexora/presentation/shared/widgets/buttons/button_styles.dart';

/// Button variants you actually use.
enum ButtonVariant { primary, secondary, ghost, danger, info }

/// Central place to produce button styles using your saucyButtonStyle.
class ThemedButtons {
  ThemedButtons._();

  static double actionTarget(BuildContext context) =>
      MobileTheme.isActive(context) || MediaQuery.sizeOf(context).width < 760
          ? HexoraDimensions.touchTarget
          : HexoraDimensions.button;

  static ButtonStyle iconAction(BuildContext context, {Color? color}) =>
      IconButton.styleFrom(
        minimumSize: Size.square(actionTarget(context)),
        iconSize: HexoraTableTokens.icon,
        padding: const EdgeInsets.all(HexoraDimensions.space),
        foregroundColor:
            color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        backgroundColor: Colors.transparent,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexoraDimensions.radius)),
      );

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

      case ButtonVariant.ghost:
        bg = Colors.transparent;
        bgPressed = cs.onSurface.withValues(alpha: 0.08);
        text = cs.onSurfaceVariant;
        border = Colors.transparent;
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
