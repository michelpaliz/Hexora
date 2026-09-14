import 'package:flutter/material.dart';

class TitleInputWidget extends StatelessWidget {
  final TextEditingController titleController;

  const TitleInputWidget({
    Key? key,
    required this.titleController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: titleController,
      decoration: const InputDecoration(
        labelText: 'Event Title',
        border: OutlineInputBorder(),
      ),
    );
  }
}
