import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bg = ThemeColors.cardBg(context);
    final onBg = ThemeColors.textPrimary(context);
    final hint = onBg.withOpacity(0.6);
    final border = cs.outlineVariant.withOpacity(0.35);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.cardShadow(context),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: cs.primary,
              style: t.bodyLarge
                  .copyWith(color: onBg, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchPerson,
                hintStyle: t.bodyMedium.copyWith(color: hint),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: onClear,
            color: onBg.withOpacity(0.8),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            onPressed: onSearch,
            color: cs.secondary, // subtle accent
          ),
        ],
      ),
    );
  }
}
