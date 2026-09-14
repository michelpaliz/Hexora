import 'package:flutter/material.dart';

class DescriptionInputWidget extends StatelessWidget {
  final TextEditingController descriptionController;

  const DescriptionInputWidget({
    Key? key,
    required this.descriptionController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        hintText: 'Enter event description',
      ),
    );
  }
}
