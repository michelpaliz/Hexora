import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(AppLocalizations.of(context)!.save),
      ),
    );
  }
}
