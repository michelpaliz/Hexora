import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';

class ActionsSection extends StatelessWidget {
  const ActionsSection({
    super.key,
    required this.l,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  final AppLocalizations l;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      return Flex(
        direction: stacked ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment:
            stacked ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          HexoraButton(
            label: l.cancel,
            size: HexoraButtonSize.standard,
            variant: HexoraButtonVariant.ghost,
            onPressed: saving ? null : onCancel,
          ),
          SizedBox(width: stacked ? 0 : 12, height: stacked ? 8 : 0),
          HexoraButton(
            icon: Icons.save_outlined,
            label: saving ? l.savingLabel : l.addTimeEntryCta,
            size: HexoraButtonSize.standard,
            loading: saving,
            onPressed: saving ? null : onSave,
          ),
        ],
      );
    });
  }
}
