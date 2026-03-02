import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class DescriptionInputWidget extends StatelessWidget {
  final TextEditingController descriptionController;
  final int maxLength;

  const DescriptionInputWidget({
    super.key,
    required this.descriptionController,
    this.maxLength = 100,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return TextFormField(
      controller: descriptionController,
      minLines: 2,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      style: typo.bodyMedium.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: l.descriptionLabel,
        labelStyle: typo.bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        hintText: l.descriptionLabel,
        hintStyle: typo.bodyMedium.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        counterStyle: typo.bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      maxLength: maxLength,
    );
  }
}
