import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class DeleteGroupDialog extends StatefulWidget {
  const DeleteGroupDialog({super.key, required this.groupName});
  final String groupName;

  @override
  State<DeleteGroupDialog> createState() => _DeleteGroupDialogState();
}

class _DeleteGroupDialogState extends State<DeleteGroupDialog> {
  String _enteredName = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      scrollable: true,
      title: Text(l.groupSettingsDeleteGroup),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l.groupSettingsDeleteNamePrompt(widget.groupName)),
        const SizedBox(height: 16),
        TextField(
          autofocus: true,
          autocorrect: false,
          decoration: InputDecoration(labelText: widget.groupName),
          onChanged: (value) => setState(() => _enteredName = value),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError),
          onPressed: _enteredName == widget.groupName
              ? () => Navigator.pop(context, true)
              : null,
          child: Text(l.groupSettingsDeleteGroup),
        ),
      ],
    );
  }
}
