import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onSubmitted;

  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final fill = ThemeColors.inputFillLighter(context);
    final onFill = ThemeColors.contrastOn(fill);

    final radius = BorderRadius.circular(12);
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      cursorColor: cs.primary,
      style: t.bodyLarge.copyWith(color: ThemeColors.textPrimary(context)),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.typeNameOrEmail,
        hintStyle: t.bodyMedium.copyWith(color: onFill.withValues(alpha: 0.75)),
        isDense: true,
        prefixIcon: Icon(Icons.search, color: cs.secondary),
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: b(cs.outlineVariant.withValues(alpha: 0.4)),
        enabledBorder: b(cs.outlineVariant.withValues(alpha: 0.4)),
        focusedBorder: b(cs.primary, 1.6),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
