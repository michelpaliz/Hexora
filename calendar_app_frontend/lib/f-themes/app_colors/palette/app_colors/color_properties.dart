import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/button/button_styles.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';

class ColorProperties {
  // Primary / default button
  static const Color BUTTON_DEFAULT_PROPERTY = AppColors.primary;
  static const Color BUTTON_PRESSED_BACKGROUND = AppColors.primaryLight;
  static const Color BUTTON_TEXT_COLOR = AppColors.white;
  static const Color BUTTON_BORDER_COLOR = AppColors.primaryDark;

  static ButtonStyle defaultButton() {
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: BUTTON_DEFAULT_PROPERTY,
      pressedBackgroundColor: BUTTON_PRESSED_BACKGROUND,
      textColor: BUTTON_TEXT_COLOR,
      borderColor: BUTTON_BORDER_COLOR,
    );
  }

  // Context-aware primary button (follows theme palette)
  static ButtonStyle themedPrimaryButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: cs.primary,
      pressedBackgroundColor: cs.primary.withOpacity(0.9),
      textColor: cs.onPrimary,
      borderColor: cs.primary,
    );
  }

  // Danger button
  static ButtonStyle dangerButton() {
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: AppDarkColors.error,
      pressedBackgroundColor: AppDarkColors.error.withOpacity(0.85),
      textColor: AppColors.white,
      borderColor: AppDarkColors.error,
    );
  }

  // Info button
  static ButtonStyle infoButton() {
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: AppColors.secondary,
      pressedBackgroundColor: AppColors.secondaryLight,
      textColor: AppColors.white,
      borderColor: AppColors.secondaryDark,
    );
  }
}
