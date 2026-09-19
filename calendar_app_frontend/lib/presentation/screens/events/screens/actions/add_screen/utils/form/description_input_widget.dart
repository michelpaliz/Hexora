import 'package:flutter/material.dart';
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
    final text = Theme.of(context).textTheme;

    return TextFormField(
      controller: descriptionController,
      minLines: 2,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      style: text.bodyLarge!.copyWith(
        color: cs.onSurface,
      ),
      decoration: InputDecoration(
        labelText: l.descriptionLabel,
        labelStyle: text.bodyMedium!.copyWith(
          color: cs.onSurfaceVariant,
        ),
        hintText: l.descriptionLabel,
        hintStyle: text.bodyLarge!.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        counterStyle: text.bodyMedium!.copyWith(
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
