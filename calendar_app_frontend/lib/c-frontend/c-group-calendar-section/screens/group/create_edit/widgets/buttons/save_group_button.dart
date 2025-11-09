import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/themed_buttons.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../../../../../../b-backend/group_mng_flow/group/view_model/group_view_model.dart';

class SaveGroupButton extends StatelessWidget {
  final GroupEditorViewModel controller;

  const SaveGroupButton({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bg = cs.primary;
    final onBg = ThemeColors.contrastOn(bg);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: controller.submitGroupFromUI,
        icon: Icon(Icons.group_add, color: onBg, size: 20),
        label: Text(
          AppLocalizations.of(context)!.saveGroup,
          style: t.buttonText.copyWith(color: onBg),
        ),
        style: ThemedButtons.button(
          context,
          variant: ButtonVariant.primary,
        ),
      ),
    );
  }
}
