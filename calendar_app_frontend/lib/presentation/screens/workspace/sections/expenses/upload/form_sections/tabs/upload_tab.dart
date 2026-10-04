
import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseUploadTab extends StatelessWidget {
  final Widget filePicker;

  const ExpenseUploadTab({
    super.key,
    required this.filePicker,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filePicker,
        const SizedBox(height: 12),
        Text(
          l.expenseUploadFileHelp,
          style: t.bodySmall,
        ),
      ],
    );
  }
}

