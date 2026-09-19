import 'package:flutter/material.dart';

import '../statements_controller.dart';
import 'statements_shared_utils.dart';

class StatementEntryNotesDialog {
  static Future<void> show(
    BuildContext context,
    StatementsController controller,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
    if (entryId.isEmpty) return;

    final textController = TextEditingController(
      text: StatementsSharedUtils.entryText(entry, const ['notes']),
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          var saving = false;
          String? errorText;

          Future<void> save(String value, StateSetter setState) async {
            setState(() {
              saving = true;
              errorText = null;
            });
            try {
              await controller.updateEntryNotes(entryId: entryId, notes: value);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            } catch (e) {
              if (!dialogContext.mounted) return;
              setState(() {
                saving = false;
                errorText = e.toString().replaceFirst('Exception: ', '').trim();
              });
            }
          }

          return StatefulBuilder(
            builder: (context, setState) {
              final hasText = textController.text.trim().isNotEmpty;
              return AlertDialog(
                title: const Text('Nota del movimiento'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: textController,
                        enabled: !saving,
                        autofocus: true,
                        maxLength: 1000,
                        maxLines: 6,
                        minLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Escribe una nota para este movimiento...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (errorText != null && errorText!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving || !hasText ? null : () => save('', setState),
                    child: const Text('Borrar nota'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () => save(textController.text, setState),
                    child: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      textController.dispose();
    }
  }
}
