import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NoteInput extends StatelessWidget {
  final TextEditingController controller;

  const NoteInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.note(50),
      ),
      maxLength: 50,
    );
  }
}
