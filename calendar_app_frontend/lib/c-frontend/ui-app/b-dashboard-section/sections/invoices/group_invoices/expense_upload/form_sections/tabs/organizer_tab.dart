import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

