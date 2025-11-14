import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

Future<String?> showChangeUsernameDialog(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l.changeUsername),
      content: TextField(controller: controller, decoration: InputDecoration(labelText: l.userName)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l.save)),
      ],
    ),
  );
}
