import 'package:flutter/material.dart';

class NoteInputWidget extends StatelessWidget {
  final TextEditingController noteController;

  const NoteInputWidget({
    Key? key,
    required this.noteController,
  }) : super(key: key);

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
