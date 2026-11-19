import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HexoraButton(
        onPressed: onPressed,
        label: AppLocalizations.of(context)!.save,
      ),
    );
  }
}
