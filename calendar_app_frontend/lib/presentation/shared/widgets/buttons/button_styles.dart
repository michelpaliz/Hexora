import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

class ButtonStyles {
  static ButtonStyle saucyButtonStyle({
    required Color defaultBackgroundColor,
    required Color pressedBackgroundColor,
    required Color textColor,
    required Color borderColor,
    double borderRadius = HexoraDimensions.radius,
    double padding = HexoraTableTokens.gap,
    double fontSize = HexoraTypography.body,
    FontWeight fontWeight = FontWeight.w500,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return ButtonStyle(
      textStyle: WidgetStateProperty.all<TextStyle>(
        TextStyle(
          fontFamily: HexoraTypography.fontFamily,
          fontWeight: fontWeight,
          fontSize: fontSize,
          fontStyle: fontStyle,
        ),
      ),
      foregroundColor: WidgetStateProperty.all<Color>(textColor),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return pressedBackgroundColor;
          } else if (states.contains(WidgetState.hovered)) {
            return defaultBackgroundColor.withValues(
                alpha: 0.9); // Slight effect on hover
          }
          return defaultBackgroundColor;
        },
      ),
      overlayColor: WidgetStateProperty.all<Color>(
        textColor.withValues(alpha: 0.1), // Light ripple color
      ),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
        EdgeInsets.all(padding),
      ),
      shape: WidgetStateProperty.all<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderColor),
        ),
      ),
      elevation: WidgetStateProperty.resolveWith<double>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return 0;
          }
          return 0;
        },
      ),
    );
  }

  static Widget buttonWithIcon({
    required IconData iconData,
    required String label,
    required ButtonStyle style,
    required VoidCallback onPressed,
    double iconSize = 20.0,
  }) {
    return ElevatedButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(iconData, size: iconSize),
      label: Text(label),
    );
  }
}
