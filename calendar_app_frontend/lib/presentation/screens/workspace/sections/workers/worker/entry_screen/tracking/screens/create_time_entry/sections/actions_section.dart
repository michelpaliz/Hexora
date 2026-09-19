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
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      return Flex(
        direction: stacked ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            stacked ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: stacked ? 0 : 1,
            fit: stacked ? FlexFit.loose : FlexFit.tight,
            child: OutlinedButton(
              onPressed: saving ? null : () => Navigator.of(context).pop(false),
              child: Text(l.cancel),
            ),
          ),
          SizedBox(width: stacked ? 0 : 12, height: stacked ? 8 : 0),
          Flexible(
            flex: stacked ? 0 : 1,
            fit: stacked ? FlexFit.loose : FlexFit.tight,
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
    });
  }
}
