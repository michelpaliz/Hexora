// lib/widgets/group_name_field.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_utilities/view-item-styles/text_field/flexible/custom_editable_text_field.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupNameField extends StatelessWidget {
  final String groupName;
  final ValueChanged<String> onNameChange;

  const GroupNameField({
    required this.groupName,
    required this.onNameChange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    // Source-of-truth comes from parent; ephemeral controller is fine here.
    final controller = TextEditingController(text: groupName);

    // Theme-aware colors using the new helpers.
    final bg = ThemeColors.inputFillLighter(context);
    final onBg = ThemeColors.contrastOn(bg); // for label + icon
    final textColor = ThemeColors.textPrimary(context); // for input text

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CustomEditableTextField(
        controller: controller,
        labelText: loc.groupNameLabel.toUpperCase(),
        maxLength: 25,
        prefixIcon: Icons.group,
        backgroundColor: bg,
        iconColor: onBg,

        // Typography: use your themed styles
        labelStyle: t.accentText.copyWith(
          color: onBg,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
        textStyle: t.bodyLarge.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),

        // If your CustomEditableTextField exposes onChanged, wire it:
        // onChanged: onNameChange,
      ),
    );
  }
}
