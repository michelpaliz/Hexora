import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors.dart';
import 'package:hexora/f-themes/app_utilities/view-item-styles/button/button_styles.dart';

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

    late final Color bg;
    late final Color bgPressed;
    late final Color text;
    late final Color border;

    switch (variant) {
      case ButtonVariant.danger:
        final e = t.colorScheme.error;
        bg = e;
        bgPressed = e.withOpacity(0.8);
        text = Colors.white;
        border = e;
        break;

      case ButtonVariant.secondary:
        final c = t.brightness == Brightness.dark
            ? AppDarkColors.secondary
            : AppColors.secondary;
        bg = c;
        bgPressed = t.brightness == Brightness.dark
            ? c.withOpacity(0.85)
            : AppColors.secondaryLight;
        text = Colors.white;
        border = t.brightness == Brightness.dark ? c : AppColors.secondaryDark;
        break;

      case ButtonVariant.info:
        final c = AppColors.secondary;
        bg = c;
        bgPressed = AppColors.secondaryLight;
        text = Colors.white;
        border = AppColors.secondaryDark;
        break;

      case ButtonVariant.primary:
      final c = t.brightness == Brightness.dark
            ? AppDarkColors.primary
            : AppColors.primary;
        bg = c;
        bgPressed = t.brightness == Brightness.dark
            ? c.withOpacity(0.85)
            : AppColors.primaryLight;
        text = Colors.white; // strong, reliable contrast
        border = t.brightness == Brightness.dark
            ? AppDarkColors.primary
            : AppColors.primaryDark;
    }

    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: bg,
      pressedBackgroundColor: bgPressed,
      textColor: text,
      borderColor: border,
    );
  }
}
