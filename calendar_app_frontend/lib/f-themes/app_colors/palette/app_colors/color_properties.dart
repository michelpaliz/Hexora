import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/button/button_styles.dart';
import 'package:flutter/material.dart';

class ColorProperties {
  // Button Colors
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

  // Danger button (uses error color)
  static ButtonStyle dangerButton() {
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: AppDarkColors.error,
      pressedBackgroundColor: AppDarkColors.error.withOpacity(0.8),
      textColor: AppColors.white,
      borderColor: AppDarkColors.error,
    );
  }

  // Info button (accent blue)
  static ButtonStyle infoButton() {
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: AppColors.secondary,
      pressedBackgroundColor: AppColors.secondaryLight,
      textColor: AppColors.white,
      borderColor: AppColors.secondaryDark,
    );
  }
}
