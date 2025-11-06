import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'group_text_field.dart';

class GroupNameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged; // NEW

  const GroupNameField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onChanged, // NEW
  });

  String? _validate(BuildContext context, String? value) {
    final t = AppLocalizations.of(context)!;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return t.groupNameRequired;
    if (v.length < 3) return t.groupNameTooShort;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return GroupTextField(
      label: t.groupNameLabel,
      hint: t.groupNameHint,
      controller: controller,
      validator: (v) => _validate(context, v),
      textInputAction: TextInputAction.next,
      enabled: enabled,
      onChanged: onChanged, // NEW (GroupTextField must support this)
    );
  }
}
