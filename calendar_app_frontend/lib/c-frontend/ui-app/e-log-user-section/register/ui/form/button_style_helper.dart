import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:flutter/material.dart';

class ButtonStyleHelper {
  static ButtonStyle resolved(BuildContext context, {bool enabled = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!enabled || states.contains(WidgetState.disabled)) {
          return isDark
              ? Colors.grey.shade700 // soft grey in dark
              : Colors.grey.shade300; // soft grey in light
        }
        return isDark ? AppDarkColors.primary : AppColors.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (!enabled || states.contains(WidgetState.disabled)) {
          return isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
        }
        return AppColors.white; // white text on blue
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (!enabled || states.contains(WidgetState.disabled)) return 0;
        return 4;
      }),
      shadowColor: WidgetStateProperty.resolveWith((states) {
        if (!enabled || states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        return Colors.black.withOpacity(0.25);
      }),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
