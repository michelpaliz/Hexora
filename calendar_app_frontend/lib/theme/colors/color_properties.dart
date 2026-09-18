import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/button_styles.dart';
import 'package:hexora/theme/colors/app_colors.dart';

class ColorProperties {
  // Primary / default button
  static const Color buttonDefaultProperty = AppColors.primary;
  static const Color buttonPressedBackground = AppColors.primaryLight;
  static const Color buttonTextColor = AppColors.white;
  static const Color buttonBorderColor = AppColors.primaryDark;

  static ButtonStyle defaultButton() {
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: buttonDefaultProperty,
      pressedBackgroundColor: buttonPressedBackground,
      textColor: buttonTextColor,
      borderColor: buttonBorderColor,
    );
  }

  // Context-aware primary button (follows theme palette)
  static ButtonStyle themedPrimaryButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: cs.primary,
      pressedBackgroundColor: cs.primary.withValues(alpha: 0.9),
      textColor: cs.onPrimary,
      borderColor: cs.primary,
    );
  }

  // Danger button
  static ButtonStyle dangerButton() {
    return ButtonStyles.saucyButtonStyle(
      defaultBackgroundColor: AppDarkColors.error,
      pressedBackgroundColor: AppDarkColors.error.withValues(alpha: 0.85),
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
