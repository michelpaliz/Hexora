import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/themed_buttons.dart';
import 'package:hexora/l10n/app_localizations.dart';

class BottomNavigationSection extends StatelessWidget {
  final VoidCallback onGroupUpdate;

  const BottomNavigationSection({
    required this.onGroupUpdate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Solid primary background for the button, text/icon use the best contrast.
    final Color bg = cs.primary;
    final Color onBg = ThemeColors.contrastOn(bg);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Container(
        // Outer margin so it breathes from screen edges.
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Subtle separation from content above.
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onGroupUpdate,
            icon: Icon(Icons.group_add_rounded, color: onBg, size: 20),
            label: Text(
              AppLocalizations.of(context)!.save,
              // Use your type system; just swap color to onBg.
              style: t.buttonText.copyWith(color: onBg),
            ),
            style: ThemedButtons.button(
              context,
              variant: ButtonVariant.primary,
            ).copyWith(
              // Real internal padding for a chunkier tap target.
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              // Ensure full-width, comfortable height.
              minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
              // Force our theme colors.
              backgroundColor: WidgetStateProperty.all(bg),
              foregroundColor: WidgetStateProperty.all(onBg),
              // Slightly rounder corners feel nice in bottom bars.
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              // Flatten splash color mismatch on custom foreground.
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return onBg.withOpacity(0.08);
                }
                return null;
              }),
              elevation: WidgetStateProperty.all(0), // keep it modern/flat
            ),
          ),
        ),
      ),
    );
  }
}
