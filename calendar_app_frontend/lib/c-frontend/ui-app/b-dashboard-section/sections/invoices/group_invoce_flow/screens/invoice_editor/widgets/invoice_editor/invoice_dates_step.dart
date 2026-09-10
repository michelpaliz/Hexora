import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/form_widgets/dates_box.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceDatesStep extends StatelessWidget {
  const InvoiceDatesStep({
    super.key,
    required this.currencyController,
    required this.invoiceDate,
    required this.dueDate,
    required this.notesController,
    required this.onPickInvoiceDate,
    required this.onPickDueDate,
    required this.onCurrencyChanged,
    required this.onNotesChanged,
    this.onBack,
    this.onContinue,
  });

  final TextEditingController currencyController;
  final ValueNotifier<DateTime?> invoiceDate;
  final ValueNotifier<DateTime?> dueDate;
  final TextEditingController notesController;
  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isSpanish = localizations.localeName.toLowerCase().startsWith('es');

    return ValueListenableBuilder<DateTime?>(
      valueListenable: invoiceDate,
      builder: (context, selectedInvoiceDate, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: dueDate,
          builder: (context, selectedDueDate, _) {
            final invalidDates = selectedInvoiceDate != null &&
                selectedDueDate != null &&
                selectedDueDate.isBefore(selectedInvoiceDate);
            final canContinue = selectedInvoiceDate != null && !invalidDates;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_note_rounded,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSpanish
                                ? 'Fechas y condiciones'
                                : 'Dates & terms',
                            style: typography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isSpanish
                                ? 'Define cuándo se emite la factura y, si aplica, cuándo vence.'
                                : 'Choose when the invoice is issued and, if needed, when it is due.',
                            style: typography.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _StepCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720;
                      final currencyField = SizedBox(
                        width: wide ? 160 : double.infinity,
                        child: TextFormField(
                          controller: currencyController,
                          onChanged: onCurrencyChanged,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          maxLength: 3,
                          decoration: InputDecoration(
                            labelText: localizations.currencyLabel,
                            helperText: isSpanish
                                ? 'Código ISO, p. ej. EUR'
                                : 'ISO code, e.g. EUR',
                            counterText: '',
                            prefixIcon:
                                const Icon(Icons.currency_exchange_rounded),
                          ),
                        ),
                      );
                      final dates = DatesBox(
                        invoiceDate: selectedInvoiceDate,
                        dueDate: selectedDueDate,
                        onPickInvoiceDate: onPickInvoiceDate,
                        onPickDueDate: onPickDueDate,
                      );

                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            currencyField,
                            const SizedBox(height: 16),
                            dates,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          currencyField,
                          const SizedBox(width: 18),
                          Expanded(child: dates),
                        ],
                      );
                    },
                  ),
                ),
                if (!canContinue) ...[
                  const SizedBox(height: 10),
                  _DatesValidationBanner(
                    message: invalidDates
                        ? (isSpanish
                            ? 'La fecha de vencimiento no puede ser anterior a la fecha de factura.'
                            : 'The due date cannot be earlier than the invoice date.')
                        : (isSpanish
                            ? 'Selecciona la fecha de factura para continuar.'
                            : 'Select an invoice date to continue.'),
                    isError: invalidDates,
                  ),
                ],
                const SizedBox(height: 14),
                _StepCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isSpanish ? 'Notas para el cliente' : 'Customer notes',
                        style: typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSpanish
                            ? 'Opcional. Se mostrarán en la factura.'
                            : 'Optional. These will appear on the invoice.',
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        minLines: 4,
                        maxLines: 7,
                        onChanged: onNotesChanged,
                        decoration: InputDecoration(
                          hintText: isSpanish
                              ? 'Añade condiciones de pago, referencias o un mensaje...'
                              : 'Add payment terms, references, or a message...',
                          prefixIcon: const Align(
                            alignment: Alignment.topCenter,
                            widthFactor: 1,
                            heightFactor: 1,
                            child: Padding(
                              padding: EdgeInsets.only(top: 14),
                              child: Icon(Icons.notes_rounded),
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 48, minHeight: 48),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onBack != null || onContinue != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (onBack != null)
                        OutlinedButton.icon(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(isSpanish ? 'Cliente' : 'Customer'),
                        ),
                      const Spacer(),
                      if (onContinue != null)
                        FilledButton.icon(
                          onPressed: canContinue ? onContinue : null,
                          icon:
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(
                            isSpanish
                                ? 'Continuar a líneas'
                                : 'Continue to line items',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DatesValidationBanner extends StatelessWidget {
  const _DatesValidationBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
