import 'package:flutter/material.dart';

class NoteInputWidget extends StatelessWidget {
  final TextEditingController noteController;

  const NoteInputWidget({
    super.key,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: noteController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Note (optional)',
        border: OutlineInputBorder(),
        hintText: 'Enter additional notes',
      ),
    );
  }
}
