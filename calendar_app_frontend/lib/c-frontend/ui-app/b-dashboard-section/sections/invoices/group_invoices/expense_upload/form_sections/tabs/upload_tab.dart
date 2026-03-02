import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

