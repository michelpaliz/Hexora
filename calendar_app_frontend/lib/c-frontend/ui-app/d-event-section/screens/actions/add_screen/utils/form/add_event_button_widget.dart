import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AddEventButtonWidget extends StatelessWidget {
  final VoidCallback onAddEvent;

  const AddEventButtonWidget({
    required this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onAddEvent,
        child: Text(AppLocalizations.of(context)!.addEvent),
      ),
    );
  }
}
