import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';

class SaveButton extends StatelessWidget {
  final bool saving;
  final bool isEdit;
  final VoidCallback? onPressed;

  const SaveButton({
    super.key,
    required this.saving,
    required this.isEdit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: HexoraButton(
        icon: Icons.save_outlined,
        label: isEdit ? l.saveChanges : l.saveClient,
        onPressed: onPressed,
        loading: saving,
        size: HexoraButtonSize.large,
      ),
    );
  }
}
