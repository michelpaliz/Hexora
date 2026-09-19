import 'package:flutter/material.dart';

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
      child: ElevatedButton.icon(
        onPressed: onAddEvent,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
