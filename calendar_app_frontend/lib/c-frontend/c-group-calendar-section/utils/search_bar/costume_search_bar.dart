import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final fill = ThemeColors.inputFillLighter(context);
    final onFill = ThemeColors.contrastOn(fill);

    final radius = BorderRadius.circular(12.0);
    OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          onChanged: onChanged,
          cursorColor: cs.primary,
          style: t.bodyLarge.copyWith(color: ThemeColors.textPrimary(context)),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.searchPerson,
            labelStyle: t.bodyMedium.copyWith(
              color: onFill.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            floatingLabelStyle: t.bodyMedium.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
            ),
            isDense: true,
            filled: true,
            fillColor: fill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

            // Borders
            border: _b(cs.outlineVariant.withOpacity(0.4)),
            enabledBorder: _b(cs.outlineVariant.withOpacity(0.4)),
            focusedBorder: _b(cs.primary, 1.6),
            disabledBorder: _b(cs.outlineVariant.withOpacity(0.25)),

            // Prefix search icon (tap to search)
            prefixIcon: IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              color: cs.secondary, // subtle accent
              tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            ),

            // Suffix clear button (only when there's text)
            suffixIcon: hasText
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear),
                    color: onFill.withOpacity(0.9),
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                  )
                : null,
          ),
        );
      },
    );
  }
}
