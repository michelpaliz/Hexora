import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class DatesBox extends StatelessWidget {
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;

  const DatesBox({
    super.key,
    required this.invoiceDate,
    required this.dueDate,
    required this.onPickInvoiceDate,
    required this.onPickDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final invalidDueDate = invoiceDate != null &&
        dueDate != null &&
        dueDate!.isBefore(invoiceDate!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 460;
        final invoiceField = DateMini(
          label: localizations.invoiceDateLabel,
          value: invoiceDate,
          onPick: onPickInvoiceDate,
          required: true,
        );
        final dueField = DateMini(
          label: localizations.invoiceDueDateLabel,
          value: dueDate,
          onPick: onPickDueDate,
          optional: true,
          hasError: invalidDueDate,
        );
        if (!wide) {
          return Column(
            children: [
              invoiceField,
              const SizedBox(height: 10),
              dueField,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: invoiceField),
            const SizedBox(width: 12),
            Expanded(child: dueField),
          ],
        );
      },
    );
  }
}

class DateMini extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final bool required;
  final bool optional;
  final bool hasError;

  const DateMini({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
    this.required = false,
    this.optional = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final colors = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final isSpanish = localizations.localeName.toLowerCase().startsWith('es');
    final formattedValue = value == null
        ? (isSpanish ? 'Seleccionar fecha' : 'Select date')
        : DateFormat.yMMMd(localizations.localeName).format(value!);
    final accent = hasError ? colors.error : colors.primary;

    return Semantics(
      button: true,
      label: '$label: $formattedValue',
      child: Material(
        color: hasError
            ? colors.errorContainer.withValues(alpha: 0.18)
            : colors.surfaceContainerLow.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPick,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? colors.error.withValues(alpha: 0.55)
                    : colors.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasError
                        ? Icons.event_busy_outlined
                        : Icons.calendar_month_outlined,
                    size: 20,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: typography.bodySmall.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (required && value == null)
                            Text(
                              ' *',
                              style: TextStyle(
                                color: colors.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          if (optional) ...[
                            const SizedBox(width: 6),
                            Text(
                              isSpanish ? 'Opcional' : 'Optional',
                              style: typography.bodySmall.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedValue,
                        style: typography.bodyMedium.copyWith(
                          color:
                              value == null ? colors.primary : colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
