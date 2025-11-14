import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:flutter/material.dart';

class ButtonStyleHelper {
  static ButtonStyle resolved(BuildContext context, {bool enabled = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (!enabled || states.contains(MaterialState.disabled)) {
          return isDark
              ? Colors.grey.shade700 // soft grey in dark
              : Colors.grey.shade300; // soft grey in light
        }
        return isDark ? AppDarkColors.primary : AppColors.primary;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (!enabled || states.contains(MaterialState.disabled)) {
          return isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
        }
        return AppColors.white; // white text on blue
      }),
      elevation: MaterialStateProperty.resolveWith((states) {
        if (!enabled || states.contains(MaterialState.disabled)) return 0;
        return 4;
      }),
      shadowColor: MaterialStateProperty.resolveWith((states) {
        if (!enabled || states.contains(MaterialState.disabled)) {
          return Colors.transparent;
        }
        return Colors.black.withOpacity(0.25);
      }),
      textStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
