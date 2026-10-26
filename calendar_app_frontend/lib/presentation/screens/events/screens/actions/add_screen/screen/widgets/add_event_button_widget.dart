import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';

class AddEventButtonWidget extends StatelessWidget {
  final Future<void> Function() onAddEvent;

  const AddEventButtonWidget({
    super.key,
    required this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: HexoraButton(
        onPressed: onAddEvent,
        icon: Icons.add,
        label: 'Add Event',
        size: HexoraButtonSize.large,
      ),
    );
  }
}
