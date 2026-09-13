import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/themed_buttons.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../../../../../../viewmodels/group_vm/view_model/group_view_model.dart';

class SaveGroupButton extends StatelessWidget {
  final GroupEditorViewModel controller;
  const SaveGroupButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bg = cs.primary;
    final onBg = ThemeColors.contrastOn(bg);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: controller.status == GroupEditorStatus.loading
              ? null
              : controller.submitGroupFromUI,
          icon: controller.status == GroupEditorStatus.loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: onBg))
              : Icon(Icons.save_outlined, color: onBg, size: 20),
          label: Text(
            AppLocalizations.of(context)!.save,
            style: t.buttonText.copyWith(color: onBg),
          ),
          style: ThemedButtons.button(context, variant: ButtonVariant.primary),
        ),
      ),
    );
  }
}
