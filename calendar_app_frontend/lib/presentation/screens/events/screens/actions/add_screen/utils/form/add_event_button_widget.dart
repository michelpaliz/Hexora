import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';

class AddEventButtonWidget extends StatelessWidget {
  final VoidCallback onAddEvent;

  const AddEventButtonWidget({super.key,
    required this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HexoraButton(
        onPressed: onAddEvent,
        label: AppLocalizations.of(context)!.addEvent,
      ),
    );
  }
}
