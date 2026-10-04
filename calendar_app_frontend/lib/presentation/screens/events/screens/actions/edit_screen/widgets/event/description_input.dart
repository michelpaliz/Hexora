import 'package:hexora/presentation/shared/widgets/text_fields/custom_editable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class DescriptionInput extends StatelessWidget {
  final TextEditingController controller;

  const DescriptionInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomEditableTextField(
      controller: controller,
      labelText: AppLocalizations.of(context)!.description(100),
      maxLength: 100,
      isMultiline: true,
      prefixIcon: Icons.description, // optional if you want a description icon
    );
  }
}
