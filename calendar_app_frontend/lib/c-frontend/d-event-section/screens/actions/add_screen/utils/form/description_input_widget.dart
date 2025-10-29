import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
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
      style: typo.bodyMedium, // input text
      decoration: InputDecoration(
        labelText: l.descriptionLabel,
        labelStyle: typo.bodySmall,
        hintText: l.descriptionLabel, // or a dedicated hint if you add one
        hintStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
        counterStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
        // filled: true,
        // fillColor: cs.surfaceVariant.withOpacity(.25),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      maxLength: maxLength,
    );
  }
}
