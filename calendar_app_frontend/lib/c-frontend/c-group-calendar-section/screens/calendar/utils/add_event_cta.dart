// lib/.../calendar/widgets/add_event_cta.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AddEventCta extends StatelessWidget {
  final VoidCallback onPressed;
  const AddEventCta({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    // Colors that adapt to the theme (context)
    final enabledBg = cs.primary;
    final enabledFg = cs.onPrimary; // high contrast on primary
    final disabledBg = cs.surfaceVariant;
    final disabledFg = cs.onSurface.withOpacity(.60);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: const MaterialStatePropertyAll(Size.fromHeight(48)),
            padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            elevation: MaterialStateProperty.resolveWith<double>(
              (s) => s.contains(MaterialState.disabled) ? 0 : 2,
            ),
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (s) =>
                  s.contains(MaterialState.disabled) ? disabledBg : enabledBg,
            ),
            foregroundColor: MaterialStateProperty.resolveWith<Color>(
              (s) =>
                  s.contains(MaterialState.disabled) ? disabledFg : enabledFg,
            ),
            overlayColor: MaterialStatePropertyAll(enabledFg.withOpacity(0.10)),
          ),
          // Ensure the icon inherits the same foreground color
          child: IconTheme(
            data: IconThemeData(
              color: onPressed == null ? disabledFg : enabledFg,
              size: 22,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    loc.addEvent, // localized
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyMedium.copyWith(
                      // Ensure text uses the same resolved foreground color
                      color: onPressed == null ? disabledFg : enabledFg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
