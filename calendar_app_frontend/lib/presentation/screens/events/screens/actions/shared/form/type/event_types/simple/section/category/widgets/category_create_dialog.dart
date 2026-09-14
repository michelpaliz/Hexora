import 'package:flutter/material.dart';

Future<String?> showCategoryCreateDialog({
  required BuildContext context,
  required String title,
  required String hintText,
  required String confirmText,
  required String cancelText,
  TextStyle? titleStyle,
  TextStyle? buttonTextStyle,
}) {
  final controller = TextEditingController();
  return showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: titleStyle),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hintText),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: Text(cancelText, style: buttonTextStyle),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(confirmText, style: buttonTextStyle),
        ),
      ],
    ),
  );
}
