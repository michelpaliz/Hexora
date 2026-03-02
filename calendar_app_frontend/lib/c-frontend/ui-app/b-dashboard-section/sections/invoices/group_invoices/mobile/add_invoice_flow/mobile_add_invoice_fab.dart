import 'package:flutter/material.dart';

class MobileAddInvoiceFab extends StatelessWidget {
  const MobileAddInvoiceFab({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
    );
  }
}
