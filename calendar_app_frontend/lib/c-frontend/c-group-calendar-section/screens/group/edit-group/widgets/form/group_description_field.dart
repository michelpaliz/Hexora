import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_utilities/view-item-styles/text_field/flexible/custom_editable_text_field.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupDescriptionField extends StatelessWidget {
  final TextEditingController descriptionController;

  const GroupDescriptionField({
    required this.descriptionController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    final bg = ThemeColors.inputFillLighter(context);
    final onBg = ThemeColors.contrastOn(bg);
    final textColor = ThemeColors.textPrimary(context);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CustomEditableTextField(
        controller: descriptionController,
        labelText: loc.groupDescriptionLabel.toUpperCase(),
        maxLength: 100,
        isMultiline: true,
        prefixIcon: Icons.description,
        backgroundColor: bg,
        iconColor: onBg,

        // Typography
        labelStyle: t.accentText.copyWith(
          color: onBg,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
        textStyle: t.bodyLarge.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
          height: 1.35, // nicer for multiline
        ),
      ),
    );
  }
}
