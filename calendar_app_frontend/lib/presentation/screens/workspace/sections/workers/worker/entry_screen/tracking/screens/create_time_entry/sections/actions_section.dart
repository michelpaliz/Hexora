import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ActionsSection extends StatelessWidget {
  const ActionsSection({
    super.key,
    required this.l,
    required this.saving,
    required this.onSave,
  });

  final AppLocalizations l;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? l.savingLabel : l.addTimeEntryCta),
          ),
        ),
      ],
    );
  }
}
