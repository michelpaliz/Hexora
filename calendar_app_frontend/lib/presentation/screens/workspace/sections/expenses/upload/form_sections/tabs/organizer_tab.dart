
import 'package:flutter/material.dart';

class ExpenseOrganizerTab extends StatelessWidget {
  final Widget filePicker;
  final Widget formFields;

  const ExpenseOrganizerTab({
    super.key,
    required this.filePicker,
    required this.formFields,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: filePicker),
              const SizedBox(width: 12),
              Expanded(child: formFields),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            filePicker,
            const SizedBox(height: 12),
            formFields,
          ],
        );
      },
    );
  }
}

