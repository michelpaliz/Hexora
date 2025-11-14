import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

Future<bool> showConfirmationDialog(BuildContext context, String message) {
  final t = AppTypography.of(context);
  final cs = Theme.of(context).colorScheme;

  final dialogBg = ThemeColors.cardBg(context);
  final onDialog = ThemeColors.textPrimary(context);

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Text(
          'Confirm',
          style: t.titleLarge.copyWith(
            color: onDialog,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: t.bodyLarge.copyWith(
            color: onDialog.withOpacity(0.9),
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: cs.secondary,
            ),
            child: Text('Cancel', style: t.buttonText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: ThemeColors.contrastOn(cs.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Confirm', style: t.buttonText),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
