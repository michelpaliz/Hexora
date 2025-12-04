import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NotesSection extends StatelessWidget {
  const NotesSection({
    super.key,
    required this.controller,
    required this.l,
    required this.t,
  });

  final TextEditingController controller;
  final AppLocalizations l;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.notesLabel,
          style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: t.bodyMedium.copyWith(
            color: ThemeColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: l.notesOptionalHint,
            hintStyle: t.bodySmall.copyWith(
              color: ThemeColors.textSecondary(context),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
