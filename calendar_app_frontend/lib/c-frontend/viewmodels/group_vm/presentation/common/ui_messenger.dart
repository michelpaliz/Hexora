import 'package:flutter/material.dart';

abstract class UiMessenger {
  void showSnack(String message);
  Future<void> showError(String message);
  void pop(); // for simple back/close
}

// Flutter adapter the widget will provide to the VM
class MaterialUiMessenger implements UiMessenger {
  final BuildContext context;
  MaterialUiMessenger(this.context);

  @override
  void showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Future<void> showError(String message) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void pop() => Navigator.of(context).pop();
}
