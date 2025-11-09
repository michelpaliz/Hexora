import 'package:flutter/material.dart';

class ButtonStyles {
  static ButtonStyle saucyButtonStyle({
    required Color defaultBackgroundColor,
    required Color pressedBackgroundColor,
    required Color textColor,
    required Color borderColor,
    double borderRadius = 10.0,
    double padding = 10.0,
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.bold,
    FontStyle fontStyle = FontStyle.italic,
  }) {
    return ButtonStyle(
      textStyle: WidgetStateProperty.all<TextStyle>(
        TextStyle(
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
            return defaultBackgroundColor
                .withOpacity(0.9); // Slight effect on hover
          }
          return defaultBackgroundColor;
        },
      ),
      overlayColor: WidgetStateProperty.all<Color>(
        textColor.withOpacity(0.1), // Light ripple color
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
            return 2.0; // Lower elevation when pressed
          }
          return 6.0; // Normal elevated button
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
