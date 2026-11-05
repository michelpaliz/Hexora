import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_form_fields.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimePickersSection extends StatelessWidget {
  const TimePickersSection({
    super.key,
    required this.l,
    required this.t,
    required this.start,
    required this.end,
    required this.dateFormat,
    required this.timeFormat,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final AppLocalizations l;
  final AppTypography t;
  final DateTime start;
  final DateTime end;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final isSpanish = l.localeName.startsWith('es');
    Widget field({
      required String label,
      required DateTime value,
      required VoidCallback onTap,
    }) =>
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: InputDecorator(
            decoration: buildInputDecoration(
              context,
              label: label,
              prefixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              '${dateFormat.format(value)} · ${timeFormat.format(value)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
    return ClientFormFields(
      first: field(
        label: isSpanish ? 'Fecha y hora de inicio' : 'Start date and time',
        value: start,
        onTap: onPickStart,
      ),
      second: field(
        label: isSpanish ? 'Fecha y hora de fin' : 'End date and time',
        value: end,
        onTap: onPickEnd,
      ),
    );
  }
}
