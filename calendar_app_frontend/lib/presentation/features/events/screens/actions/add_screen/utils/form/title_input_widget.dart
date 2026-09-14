import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TitleInputWidget extends StatelessWidget {
  final TextEditingController titleController;

  const TitleInputWidget({
    required this.titleController,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: titleController,
      decoration:
          InputDecoration(labelText: AppLocalizations.of(context)!.title(15)),
      maxLength: 15,
    );
  }
}
