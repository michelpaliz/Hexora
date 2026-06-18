import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';

class InvoiceDetailDates extends StatelessWidget {
  final Invoice invoice;
  final String locale;
  final bool isEs;

  const InvoiceDetailDates({
    super.key,
    required this.invoice,
    required this.locale,
    required this.isEs,
  });

  String _fmtDate(DateTime dt) =>
      DateFormat('d MMM y', locale).format(dt.toLocal());

  String _fmtDateTime(DateTime dt) =>
      DateFormat('d MMM y · HH:mm', locale).format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final issueDate = invoice.issuedAtResolved;
    final registeredAt = invoice.registeredAt;
    final sentAt = invoice.sentAt;
    final linkedAt = invoice.linkedEntryDate;

    final rows = <({IconData icon, String label, String value, bool primary})>[];

    if (issueDate != null) {
      rows.add((
        icon: Icons.calendar_today_rounded,
        label: isEs ? 'Fecha de factura' : 'Invoice date',
        value: _fmtDate(issueDate),
        primary: true,
      ));
    }

    if (registeredAt != null) {
      final sameDay = issueDate != null &&
          registeredAt.year == issueDate.year &&
          registeredAt.month == issueDate.month &&
          registeredAt.day == issueDate.day;
      if (!sameDay) {
        rows.add((
          icon: Icons.add_circle_outline_rounded,
          label: isEs ? 'Registrada' : 'Created',
          value: _fmtDate(registeredAt),
          primary: false,
        ));
      }
    }

    if (sentAt != null) {
      rows.add((
        icon: Icons.send_rounded,
        label: isEs ? 'Enviada' : 'Sent',
        value: _fmtDateTime(sentAt),
        primary: false,
      ));
    }

    if (linkedAt != null) {
      rows.add((
        icon: Icons.link_rounded,
        label: isEs ? 'Vinculada' : 'Linked',
        value: _fmtDate(linkedAt),
        primary: false,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    size: 13,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isEs ? 'Fechas' : 'Dates',
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) ...[
                    Divider(
                      height: 16,
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ],
                  _buildDateRow(context, cs, t, rows[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    ColorScheme cs,
    AppTypography t,
    ({IconData icon, String label, String value, bool primary}) row,
  ) {
    final color = row.primary ? cs.primary : cs.onSurfaceVariant;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(row.icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            row.label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          row.value,
          style: t.bodySmall.copyWith(
            color: row.primary ? cs.primary : cs.onSurface,
            fontWeight: row.primary ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
