import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import 'insights_chat_sheet_base.dart';

mixin InsightsBankIncomeConfirmLink on InsightsChatSheetStateBase {
  @override
  Future<bool> confirmBankIncomeCandidateLink({
    required BuildContext sourceContext,
    required Map<String, dynamic> row,
    required bool isEs,
    required Future<void> Function() onConfirm,
  }) async {
    final grouped = isGroupedBankIncomeCandidate(row);
    final lowConfidence = bankIncomeMatchIsLow(row);
    final mediumConfidence = bankIncomeMatchIsMedium(row);
    if (!grouped && !lowConfidence) {
      await onConfirm();
      return true;
    }

    final count = bankIncomeMatchedInvoiceCount(row);
    var submitting = false;
    String? errorMessage;
    final confirmed = await showDialog<bool>(
      context: sourceContext,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setConfirmationState) {
          final cs = Theme.of(context).colorScheme;
          final t = AppTypography.of(context);
          final percent =
              formatBankIncomeMatchNumber(row['matchScorePercent']);
          final depositDate = bankIncomeCandidateValue(
            row,
            const ['date', 'fecha'],
          );
          final depositAmount = bankIncomeCandidateValue(
            row,
            const ['amountFormatted', 'amount', 'importe'],
          );
          final selectedScore = bankIncomeMatchScoreText(row, isEs);
          final mobile = MediaQuery.sizeOf(context).width < 700;

          Future<void> submitLink() async {
            setConfirmationState(() {
              submitting = true;
              errorMessage = null;
            });
            try {
              await onConfirm();
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            } catch (error) {
              if (!context.mounted) rethrow;
              setConfirmationState(() {
                submitting = false;
                errorMessage =
                    error.toString().replaceFirst('Exception: ', '').trim();
              });
            }
          }

          Widget confirmButton() => FilledButton(
                onPressed: submitting ? null : submitLink,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        grouped
                            ? (isEs
                                ? 'Vincular $count facturas'
                                : 'Link $count invoices')
                            : (isEs
                                ? 'Vincular de todas formas'
                                : 'Link anyway'),
                      ),
              );
          return PopScope(
            canPop: !submitting,
            child: AlertDialog(
              title: Text(
                grouped
                    ? (isEs
                        ? 'Vincular ingreso con $count facturas'
                        : 'Link income to $count invoices')
                    : (isEs ? 'Revisar coincidencia' : 'Review match'),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (grouped) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 7,
                            children: [
                              if (depositDate.isNotEmpty)
                                Text(
                                  '${isEs ? 'Ingreso' : 'Deposit'}: $depositDate',
                                  style: t.bodySmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (depositAmount.isNotEmpty)
                                Text(
                                  depositAmount,
                                  style: t.bodySmall.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              Text(
                                selectedScore,
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (lowConfidence || (grouped && mediumConfidence)) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (lowConfidence
                                    ? const Color(0xFF8C514B)
                                    : const Color(0xFFA65A00))
                                .withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            grouped && lowConfidence
                                ? (isEs
                                    ? 'La coincidencia agrupada es baja${percent.isEmpty ? '' : ' ($percent%)'}. Revisa todas las facturas antes de continuar.'
                                    : 'This grouped match has low confidence${percent.isEmpty ? '' : ' ($percent%)'}. Review every invoice before continuing.')
                                : grouped && mediumConfidence
                                    ? (isEs
                                        ? 'La suma coincide exactamente, pero revisa la proximidad de las fechas antes de vincular.'
                                        : 'The sum matches exactly, but review the date proximity before linking.')
                                    : (isEs
                                        ? 'La coincidencia es baja${percent.isEmpty ? '' : ' ($percent%)'}. Revisa el concepto, la fecha y el cliente antes de vincular.'
                                        : 'This is a low-confidence match${percent.isEmpty ? '' : ' ($percent%)'}. Review the description, date, and client before linking.'),
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (grouped) ...[
                        Text(
                          isEs
                              ? 'Este ingreso bancario se vinculará con las siguientes facturas:'
                              : 'This bank income will be linked to the following invoices:',
                          style: t.bodySmall,
                        ),
                        buildGroupedBankIncomeDetails(
                          context,
                          row: row,
                          isEs: isEs,
                        ),
                      ],
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMessage!,
                            style: t.bodySmall.copyWith(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (mobile) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: confirmButton(),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: Text(isEs ? 'Cancelar' : 'Cancel'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: mobile
                  ? null
                  : [
                      TextButton(
                        onPressed: submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(isEs ? 'Cancelar' : 'Cancel'),
                      ),
                      confirmButton(),
                    ],
            ),
          );
        },
      ),
    );
    return confirmed == true;
  }

  @override
  int highestBankIncomeMatchIndex(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return 0;
    final usePercent = rows.any((row) => row['matchScorePercent'] is num);
    var bestIndex = 0;
    num? bestScore;
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final score = usePercent
          ? row['matchScorePercent'] as num?
          : row['matchScore'] as num?;
      if (score != null && (bestScore == null || score > bestScore)) {
        bestScore = score;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  @override
  Widget buildTargetInvoiceSummary(
    BuildContext context, {
    required Map<String, dynamic> invoiceRow,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final invoiceNumber = bankIncomeCandidateValue(
      invoiceRow,
      const [
        'invoiceNumber',
        'invoice_number',
        'number',
        'factura',
      ],
    );
    final client = bankIncomeCandidateValue(
      invoiceRow,
      const [
        'clientName',
        'client',
        'cliente',
        'customerName',
        'counterpartyName',
      ],
    );
    final date = bankIncomeCandidateValue(
      invoiceRow,
      const [
        'issueDate',
        'issue_date',
        'invoiceDate',
        'invoice_date',
        'date',
        'fecha',
      ],
    );
    final amount = bankIncomeCandidateValue(
      invoiceRow,
      const [
        'totalFormatted',
        'amountFormatted',
        'importeFormatted',
        'total',
        'amount',
        'importe',
      ],
    );
    final details = <(IconData, String)>[
      if (invoiceNumber.isNotEmpty)
        (Icons.receipt_long_outlined, invoiceNumber),
      if (client.isNotEmpty) (Icons.person_outline_rounded, client),
      if (date.isNotEmpty) (Icons.calendar_today_outlined, date),
      if (amount.isNotEmpty) (Icons.payments_outlined, amount),
    ];

    return Semantics(
      container: true,
      label: isEs ? 'Factura que se va a vincular' : 'Invoice being linked',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 17,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEs ? 'Factura consultada' : 'Selected invoice',
                    style: t.caption.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        for (final detail in details)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                detail.$1,
                                size: 13,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 230,
                                ),
                                child: Text(
                                  detail.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.caption.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
