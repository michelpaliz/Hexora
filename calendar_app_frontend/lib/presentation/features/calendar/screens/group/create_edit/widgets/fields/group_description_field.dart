import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'group_text_field.dart';

class GroupDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged; // NEW

  const GroupDescriptionField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.maxLines = 4,
    this.onChanged, // NEW
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return GroupTextField(
      label: t.groupDescriptionLabel,
      hint: t.groupDescriptionHint,
      controller: controller,
      maxLines: maxLines,
      validator: (v) => null,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      enabled: enabled,
      onChanged: onChanged, // NEW
    );
  }
}
